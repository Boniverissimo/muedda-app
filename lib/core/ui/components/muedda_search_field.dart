import 'package:flutter/material.dart';

class MueddaSearchField extends StatelessWidget {
  const MueddaSearchField({
    required this.controller,
    required this.onChanged,
    super.key,
    this.hintText = 'Pesquisar',
    this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Limpar pesquisa',
              onPressed: () {
                controller.clear();
                onChanged('');
                onClear?.call();
              },
              icon: const Icon(Icons.close_rounded),
            );
          },
        ),
      ),
    );
  }
}
