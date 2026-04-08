import 'package:flutter/material.dart';

class CalcKeyButton extends StatefulWidget {
  const CalcKeyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isOperator = false,
    this.isEquals = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback onTap;
  final bool isOperator;
  final bool isEquals;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<CalcKeyButton> createState() => _CalcKeyButtonState();
}

class _CalcKeyButtonState extends State<CalcKeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isEquals = widget.isEquals;
    final bg = isEquals
        ? const Color(0xFF22A652)
        : widget.isOperator
        ? const Color(0xFFDCE7FF)
        : const Color(0xFFEFF2F6);
    final fg = isEquals ? Colors.white : const Color(0xFF1C1C1E);
    final resolvedBg = widget.backgroundColor ?? bg;
    final resolvedFg = widget.foregroundColor ?? fg;

    final topColor = _shiftLightness(resolvedBg, 0.14);
    final bottomColor = _shiftLightness(resolvedBg, -0.08);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [topColor, bottomColor],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          boxShadow: _pressed
              ? const [
                  BoxShadow(
                    color: Color(0x24000000),
                    blurRadius: 2.5,
                    offset: Offset(0, 1),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Color(0x99FFFFFF),
                    blurRadius: 0,
                    offset: Offset(0, -1),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: resolvedFg,
              fontWeight: FontWeight.w700,
              fontSize: isEquals ? 20 : 18,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  Color _shiftLightness(Color color, double delta) {
    final hsl = HSLColor.fromColor(color);
    final next = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(next).toColor();
  }
}
