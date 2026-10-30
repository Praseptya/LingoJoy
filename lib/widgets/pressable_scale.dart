import 'package:flutter/material.dart';

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.duration = const Duration(milliseconds: 110),
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool isPressed = false;

  bool get isEnabled => widget.onTap != null;

  void _setPressed(bool value) {
    if (!mounted || !isEnabled) return;

    setState(() {
      isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: isEnabled ? (_) => _setPressed(true) : null,
      onTapCancel: isEnabled ? () => _setPressed(false) : null,
      onTapUp: isEnabled ? (_) => _setPressed(false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: isPressed ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
