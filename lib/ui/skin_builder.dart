import 'package:flutter/material.dart';
import '../game/mirror_run_game.dart';
import '../models/player_skin.dart';
import '../services/skin_service.dart';
import 'player_scene_painter.dart';
import 'tap_scale.dart';
import 'theme.dart';

class SkinBuilder extends StatefulWidget {
  final MirrorRunGame game;
  const SkinBuilder({super.key, required this.game});

  @override
  State<SkinBuilder> createState() => _SkinBuilderState();
}

class _SkinBuilderState extends State<SkinBuilder> with SingleTickerProviderStateMixin {
  static const _accent = MR.accent;

  late final AnimationController _glowController;
  late final TextEditingController _nameController;

  double _leftHue = 20.0;
  double _leftSat = 1.0;
  double _rightHue = 270.0;
  double _rightSat = 1.0;
  HeadDecoration _headDeco = HeadDecoration.none;
  FaceDecoration _faceDeco = FaceDecoration.none;
  int? _editIndex;

  bool get _isEditing => _editIndex != null;
  SkinService get _skinService => widget.game.skinService;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _nameController = TextEditingController();

    _editIndex = widget.game.skinBuilderEditIndex;
    if (_isEditing && _editIndex! >= 0 && _editIndex! < _skinService.customSkins.length) {
      final skin = _skinService.customSkins[_editIndex!];
      _nameController.text = skin.name;
      final leftHsl = HSLColor.fromColor(skin.leftColor);
      _leftHue = leftHsl.hue;
      _leftSat = leftHsl.saturation;
      final rightHsl = HSLColor.fromColor(skin.rightColor);
      _rightHue = rightHsl.hue;
      _rightSat = rightHsl.saturation;
      _headDeco = skin.headDecoration;
      _faceDeco = skin.faceDecoration;
    }
    // Apply preset from screenshot tour or other external source
    final preset = widget.game.skinBuilderPreset;
    if (preset != null) {
      _leftHue = (preset['leftHue'] as num?)?.toDouble() ?? _leftHue;
      _leftSat = (preset['leftSat'] as num?)?.toDouble() ?? _leftSat;
      _rightHue = (preset['rightHue'] as num?)?.toDouble() ?? _rightHue;
      _rightSat = (preset['rightSat'] as num?)?.toDouble() ?? _rightSat;
      _headDeco = preset['head'] as HeadDecoration? ?? _headDeco;
      _faceDeco = preset['face'] as FaceDecoration? ?? _faceDeco;
      if (preset['name'] != null) _nameController.text = preset['name'];
      widget.game.skinBuilderPreset = null;
    }
    widget.game.adService.proStatusNotifier.addListener(_onProStatus);
  }

  void _onProStatus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.game.adService.proStatusNotifier.removeListener(_onProStatus);
    _glowController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Color get _leftColor => HSLColor.fromAHSL(1.0, _leftHue, _leftSat, 0.55).toColor();
  Color get _rightColor => HSLColor.fromAHSL(1.0, _rightHue, _rightSat, 0.55).toColor();

  String _defaultName() {
    final count = _skinService.customSkins.length;
    return 'CUSTOM ${count + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _skinService.customSkinUnlocked;

    return Container(
      decoration: const BoxDecoration(gradient: MR.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBackButton(),
            Expanded(child: unlocked ? _buildEditor() : _buildLockedState()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBackButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TapScale(
            onTap: _goBack,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: _accent.withValues(alpha: 0.5),
                size: 20,
              ),
            ),
          ),
          if (_isEditing)
            TapScale(
              onTap: _confirmDelete,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: MR.alert.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLockedState() {
    const gold = MR.gold;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          color: _accent.withValues(alpha: 0.3),
          size: 64,
        ),
        const SizedBox(height: 24),
        Text(
          'SKIN CREATOR',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'Create custom skins with your own colors and decorations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.35),
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 32),
        TapScale(
          onTap: () {
            widget.game.overlays.add('ProScreen');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                colors: [
                  gold.withValues(alpha: 0.5),
                  gold.withValues(alpha: 0.3),
                ],
              ),
              border: Border.all(color: gold.withValues(alpha: 0.6), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'GO PRO — INCLUDED',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text(
            _isEditing ? 'EDIT SKIN' : 'SKIN CREATOR',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _accent,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 20),

          // Live preview
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
                ),
                child: SizedBox(
                  height: 180,
                  width: 220,
                  child: CustomPaint(
                    painter: PlayerScenePainter(
                      leftColor: _leftColor,
                      rightColor: _rightColor,
                      glowT: _glowController.value,
                      headDecoration: _headDeco,
                      faceDecoration: _faceDeco,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Left color
          _buildLabel('LEFT COLOR'),
          const SizedBox(height: 8),
          _buildHueSlider(_leftHue, (v) => setState(() => _leftHue = v), _leftColor),
          const SizedBox(height: 6),
          _buildSatSlider(_leftSat, _leftHue, (v) => setState(() => _leftSat = v)),
          const SizedBox(height: 20),

          // Right color
          _buildLabel('RIGHT COLOR'),
          const SizedBox(height: 8),
          _buildHueSlider(_rightHue, (v) => setState(() => _rightHue = v), _rightColor),
          const SizedBox(height: 6),
          _buildSatSlider(_rightSat, _rightHue, (v) => setState(() => _rightSat = v)),
          const SizedBox(height: 20),

          // Head decoration
          _buildLabel('HEAD'),
          const SizedBox(height: 10),
          _buildHeadPicker(),
          const SizedBox(height: 16),

          // Face decoration
          _buildLabel('FACE'),
          const SizedBox(height: 10),
          _buildFacePicker(),
          const SizedBox(height: 20),

          // Name
          _buildLabel('NAME'),
          const SizedBox(height: 8),
          _buildNameField(),
          const SizedBox(height: 28),

          // Action button
          _buildActionButton(
            _isEditing ? 'UPDATE' : 'SAVE',
            _accent,
            _onSave,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.3),
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _buildHueSlider(double hue, ValueChanged<double> onChanged, Color currentColor) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: List.generate(
            13,
            (i) => HSLColor.fromAHSL(1.0, i * 30.0, 1.0, 0.55).toColor(),
          ),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 0,
          activeTrackColor: Colors.transparent,
          inactiveTrackColor: Colors.transparent,
          thumbColor: currentColor,
          thumbShape: _CircleThumbShape(radius: 14, color: currentColor),
          overlayShape: SliderComponentShape.noOverlay,
        ),
        child: Slider(
          value: hue,
          min: 0,
          max: 360,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSatSlider(double sat, double hue, ValueChanged<double> onChanged) {
    final fullSat = HSLColor.fromAHSL(1.0, hue, 1.0, 0.55).toColor();
    final noSat = HSLColor.fromAHSL(1.0, hue, 0.0, 0.55).toColor();
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [noSat, fullSat]),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
      ),
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 0,
          activeTrackColor: Colors.transparent,
          inactiveTrackColor: Colors.transparent,
          thumbColor: Colors.white,
          thumbShape: const _CircleThumbShape(radius: 9, color: Colors.white),
          overlayShape: SliderComponentShape.noOverlay,
        ),
        child: Slider(
          value: sat,
          min: 0,
          max: 1,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHeadPicker() {
    const labels = {
      HeadDecoration.none: 'NONE',
      HeadDecoration.iceCrown: 'ICE',
      HeadDecoration.flames: 'FIRE',
      HeadDecoration.crown: 'CROWN',
      HeadDecoration.antenna: 'ANTENNA',
      HeadDecoration.halo: 'HALO',
      HeadDecoration.horns: 'HORNS',
      HeadDecoration.wings: 'WINGS',
      HeadDecoration.mohawk: 'MOHAWK',
      HeadDecoration.star: 'STAR',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HeadDecoration.values.map((deco) {
          final selected = _headDeco == deco;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TapScale(
              minSize: MR.minTouchTarget,
              onTap: () => setState(() => _headDeco = deco),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: selected ? _accent.withValues(alpha: 0.2) : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? _accent.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.08),
                    width: selected ? 1 : 0.5,
                  ),
                ),
                child: Text(
                  labels[deco]!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? _accent
                        : Colors.white.withValues(alpha: 0.35),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFacePicker() {
    const labels = {
      FaceDecoration.none: 'NONE',
      FaceDecoration.goggles: 'GOGGLES',
      FaceDecoration.visor: 'VISOR',
      FaceDecoration.mask: 'MASK',
      FaceDecoration.monocle: 'MONOCLE',
      FaceDecoration.scar: 'SCAR',
      FaceDecoration.shades: 'SHADES',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
      children: FaceDecoration.values.map((deco) {
        final selected = _faceDeco == deco;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TapScale(
            minSize: MR.minTouchTarget,
            onTap: () => setState(() => _faceDeco = deco),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: selected ? _accent.withValues(alpha: 0.2) : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? _accent.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.08),
                  width: selected ? 1 : 0.5,
                ),
              ),
              child: Text(
                labels[deco]!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? _accent
                      : Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        );
      }).toList(),
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      maxLength: 12,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.8),
        fontSize: 14,
        letterSpacing: 2,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: _defaultName(),
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.15),
          letterSpacing: 2,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: _accent.withValues(alpha: 0.4)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return TapScale(
      minSize: MR.minTouchTarget,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.8),
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    final deleteIndex = _editIndex!;
    if (deleteIndex < 0 || deleteIndex >= _skinService.customSkins.length) return;
    final skin = _skinService.customSkins[deleteIndex];
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0e0e18),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: MR.alert.withValues(alpha: 0.08),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DELETE SKIN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    skin.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: skin.leftColor.withValues(alpha: 0.7),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TapScale(
                          minSize: MR.minTouchTarget,
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                            child: Center(
                              child: Text(
                                'CANCEL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.4),
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TapScale(
                          minSize: MR.minTouchTarget,
                          onTap: () {
                            Navigator.pop(ctx);
                            _skinService.deleteCustomSkin(deleteIndex);
                            _goBack();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: MR.alert.withValues(alpha: 0.15),
                            ),
                            child: Center(
                              child: Text(
                                'DELETE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: MR.alert.withValues(alpha: 0.8),
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onSave() {
    final name = _nameController.text.trim().isEmpty
        ? _defaultName()
        : _nameController.text.trim().toUpperCase();

    final skin = CustomSkinData(
      name: name,
      leftColorValue: _leftColor.toARGB32(),
      rightColorValue: _rightColor.toARGB32(),
      headDecoration: _headDeco,
      faceDecoration: _faceDeco,
    );

    if (_isEditing) {
      _skinService.updateCustomSkin(_editIndex!, skin);
      _goBack();
    } else {
      if (_skinService.customSkins.length >= SkinService.maxCustomSkins) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1a1a2e),
            content: Text(
              'Maximum ${SkinService.maxCustomSkins} custom skins reached.',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        );
        return;
      }
      _skinService.saveCustomSkin(skin);
      _goBack();
    }
  }

  void _goBack() {
    widget.game.overlays.remove('SkinBuilder');
    widget.game.overlays.add('SkinSelector');
  }

}

class _CircleThumbShape extends SliderComponentShape {
  final double radius;
  final Color color;

  const _CircleThumbShape({required this.radius, required this.color});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(radius * 2, radius * 2);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, radius, Paint()..color = Colors.white.withValues(alpha: 0.9));
    canvas.drawCircle(center, radius - 2, Paint()..color = color);
  }
}
