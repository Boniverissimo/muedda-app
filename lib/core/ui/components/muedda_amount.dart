import 'package:flutter/material.dart';
import '../formatters/muedda_formatters.dart';

class MueddaAmount extends StatelessWidget {
  const MueddaAmount({
    required this.value,
    super.key,
    this.style,
    this.compact = false,
    this.semanticLabel,
  });

  final num value;
  final TextStyle? style;
  final bool compact;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final text = compact
        ? MueddaFormatters.compactCurrency(value)
        : MueddaFormatters.currency(value);
    return Semantics(
      label: semanticLabel ?? 'Valor $text',
      child: ExcludeSemantics(
        child: Text(text, style: style ?? Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
