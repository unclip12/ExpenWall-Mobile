import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/theme_compat.dart';

/// Premium liquid glassmorphism card with blur effects and gradients
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final bool showShimmer;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.blur = 15,
    this.backgroundColor,
    this.border,
    this.boxShadow,
    this.gradient,
    this.showShimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.white.withOpacity(0.85);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.3)
                    : AppThemeCompat.primaryPurple.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.white.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, -2),
                spreadRadius: 0,
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null ? (backgroundColor ?? defaultBg) : null,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.6),
                    width: 1.5,
                  ),
            ),
            padding: padding,
            child: Stack(
              children: [
                // Subtle shimmer effect
                if (showShimmer)
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppThemeCompat.primaryPurple.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient Glass Card for special highlights
class GradientGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Gradient? gradient;

  const GradientGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? AppThemeCompat.purpleGradient;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: effectiveGradient,
        boxShadow: [
          BoxShadow(
            color: AppThemeCompat.primaryPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // Liquid glass effect - floating bubbles
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated Glass Card with hover effects
class AnimatedGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;

  const AnimatedGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.onTap,
  });

  @override
  State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<AnimatedGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GlassCard(
          padding: widget.padding,
          borderRadius: widget.borderRadius,
          showShimmer: true,
          child: widget.child,
        ),
      ),
    );
  }
}
