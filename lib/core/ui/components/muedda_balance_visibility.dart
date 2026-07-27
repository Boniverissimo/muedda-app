import 'package:flutter/material.dart';

class MueddaBalanceVisibility extends StatelessWidget {
  const MueddaBalanceVisibility({
    required this.visible,
    required this.onChanged,
    super.key,
  });

  final bool visible;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = visible ? 'Ocultar valores' : 'Exibir valores';
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        tooltip: label,
        onPressed: () => onChanged(!visible),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            key: ValueKey(visible),
          ),
        ),
      ),
    );
  }
}
