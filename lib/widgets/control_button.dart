import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final bool isLarge;
  final bool isGlowing;
  final bool isPressed;
  final double size; // New parameter for button size

  const ControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.isLarge = false,
    this.isGlowing = false,
    this.isPressed = false,
    this.size = 70, // Default size if not specified
  });

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _glowAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isGlowing) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ControlButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPressed && !oldWidget.isPressed) {
      _animationController.forward();
    } else if (!widget.isPressed && oldWidget.isPressed) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: widget.isLarge ? widget.size * 1.3 : widget.size,
          height: widget.isLarge ? widget.size * 1.3 : widget.size,
          decoration: BoxDecoration(
            color: widget.color ?? AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(widget.size / 4),
            boxShadow: [
              // Main shadow
              BoxShadow(
                color: (widget.color ?? AppTheme.primaryColor).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              // Glow effect if enabled
              if (widget.isGlowing)
                BoxShadow(
                  color: (widget.color ?? AppTheme.primaryColor).withOpacity(
                    0.3 * _glowAnimation.value,
                  ),
                  blurRadius: 15 * _glowAnimation.value,
                  spreadRadius: 1 * _glowAnimation.value,
                ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (widget.color ?? AppTheme.primaryColor).withOpacity(1),
                (widget.color ?? AppTheme.primaryColor).withOpacity(0.8),
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(widget.size / 4),
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              onTap: widget.onPressed,
              child: Center(
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: widget.isLarge ? widget.size / 2 : widget.size / 2.5,
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
