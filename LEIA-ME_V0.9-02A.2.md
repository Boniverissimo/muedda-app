# V0.9-02A.2 — Fluxo para salvar

## O que mudou

- O botão do resultado agora se chama **Continuar para salvar**.
- Ao tocar nele, o formulário de nova transação abre com os dados interpretados.
- A tela informa que conta e categoria devem ser revisadas antes de salvar.
- Depois de tocar em **Salvar transação**, o formulário retorna sucesso e fecha o Registro Inteligente.

## Como aplicar

Extraia o conteúdo deste ZIP na raiz do projeto, na mesma pasta do `pubspec.yaml`, e confirme a substituição dos arquivos.

Depois execute:

```powershell
dart format .
flutter analyze
flutter test
flutter run
```

Não é necessário executar `build_runner`.
