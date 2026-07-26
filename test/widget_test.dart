import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meu_app/app/app.dart';

void main() {
  testWidgets('FinanceApp inicia dentro do ProviderScope', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FinanceApp()));

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
  });
}
