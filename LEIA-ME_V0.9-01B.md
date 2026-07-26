# V0.9-01B — Higiene estrutural

Este patch foi montado sobre o ZIP completo `meu_app (2).zip`.

Alterações:

- providers de contas centralizados em `accounts_providers.dart`;
- `database_providers.dart` mantém apenas o provider do banco;
- imports das páginas ajustados;
- teste padrão do contador substituído por smoke test com `ProviderScope`;
- dois avisos simples de lint corrigidos;
- o arquivo duplicado `transaction_form_page_corrigido.dart` deve ser removido pelo script.

Não altera schema Drift, rotas, interface ou regras financeiras.
