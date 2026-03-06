import 'package:flutter/material.dart';
import '../game/mirror_run_game.dart';

class SettingsScreen extends StatefulWidget {
  final MirrorRunGame game;
  const SettingsScreen({super.key, required this.game});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _accent = Color(0xFFB48CFF);
  bool _helpExpanded = false;

  @override
  Widget build(BuildContext context) {
    final settings = widget.game.settingsService;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF00a0a0f), Color(0xF0080812), Color(0xF00f0a14)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _accent,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 40),

              // Sound toggle
              _buildToggleRow(
                'SOUND',
                settings.soundEnabled,
                (v) {
                  settings.setSoundEnabled(v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),

              // Haptic toggle
              _buildToggleRow(
                'VIBRATION',
                settings.hapticEnabled,
                (v) {
                  settings.setHapticEnabled(v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 32),

              // Help section
              _buildDivider(),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _helpExpanded = !_helpExpanded),
                child: Row(
                  children: [
                    Text(
                      'HOW TO PLAY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _helpExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 18,
                    ),
                  ],
                ),
              ),
              if (_helpExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  'Hold and drag left/right. Dodge obstacles on both sides. The mirror reflects your movement.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                    height: 1.6,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              const SizedBox(height: 8),

              // Restore purchases
              if (!widget.game.adService.isAdFree) ...[
                _buildDivider(),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => widget.game.adService.restorePurchases(),
                  child: Text(
                    'RESTORE PURCHASES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Spacer(),

              // Credits
              Center(
                child: Text(
                  'MIRROR RUN\nby tmmr',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.25),
                    letterSpacing: 2,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Licenses
              Center(
                child: GestureDetector(
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Mirror Run',
                      applicationVersion: '1.0.0',
                    );
                  },
                  child: Text(
                    'LICENSES',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Back button
              Center(
                child: GestureDetector(
                  onTap: () {
                    widget.game.overlays.remove('SettingsScreen');
                    widget.game.overlays.add('MenuScreen');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: _accent.withValues(alpha: 0.3), width: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'BACK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accent.withValues(alpha: 0.7),
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 3,
            ),
          ),
          Container(
            width: 40,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: value ? _accent.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              color: value ? _accent.withValues(alpha: 0.2) : Colors.transparent,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? _accent : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}
