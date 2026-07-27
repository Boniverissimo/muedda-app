import 'package:flutter/material.dart';

class MueddaButton extends StatelessWidget {
  const MueddaButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final button = FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon ?? Icons.check_rounded),
      label: Text(loading ? 'Salvando...' : label),
      style: destructive
          ? FilledButton.styleFrom(backgroundColor: scheme.error)
          : null,
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
