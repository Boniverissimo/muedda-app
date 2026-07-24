# Sprint 2 — Contas a pagar e receber

## Implementado

- Nova tela **Contas a pagar e receber** acessível pelo menu **Mais**.
- Resumo de valores pendentes a pagar, a receber e vencidos.
- Filtros por tipo, período e status.
- Períodos: hoje, esta semana, este mês, próximos 30 dias e todos.
- Status: pendente, vencido e concluído.
- Ações: marcar como pago/recebido, voltar para pendente, editar, duplicar e excluir.
- Reutilização do cadastro de transações já existente.
- Nenhuma mudança no schema do Drift.

## Validação recomendada

```powershell
dart format .
flutter analyze
flutter run -d windows
```

Não é necessário executar o `build_runner`.
