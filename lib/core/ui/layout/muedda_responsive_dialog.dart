import 'package:flutter/material.dart';

import '../../../app/theme/app_radii.dart';

Future<T?> showMueddaResponsiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      final width = MediaQuery.sizeOf(context).width;
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: width < 600 ? 16 : 40,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
          child: builder(context),
        ),
      );
    },
  );
}
