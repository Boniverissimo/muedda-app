import 'package:flutter/material.dart';

abstract final class MueddaSnackBar {
  static void success(BuildContext context, String message) => _show(context, message, Icons.check_circle_rounded);
  static void error(BuildContext context, String message) => _show(context, message, Icons.error_rounded);
  static void info(BuildContext context, String message) => _show(context, message, Icons.info_rounded);

  static void _show(BuildContext context, String message, IconData icon) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
