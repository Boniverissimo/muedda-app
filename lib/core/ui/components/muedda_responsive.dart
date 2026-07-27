import 'package:flutter/material.dart';

class MueddaResponsive extends StatelessWidget {
  const MueddaResponsive({
    required this.mobile,
    super.key,
    this.tablet,
    this.desktop,
    this.maxContentWidth = 1180,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final child = constraints.maxWidth >= 1024
            ? (desktop ?? tablet ?? mobile)
            : constraints.maxWidth >= 700
                ? (tablet ?? mobile)
                : mobile;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: child,
          ),
        );
      },
    );
  }
}
