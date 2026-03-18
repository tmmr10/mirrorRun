#!/usr/bin/env ruby
# Upload App Store Preview videos via App Store Connect API
require 'jwt'
require 'net/http'
require 'json'
require 'uri'
require 'digest'

KEY_ID    = "243ZTV823U"
ISSUER_ID = "daed1276-8ca7-4193-b3ea-05bdb17bd324"
KEY_PATH  = File.expand_path("../ios/fastlane/keys/AuthKey_#{KEY_ID}.p8", __dir__)
BUNDLE_ID = "com.tmmr.mirrorrunners"
BASE      = "https://api.appstoreconnect.apple.com/v1"

def generate_token
  key = OpenSSL::PKey::EC.new(File.read(KEY_PATH))
  now = Time.now.to_i
  JWT.encode(
    { iss: ISSUER_ID, iat: now, exp: now + 1200, aud: "appstoreconnect-v1" },
    key, "ES256", { kid: KEY_ID, typ: "JWT" }
  )
end

TOKEN = generate_token

def api(method, path, body = nil)
  uri = URI("#{BASE}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  req = case method
        when :get    then Net::HTTP::Get.new(uri)
        when :post   then Net::HTTP::Post.new(uri)
        when :patch  then Net::HTTP::Patch.new(uri)
        when :delete then Net::HTTP::Delete.new(uri)
        end
  req["Authorization"] = "Bearer #{TOKEN}"
  req["Content-Type"] = "application/json"
  req.body = body.to_json if body

  res = http.request(req)
  parsed = JSON.parse(res.body) rescue {}

  if res.code.to_i >= 400 && res.code != "409"
    errors = parsed["errors"]&.map { |e| "#{e["code"]}: #{e["detail"]}" }&.join("\n    ") || res.body
    puts "  ERROR (#{res.code}):\n    #{errors}"
  end
  [res.code.to_i, parsed]
end

def upload_to_url(url, file_path, content_type)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 300

  data = File.binread(file_path)
  req = Net::HTTP::Put.new(uri)
  req["Content-Type"] = content_type
  req.body = data

  res = http.request(req)
  res.code.to_i
end

# --- Find app version ---
_, apps = api(:get, "/apps?filter[bundleId]=#{BUNDLE_ID}&fields[apps]=bundleId")
app_id = apps.dig("data", 0, "id")
puts "App ID: #{app_id}"

# Get edit version
_, versions = api(:get, "/apps/#{app_id}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION,READY_FOR_SALE&limit=1")
version_id = versions.dig("data", 0, "id")
puts "Version ID: #{version_id}"

# Get localizations
_, locs = api(:get, "/appStoreVersions/#{version_id}/appStoreVersionLocalizations")
localizations = {}
locs["data"].each do |loc|
  locale = loc.dig("attributes", "locale")
  localizations[locale] = loc["id"]
  puts "Locale: #{locale} -> #{loc["id"]}"
end

# Display types for previews
# iPhone 6.5" = APP_IPHONE_65
DISPLAY_TYPE = "APP_IPHONE_65"

PREVIEWS = {
  "en-US" => [
    { file: "preview_01_gameplay.mp4", type: DISPLAY_TYPE },
    { file: "preview_02_events.mp4",   type: DISPLAY_TYPE },
    { file: "preview_03_biomes.mp4",   type: DISPLAY_TYPE },
  ],
  "de-DE" => [
    { file: "preview_01_gameplay.mp4", type: DISPLAY_TYPE },
    { file: "preview_02_events.mp4",   type: DISPLAY_TYPE },
    { file: "preview_03_biomes.mp4",   type: DISPLAY_TYPE },
  ],
}

SCREENSHOTS_DIR = File.expand_path("../ios/fastlane/screenshots", __dir__)

PREVIEWS.each do |locale, previews|
  loc_id = localizations[locale]
  next unless loc_id

  puts "\n=== #{locale} ==="

  # Get existing preview sets
  _, sets = api(:get, "/appStoreVersionLocalizations/#{loc_id}/appPreviewSets")

  # Find or create preview set for display type
  preview_set_id = nil
  sets["data"]&.each do |s|
    if s.dig("attributes", "previewType") == DISPLAY_TYPE
      preview_set_id = s["id"]
    end
  end

  unless preview_set_id
    puts "  Creating preview set for #{DISPLAY_TYPE}..."
    code, res = api(:post, "/appPreviewSets", {
      data: {
        type: "appPreviewSets",
        attributes: { previewType: DISPLAY_TYPE },
        relationships: {
          appStoreVersionLocalization: {
            data: { type: "appStoreVersionLocalizations", id: loc_id }
          }
        }
      }
    })
    preview_set_id = res.dig("data", "id")
    puts "  Preview set: #{preview_set_id}"
  end

  # Delete existing previews
  _, existing = api(:get, "/appPreviewSets/#{preview_set_id}/appPreviews")
  existing["data"]&.each do |p|
    puts "  Deleting old preview..."
    api(:delete, "/appPreviews/#{p["id"]}")
  end

  # Upload each preview
  previews.each do |preview|
    file_path = File.join(SCREENSHOTS_DIR, locale, preview[:file])
    next unless File.exist?(file_path)

    file_size = File.size(file_path)
    file_name = preview[:file]
    checksum = Digest::MD5.hexdigest(File.binread(file_path))

    puts "  Uploading #{file_name} (#{(file_size / 1024.0 / 1024).round(1)} MB)..."

    # Reserve upload
    code, res = api(:post, "/appPreviews", {
      data: {
        type: "appPreviews",
        attributes: {
          fileName: file_name,
          fileSize: file_size,
          mimeType: "video/mp4"
        },
        relationships: {
          appPreviewSet: {
            data: { type: "appPreviewSets", id: preview_set_id }
          }
        }
      }
    })

    preview_id = res.dig("data", "id")
    unless preview_id
      puts "    Failed to reserve upload"
      next
    end

    # Get upload operations
    operations = res.dig("data", "attributes", "uploadOperations")
    if operations && !operations.empty?
      operations.each_with_index do |op, i|
        url = op["url"]
        offset = op["offset"]
        length = op["length"]

        chunk = File.binread(file_path, length, offset)

        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = 300

        headers = {}
        op["requestHeaders"]&.each { |h| headers[h["name"]] = h["value"] }

        req = Net::HTTP::Put.new(uri)
        headers.each { |k, v| req[k] = v }
        req.body = chunk

        resp = http.request(req)
        puts "    Part #{i + 1}/#{operations.length}: #{resp.code}"
      end

      # Commit
      code, res = api(:patch, "/appPreviews/#{preview_id}", {
        data: {
          type: "appPreviews",
          id: preview_id,
          attributes: {
            uploaded: true,
            sourceFileChecksum: { type: "md5", value: checksum }
          }
        }
      })
      puts "    Committed: #{code == 200 ? 'OK' : 'FAILED'}"
    else
      puts "    No upload operations returned"
    end
  end
end

puts "\nDone!"
