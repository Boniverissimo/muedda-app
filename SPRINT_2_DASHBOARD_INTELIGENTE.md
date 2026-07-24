# Sprint 2 — Dashboard Inteligente

## Implementado

- Saldo previsto considerando receitas e despesas pendentes.
- Resumo de valores a receber e a pagar.
- Indicador de vencimentos atrasados.
- Fluxo financeiro dos últimos seis meses.
- Próximos vencimentos dos próximos sete dias.
- Atalhos funcionais para Contas, Cartões, Vencimentos e Categorias.
- Links para relatórios e para a tela de contas a pagar e receber.
- Nenhuma alteração no banco de dados ou nos arquivos gerados pelo Drift.

## Validação

```powershell
dart format .
flutter analyze
flutter run -d windows
```

Não é necessário executar o build_runner.
