import 'package:flutter/material.dart';

abstract final class MueddaRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double full = 999;

  static const card = BorderRadius.all(Radius.circular(xl));
  static const button = BorderRadius.all(Radius.circular(md));
  static const input = BorderRadius.all(Radius.circular(md));
  static const chip = BorderRadius.all(Radius.circular(full));
}
