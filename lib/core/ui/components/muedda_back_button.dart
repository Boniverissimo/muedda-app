import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Botão de retorno seguro para páginas abertas por Navigator ou GoRouter.
/// Quando não existir uma rota anterior, volta para a raiz do aplicativo.
class MueddaBackButton extends StatelessWidget {
  const MueddaBackButton({super.key, this.fallbackLocation = '/'});

  final String fallbackLocation;

  Future<void> _goBack(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    context.go(fallbackLocation);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Voltar',
      onPressed: () => _goBack(context),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}
