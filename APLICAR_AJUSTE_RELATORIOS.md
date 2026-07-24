# Ajuste dos relatórios — remover Excel

Este patch remove a dependência `excel` e toda a exportação `.xlsx`.
Permanecem as exportações em PDF e CSV.

Copie o conteúdo deste ZIP para a raiz do projeto e confirme a substituição dos arquivos.

Depois execute:

```powershell
flutter pub get
dart format .
flutter analyze
flutter run -d windows
```

Não é necessário executar o `build_runner`.
