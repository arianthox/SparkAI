# SparkAI Security Notes

## Credential handling

- Credentials are stored in macOS Keychain using `kSecClassGenericPassword`.
- The database only stores metadata/reference values (for example keychain account reference), never plaintext credentials.
- Credential operations are centralized in `SparkAI/Core/Security/CredentialService.swift`.

## Redaction policy

- Logging is routed through `RedactingLogger`.
- Redaction patterns mask:
  - authorization bearer values
  - API keys
  - generic token-like fields
  - cookie values
- Debug mode can increase log detail but still applies redaction before writing.

## Threat model

Assumptions:

- Device is trusted and user account is not compromised.
- macOS Keychain protections are available and functioning.
- Local attacker without user session unlock cannot read Keychain-protected secrets.

Primary risks considered:

- Accidental secret leakage in logs or persisted payloads.
- Excessive retry behavior causing account lockouts or notification spam.
- Schema changes breaking historical sync data.

Mitigations:

- Centralized credential service.
- Redaction in logging path.
- Debounced notifications.
- Forward-only DB migrations with migration tests.

## Known limitations

- Provider adapters currently include placeholder endpoint logic; production rollout requires validating official APIs and auth workflows.
- This repository is macOS-focused and does not yet include hardened runtime entitlements/signing profiles.
- Network transport pinning is not implemented in this version.
