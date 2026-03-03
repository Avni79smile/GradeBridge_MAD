import 'package:flutter/material.dart';

class BeautifulCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final bool showGradientBorder;
  final LinearGradient? gradient;

  const BeautifulCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.backgroundColor,
    this.showGradientBorder = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(borderRadius!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10), // Fixed deprecated .withOpacity
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: gradient,
        border: showGradientBorder
            ? Border.all(
                color: Colors.white.withAlpha(77), // 0.3 opacity = 77/255
                width: 1,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}