import 'package:flutter/material.dart';

abstract final class MueddaShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 32, offset: Offset(0, 12)),
  ];
}
