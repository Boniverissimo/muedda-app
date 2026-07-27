# Muedda — substituição visual baseada no Figma

Este pacote substitui o tema global e o Dashboard pela estrutura visual do export do Figma Make.

## Arquivos

- `lib/app/theme/app_colors.dart`
- `lib/app/theme/app_theme.dart`
- `lib/app/app.dart`
- `lib/features/dashboard/presentation/pages/dashboard_page.dart`

## Aplicação

Copie a pasta `lib` deste pacote para a raiz do projeto:

`C:\Users\Financeiro\Desktop\meu_app`

Confirme a substituição dos arquivos.

Depois execute:

```powershell
dart format lib/app lib/features/dashboard/presentation/pages/dashboard_page.dart
flutter clean
flutter pub get
flutter analyze
flutter run -d windows
```

## Resultado esperado

O Dashboard passa a seguir a ordem visual do Figma:

1. cabeçalho compacto “Início”;
2. card roxo de Patrimônio Total;
3. cards de Saldo Disponível e Investimentos;
4. gráfico de área do Fluxo de Caixa;
5. Insight do Muedda IA;
6. Últimas Transações;
7. Próximas Contas.

O pacote remove do Dashboard o seletor Hoje/Semana/Mês/Ano e a seção Acesso rápido, pois esses elementos não aparecem no Dashboard do export do Figma.

## Observação

A navegação inferior pertence ao Shell do GoRouter, não ao Dashboard. Este pacote não substitui o Shell porque o arquivo atual do Shell não foi fornecido nesta conversa. O Dashboard, entretanto, deixa de criar um FAB próprio, evitando duplicidade com a navegação existente.
