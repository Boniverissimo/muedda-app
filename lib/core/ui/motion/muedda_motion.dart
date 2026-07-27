import 'package:flutter/material.dart';

abstract final class MueddaMotion {
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const curve = Curves.easeOutCubic;

  static Widget fadeSlide({required Widget child, int index = 0}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 260 + (index * 35).clamp(0, 280)),
      curve: curve,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, animatedChild) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: animatedChild,
        ),
      ),
      child: child,
    );
  }
}
