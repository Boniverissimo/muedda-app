# Sprint 2 — Relatórios e exportação

## Implementado

- Exportação do mês selecionado em PDF.
- Exportação do mês selecionado em Excel (.xlsx).
- Exportação do mês selecionado em CSV compatível com Excel em português.
- Resumo de receitas, despesas, saldo e valores pendentes.
- Identificação de conta, categoria, status e vencimento das movimentações.
- Arquivos salvos em `Documentos/Meu App Financeiro/Relatórios`.
- Nenhuma alteração no banco de dados Drift.

## Dependências adicionadas

- `pdf: ^3.13.0`
- `excel: ^4.0.6`

## Comandos necessários

```powershell
flutter pub get
dart format .
flutter analyze
flutter run -d windows
```

Não é necessário executar o `build_runner`.

## Roteiro de teste

1. Abra **Relatórios**.
2. Escolha um mês com movimentações.
3. Exporte em PDF, Excel e CSV.
4. Confirme a mensagem com o caminho do arquivo.
5. Abra a pasta `Documentos/Meu App Financeiro/Relatórios`.
6. Verifique os totais e as movimentações nos três formatos.
