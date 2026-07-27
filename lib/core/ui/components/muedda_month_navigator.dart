import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'muedda_icon_button.dart';

class MueddaMonthNavigator extends StatelessWidget {
  const MueddaMonthNavigator({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    super.key,
    this.onTapMonth,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onTapMonth;

  @override
  Widget build(BuildContext context) {
    final label = toBeginningOfSentenceCase(
          DateFormat('MMMM yyyy', 'pt_BR').format(month),
        ) ??
        '';

    return Row(
      children: [
        MueddaIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Mês anterior',
          onPressed: onPrevious,
        ),
        Expanded(
          child: Semantics(
            button: onTapMonth != null,
            label: 'Período selecionado: $label',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTapMonth,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
        ),
        MueddaIconButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Próximo mês',
          onPressed: onNext,
        ),
      ],
    );
  }
}
