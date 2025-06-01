import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_theme.dart';

class ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final bool isLarge;
  final bool isGlowing;
  final bool isPressed;

  const ControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.isLarge = false,
    this.isGlowing = false,
    this.isPressed = false,
  });

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
        return GestureDetector(
          onTapDown: (_) {
            _animationController.forward();
            HapticFeedback.lightImpact();
          },
          onTapUp: (_) {
            if (!widget.isPressed) {
              _animationController.reverse();
            }
            widget.onPressed();
          },
          onTapCancel: () {
            if (!widget.isPressed) {
              _animationController.reverse();
            }
          },
          child: Transform.scale(
            scale: widget.isPressed ? _scaleAnimation.value : 1.0,
            child: Container(
              width: widget.isLarge ? 200 : 100,
              height: widget.isLarge ? 90 : 70,
              decoration: BoxDecoration(
                color: widget.color ?? AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  // Main shadow
                  BoxShadow(
                    color: (widget.color ?? AppTheme.primaryColor).withOpacity(
                      0.4,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                  // Glow effect if enabled
                  if (widget.isGlowing)
                    BoxShadow(
                      color: (widget.color ?? AppTheme.primaryColor)
                          .withOpacity(0.3 * _glowAnimation.value),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 2 * _glowAnimation.value,
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
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.white.withOpacity(0.1),
                  onTap: () {},
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.icon,
                              color: Colors.white,
                              size: widget.isLarge ? 40 : 30,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: widget.isLarge ? 16 : 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
