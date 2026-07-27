import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

BoxDecoration dashboardCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.border),
    boxShadow: const [
      BoxShadow(color: Color(0x0A0F172A), blurRadius: 18, offset: Offset(0, 6)),
    ],
  );
}
