# V0.9-02A — Registro inteligente por texto

## O que este patch adiciona

- Nova tela **Registro inteligente**.
- Interpretação local e offline de texto.
- Identificação de valor, tipo, data, descrição e categoria sugerida.
- Pré-preenchimento do formulário existente de nova transação.
- Revisão obrigatória antes de salvar.
- Testes unitários do interpretador.
- O botão do Dashboard passa a abrir o Registro inteligente.
- A opção **Preencher manualmente** continua disponível.

## Como aplicar

Extraia o conteúdo deste ZIP dentro da pasta raiz do projeto `meu_app`, no mesmo nível do `pubspec.yaml`, confirmando a substituição dos arquivos.

## Comandos de validação

```powershell
dart format .
flutter analyze
flutter test
flutter run
```

Não é necessário executar `build_runner`, pois este patch não altera o banco Drift.

## Frases para testar

- `Paguei R$ 89,90 no Assaí ontem`
- `Recebi salário de 3.500,00 hoje`
- `Gasolina 220 reais no posto Shell`
- `Gastei 42,50 com Uber`
- `Paguei internet 119,99 no cartão`
- `Transferi 500 da Caixa para Nubank`

## Limitações desta primeira versão

- Transferências ainda exigem seleção manual das contas de origem e destino.
- Compras no cartão ainda exigem seleção manual do cartão.
- O aprendizado de estabelecimentos será implementado na V0.9-02B.
- Voz e foto serão adicionadas em etapas posteriores, reutilizando este mesmo interpretador.
