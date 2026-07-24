# Sprint 2 — Orçamentos

## Implementado

- Cadastro de limite mensal por categoria de despesa.
- Edição e exclusão de orçamentos.
- Pausar e reativar orçamento sem apagar a configuração.
- Percentual de alerta configurável em 70%, 80%, 90% ou 100%.
- Cálculo automático dos gastos pagos no mês atual.
- Indicador geral dos orçamentos ativos.
- Barras de progresso por categoria.
- Estados visuais de atenção e limite ultrapassado.
- Atalho em **Mais > Orçamentos**.
- Atalho de Orçamentos no Dashboard.

## Persistência

Os orçamentos são armazenados localmente no arquivo:

`meu_financeiro_orcamentos.json`

na pasta de documentos do aplicativo. Não houve alteração no schema do Drift e não é necessário executar o `build_runner`.

## Validação

Execute:

```powershell
dart format .
flutter analyze
flutter run -d windows
```

Teste sugerido:

1. Acesse **Mais > Orçamentos**.
2. Cadastre um limite para uma categoria de despesa.
3. Registre uma despesa paga nessa categoria no mês atual.
4. Retorne aos orçamentos e confira o valor consumido.
5. Edite, pause, reative e exclua o orçamento.
