# V0.9-02A.1 — Correção de localização de datas

Este patch corrige o erro:

`LocaleDataException: Locale data has not been initialized`

## Como aplicar

Extraia o conteúdo deste ZIP dentro da pasta principal do projeto `meu_app`, no mesmo nível do arquivo `pubspec.yaml`.

Confirme a substituição do arquivo `lib/main.dart`.

Depois execute:

```powershell
dart format .
flutter analyze
flutter test
flutter run
```

Não é necessário executar o `build_runner`.
