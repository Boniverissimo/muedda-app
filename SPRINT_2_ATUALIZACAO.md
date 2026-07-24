# Sprint 2 — Atualização funcional de Recorrências

## Implementado nesta entrega

- A integração do campo **Tornar recorrente**, já presente na base enviada, foi preservada.
- O lançamento informado no formulário continua sendo criado imediatamente e a regra começa na ocorrência seguinte.
- Motor automático executado ao abrir o aplicativo.
- Geração de lançamentos pendentes com `isPaid = false` e vencimento na data da ocorrência.
- Proteção contra duplicidade por marcador interno da regra e da data.
- Avanço de datas para frequências diária, semanal, quinzenal, mensal, bimestral, trimestral, semestral e anual.
- Respeito à data final da recorrência.
- Desativação automática quando a regra ultrapassa a data final.
- Botão de sincronização na tela Recorrências para geração manual imediata.
- Atualização dos providers após a geração dos lançamentos.

## Arquivos principais alterados

- `lib/app/app.dart`
- `lib/core/providers/recurring_transactions_providers.dart`
- `lib/core/services/recurring_generation_service.dart` (novo)
- `lib/features/recurring_transactions/presentation/pages/recurring_transactions_page.dart`

## Banco de dados

Esta entrega utiliza a estrutura já existente da Sprint 2.2 e não altera o schema. Portanto, não é necessário executar o build_runner por causa desta atualização.

## Comandos recomendados

```powershell
dart format .
flutter analyze
flutter run -d windows
```

## Teste rápido

1. Abra Nova transação.
2. Selecione Receita ou Despesa.
3. Marque Tornar recorrente.
4. Escolha a frequência e salve.
5. Acesse Recorrências e confirme que a regra foi criada.
6. Use o botão de sincronização no topo para processar ocorrências vencidas.

## Observação de validação

O ambiente usado para preparar o ZIP não possui o SDK Flutter instalado. Por isso, o código foi revisado estruturalmente, mas os comandos `flutter analyze` e `flutter run` devem ser executados no computador de desenvolvimento.
