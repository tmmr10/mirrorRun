#!/usr/bin/env ruby
# Setup Game Center leaderboards and achievements via App Store Connect API
#
# Usage: ruby ios/fastlane/setup_game_center.rb

require 'jwt'
require 'net/http'
require 'json'
require 'uri'

# --- Config ---
KEY_ID     = "243ZTV823U"
ISSUER_ID  = "daed1276-8ca7-4193-b3ea-05bdb17bd324"
KEY_PATH   = File.expand_path("keys/AuthKey_#{KEY_ID}.p8", __dir__)
BUNDLE_ID  = "com.tmmr.mirrorrunners"
BASE_URL   = "https://api.appstoreconnect.apple.com/v1"

# --- JWT ---
def generate_token
  key = OpenSSL::PKey::EC.new(File.read(KEY_PATH))
  now = Time.now.to_i
  payload = {
    iss: ISSUER_ID,
    iat: now,
    exp: now + 1200,
    aud: "appstoreconnect-v1"
  }
  JWT.encode(payload, key, "ES256", { kid: KEY_ID, typ: "JWT" })
end

TOKEN = generate_token

def api_request(method, path, body = nil)
  uri = URI("#{BASE_URL}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  req = case method
        when :get    then Net::HTTP::Get.new(uri)
        when :post   then Net::HTTP::Post.new(uri)
        when :patch  then Net::HTTP::Patch.new(uri)
        end
  req["Authorization"] = "Bearer #{TOKEN}"
  req["Content-Type"] = "application/json"
  req.body = body.to_json if body

  res = http.request(req)
  parsed = JSON.parse(res.body) rescue {}

  unless res.is_a?(Net::HTTPSuccess) || res.code == "201" || res.code == "409"
    errors = parsed["errors"]&.map { |e| e["detail"] }&.join(", ") || res.body
    puts "  ERROR (#{res.code}): #{errors}"
    return nil
  end
  parsed
end

# --- Find App ID ---
def find_app_id
  res = api_request(:get, "/apps?filter[bundleId]=#{BUNDLE_ID}&fields[apps]=bundleId")
  app = res&.dig("data")&.first
  abort("App #{BUNDLE_ID} not found!") unless app
  app["id"]
end

# --- Game Center ---
def enable_game_center(app_id)
  puts "\n=== Enabling Game Center ==="
  # Check if already enabled
  res = api_request(:get, "/apps/#{app_id}/gameCenterDetail")
  if res && res["data"]
    puts "  Game Center already enabled"
    return res["data"]["id"]
  end

  res = api_request(:post, "/gameCenterDetails", {
    data: {
      type: "gameCenterDetails",
      attributes: {
        challengeEnabled: false
      },
      relationships: {
        app: { data: { type: "apps", id: app_id } }
      }
    }
  })
  gc_id = res&.dig("data", "id")
  puts gc_id ? "  Enabled (#{gc_id})" : "  Failed to enable"
  gc_id
end

# --- Leaderboard ---
def create_leaderboard(gc_detail_id)
  puts "\n=== Creating Leaderboard ==="
  ref_name = "Highscore"
  vendor_id = "mirror_run_highscore"

  res = api_request(:post, "/gameCenterLeaderboards", {
    data: {
      type: "gameCenterLeaderboards",
      attributes: {
        referenceName: ref_name,
        vendorIdentifier: vendor_id,
        submissionType: "BEST_SCORE",
        scoreSortType: "DESC",
        scoreRangeStart: "0",
        scoreRangeEnd: "999999",
        defaultFormatter: "INTEGER"
      },
      relationships: {
        gameCenterDetail: { data: { type: "gameCenterDetails", id: gc_detail_id } }
      }
    }
  })

  lb_id = res&.dig("data", "id")
  if lb_id
    puts "  Created: #{ref_name} (#{vendor_id})"
    create_leaderboard_localization(lb_id, "en-US", "Highscore", " m")
    create_leaderboard_localization(lb_id, "de-DE", "Bestenliste", " m")
  else
    puts "  Leaderboard may already exist"
  end
end

def create_leaderboard_localization(lb_id, locale, name, suffix)
  api_request(:post, "/gameCenterLeaderboardLocalizations", {
    data: {
      type: "gameCenterLeaderboardLocalizations",
      attributes: {
        locale: locale,
        name: name,
        formatterOverride: nil,
        formatterSuffix: suffix,
        formatterSuffixSingular: suffix
      },
      relationships: {
        gameCenterLeaderboard: { data: { type: "gameCenterLeaderboards", id: lb_id } }
      }
    }
  })
  puts "    Localization: #{locale} -> #{name}"
end

# --- Achievements ---
ACHIEVEMENTS = [
  # Distance achievements
  { id: "achievement_distance_75",   ref: "Distance 75m",    en: "First Steps",        de: "Erste Schritte",     en_desc: "Reach 75 meters",            de_desc: "Erreiche 75 Meter",            points: 5  },
  { id: "achievement_distance_100",  ref: "Distance 100m",   en: "Century Runner",     de: "100-Meter-Laufer",   en_desc: "Reach 100 meters",           de_desc: "Erreiche 100 Meter",           points: 5  },
  { id: "achievement_distance_300",  ref: "Distance 300m",   en: "Getting Warm",       de: "Warm gelaufen",      en_desc: "Reach 300 meters",           de_desc: "Erreiche 300 Meter",           points: 10 },
  { id: "achievement_distance_750",  ref: "Distance 750m",   en: "Half K Runner",      de: "Halber Kilometer",   en_desc: "Reach 750 meters",           de_desc: "Erreiche 750 Meter",           points: 15 },
  { id: "achievement_distance_1400", ref: "Distance 1400m",  en: "Deep Space",         de: "Tiefer Weltraum",    en_desc: "Reach 1400 meters",          de_desc: "Erreiche 1400 Meter",          points: 20 },
  { id: "achievement_distance_2500", ref: "Distance 2500m",  en: "Neon Dreamer",       de: "Neon-Traumer",       en_desc: "Reach 2500 meters",          de_desc: "Erreiche 2500 Meter",          points: 25 },
  { id: "achievement_distance_3200", ref: "Distance 3200m",  en: "Legendary Runner",   de: "Legendarer Laufer",  en_desc: "Reach 3200 meters",          de_desc: "Erreiche 3200 Meter",          points: 50 },

  # Biome achievements
  { id: "achievement_biome_crystal", ref: "Biome Crystal",   en: "Crystal Clear",      de: "Kristallklar",       en_desc: "Reach the Crystal biome",    de_desc: "Erreiche das Kristall-Biom",   points: 10 },
  { id: "achievement_biome_volcano", ref: "Biome Volcano",   en: "Playing with Fire",  de: "Mit Feuer spielen",  en_desc: "Reach the Volcano biome",    de_desc: "Erreiche das Vulkan-Biom",     points: 15 },
  { id: "achievement_biome_desert",  ref: "Biome Desert",    en: "Desert Mirage",      de: "Wustenspiegelung",   en_desc: "Reach the Desert biome",     de_desc: "Erreiche das Wusten-Biom",     points: 15 },
  { id: "achievement_biome_ocean",   ref: "Biome Ocean",     en: "Deep Dive",          de: "Tiefer Tauchgang",   en_desc: "Reach the Ocean biome",      de_desc: "Erreiche das Ozean-Biom",      points: 20 },
  { id: "achievement_biome_neon",    ref: "Biome Neon",      en: "Neon Dreams",        de: "Neon-Traume",        en_desc: "Reach the Neon biome",       de_desc: "Erreiche das Neon-Biom",       points: 30 },
  { id: "achievement_biome_void",    ref: "Biome Void",      en: "Into the Void",      de: "Ab ins Nichts",      en_desc: "Reach the Void biome",       de_desc: "Erreiche das Void-Biom",       points: 50 },

  # Games played achievements
  { id: "achievement_games_10",      ref: "Games 10",        en: "Getting Started",    de: "Erste Schritte",     en_desc: "Play 10 games",              de_desc: "Spiele 10 Runden",             points: 5  },
  { id: "achievement_games_50",      ref: "Games 50",        en: "Dedicated",          de: "Hingabe",            en_desc: "Play 50 games",              de_desc: "Spiele 50 Runden",             points: 10 },
  { id: "achievement_games_100",     ref: "Games 100",       en: "Addicted",           de: "Suchtig",            en_desc: "Play 100 games",             de_desc: "Spiele 100 Runden",            points: 15 },
  { id: "achievement_games_500",     ref: "Games 500",       en: "Mirror Master",      de: "Spiegel-Meister",    en_desc: "Play 500 games",             de_desc: "Spiele 500 Runden",            points: 25 },

  # First game
  { id: "achievement_first_game",    ref: "First Game",      en: "First Reflection",   de: "Erste Spiegelung",   en_desc: "Complete your first game",   de_desc: "Beende dein erstes Spiel",     points: 5  },
]

def create_achievements(gc_detail_id)
  puts "\n=== Creating #{ACHIEVEMENTS.length} Achievements ==="

  ACHIEVEMENTS.each do |ach|
    res = api_request(:post, "/gameCenterAchievements", {
      data: {
        type: "gameCenterAchievements",
        attributes: {
          referenceName: ach[:ref],
          vendorIdentifier: ach[:id],
          points: ach[:points],
          showBeforeEarned: true,
          repeatable: false
        },
        relationships: {
          gameCenterDetail: { data: { type: "gameCenterDetails", id: gc_detail_id } }
        }
      }
    })

    ach_id = res&.dig("data", "id")
    if ach_id
      puts "  Created: #{ach[:ref]} (#{ach[:id]}, #{ach[:points]} pts)"
      create_achievement_localization(ach_id, "en-US", ach[:en], ach[:en_desc])
      create_achievement_localization(ach_id, "de-DE", ach[:de], ach[:de_desc])
    else
      puts "  Skipped (may already exist): #{ach[:ref]}"
    end
  end
end

def create_achievement_localization(ach_id, locale, name, desc)
  api_request(:post, "/gameCenterAchievementLocalizations", {
    data: {
      type: "gameCenterAchievementLocalizations",
      attributes: {
        locale: locale,
        name: name,
        beforeEarnedDescription: desc,
        afterEarnedDescription: desc
      },
      relationships: {
        gameCenterAchievement: { data: { type: "gameCenterAchievements", id: ach_id } }
      }
    }
  })
  puts "    Localization: #{locale} -> #{name}"
end

# --- Main ---
puts "Mirror Runners - Game Center Setup"
puts "=" * 40

app_id = find_app_id
puts "App ID: #{app_id}"

gc_detail_id = enable_game_center(app_id)
abort("Failed to enable Game Center") unless gc_detail_id

create_leaderboard(gc_detail_id)
create_achievements(gc_detail_id)

puts "\n=== Done! ==="
puts "Total points: #{ACHIEVEMENTS.sum { |a| a[:points] }}"
