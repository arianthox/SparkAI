# SparkAI (macOS Swift)

[![CI](https://github.com/arianthox/SparkAI/actions/workflows/ci.yml/badge.svg)](https://github.com/arianthox/SparkAI/actions/workflows/ci.yml)

SparkAI is a macOS-native desktop app for tracking AI account usage and battery state across OpenAI, Claude, and Cursor. It is implemented with SwiftUI, Swift Concurrency, SQLite (GRDB), Keychain-backed secrets, and a modular architecture.

## Architecture

- `SparkAI/App`: app lifecycle, dependency bootstrapping, root tabs
- `SparkAI/Shared/Contracts`: normalized types (`Account`, `UsageSnapshot`, `BatteryStatus`, `SyncRun`)
- `SparkAI/Core/Database`: SQLite schema, migrations, and data access
- `SparkAI/Core/Security`: Keychain credential service
- `SparkAI/Core/Providers`: adapter protocol + provider adapters + typed provider errors
- `SparkAI/Core/Sync`: scheduler, per-account sync, exponential backoff, notification integration
- `SparkAI/Core/Logging`: structured redacting logger
- `SparkAI/Features/*`: Dashboard, Accounts, Settings SwiftUI views/view-models
- `SparkAI/Tests`: unit and integration tests

## Security baseline

- Secrets are never stored in SQLite.
- Credentials are written/read only via `CredentialService` using macOS Keychain.
- Logs run through a redaction layer that masks API keys, tokens, cookies, and authorization headers.
- Provider raw payload persistence is avoided; only normalized fields are stored.

## Current provider limitations

- Adapter implementations include placeholder fetch logic for OpenAI/Claude/Cursor.
- Manual mode is fully supported and explicitly labeled with `confidence = manual`.
- Official endpoint integration should replace placeholders per provider policy and endpoint availability.

## Requirements

- macOS 13+
- Xcode 15+ (or Swift 5.10 toolchain)

## Run locally

```bash
swift package resolve
swift build
swift run SparkAIApp
```

## Run tests

```bash
swift test
```

## Project CI

GitHub Actions workflow:

- resolves dependencies
- builds all targets
- runs tests

See `.github/workflows/ci.yml`.
