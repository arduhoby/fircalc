import 'package:flutter/material.dart';

class CalcKeyButton extends StatefulWidget {
  const CalcKeyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isOperator = false,
    this.isEquals = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isOperator;
  final bool isEquals;

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

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        transform: Matrix4.translationValues(0, _pressed ? 1.5 : 0, 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          boxShadow: _pressed
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Color(0x66FFFFFF),
                    blurRadius: 0,
                    offset: Offset(0, -1),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isEquals ? 16 : 14),
          child: Text(
            widget.label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: isEquals ? 20 : 18,
            ),
          ),
        ),
      ),
    );
  }
}
