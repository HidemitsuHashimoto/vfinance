# vfinance

App financeiro pessoal offline-first (Flutter). Regras de produto e modelo estão em [`domain.md`](domain.md).

## Pré-requisitos

- [FVM](https://fvm.app/) para fixar a mesma versão do Flutter em toda a equipe.
- Uma versão do Flutter compatível com o SDK Dart declarado em `pubspec.yaml` (`environment: sdk`).

## Instalação

Na raiz do repositório:

1. Se o projeto definir a versão via FVM (pasta `.fvm/` ou `fvm_config.json`), alinhe o Flutter:

   ```bash
   fvm install
   ```

2. Baixe as dependências:

   ```bash
   fvm flutter pub get
   ```

3. Se você alterar o schema Drift em `lib/data/local/app_database.dart`, regenere o código (veja a próxima seção). Em um clone limpo em que `app_database.g.dart` já esteja no Git, este passo pode ser opcional.

## Regenerar código Drift

O Drift gera `lib/data/local/app_database.g.dart` a partir de `app_database.dart`. Depois de mudar tabelas ou anotações, execute:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

Para regenerar automaticamente durante o desenvolvimento:

```bash
fvm dart run build_runner watch --delete-conflicting-outputs
```

## Testes

```bash
fvm flutter test
```

## Análise estática

```bash
fvm flutter analyze
```

## Executar o app

```bash
fvm flutter run
```

Escolha o dispositivo ou emulador conforme o seu ambiente (por exemplo `-d chrome` para web ou o id listado por `fvm flutter devices`).
