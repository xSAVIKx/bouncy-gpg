# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Project

**bouncy-gpg** is a Java convenience library wrapping [Bouncy Castle](https://www.bouncycastle.org/) OpenPGP to provide a fluent, stream-based API for GPG encryption, decryption, signing, and verification. Target: Java 8+, Maven build, Apache 2.0 license.

## Build & Test Commands

```bash
# Full clean build (unit tests only)
./mvnw clean install

# Run all tests including integration tests
./mvnw -B -DskipITs=false -DskipQuality=true verify

# Run only unit tests
./mvnw test

# Run a single test class
./mvnw test -Dtest=ClassName

# Run a single test method
./mvnw test -Dtest=ClassName#methodName

# Run checkstyle + PMD quality checks
./mvnw verify -DskipITs=true -DskipQuality=false

# Build without any quality checks
./mvnw clean install -DskipQuality=true

# Generate JaCoCo coverage report (output: target/jacocoHtml/)
./mvnw verify
```

Key Maven properties: `-DskipITs=true` (default) skips integration tests; `-DskipQuality=true` skips checkstyle/PMD.

## Code Style

- Google Java Style with **100-character line limit** (config: `config/checkstyle/checkstyle.xml`)
- PMD rules at `config/pmd/ruleset.xml`
- No trailing whitespace (enforced by `.pre-commit-config.yaml`)
- `@SuppressWarnings` for PMD "law of Demeter" and "god class" warnings are expected on the main builder/factory classes — these are intentional API design choices

## Architecture

### Entry Point

`BouncyGPG.java` is the sole public entry point with static factory methods:
- `BouncyGPG.encryptToStream()` — fluent builder for encryption output streams
- `BouncyGPG.decryptAndVerifyStream()` — fluent builder for decryption input streams
- `BouncyGPG.createKeyring()` / `createSimpleKeyring()` — key generation
- `BouncyGPG.registerProvider()` — **must be called first** to register the Bouncy Castle JCA provider

### Stream Pipeline

Encryption: plaintext → signature generator → compression → encryption → (optional) ASCII armor → ciphertext

Decryption: ciphertext → decryption → decompression → signature validation (triggered on `close()`) → plaintext

**Critical invariant:** Encryption streams must be properly closed — the PGP signature packet is only written on `close()`. Decryption streams validate signatures on `close()`, so the stream must be fully consumed before signatures are trustworthy.

### Key Abstractions

| Interface/Class | Purpose |
|---|---|
| `KeyringConfig` | Access to public/secret keyrings; implement this to load keys from any source (DB, network, etc.) |
| `KeySelectionStrategy` | Which key to use for a given recipient/signer (default: `Rfc4880KeySelectionStrategy`) |
| `SignatureValidationStrategy` | Pluggable validation: require specific signer, any signer, or ignore signatures |
| `PGPAlgorithmSuite` | Cipher suite (symmetric cipher + hash + compression); predefined options in `DefaultPGPAlgorithmSuites` |

### Package Layout

All source lives under `name.neuhalfen.projects.crypto.bouncycastle.openpgp`:

- `algorithms/` — cipher suite definitions and defaults
- `encrypting/` — `PGPEncryptingStream` (the core encryption `OutputStream`)
- `decrypting/` — `DecryptionStreamFactory` + `SignatureValidatingInputStream`
- `keys/keyrings/` — `KeyringConfig` interface; use `InMemoryKeyring` (not deprecated `FileBasedKeyringConfig`)
- `keys/callbacks/` — passphrase and key selection strategies
- `keys/generation/` — `KeyRingBuilder` (complex RSA keys), `SimpleKeyRingBuilder` (simple RSA)
- `validation/` — signature validation strategy implementations
- `reencryption/` — decrypt-and-re-encrypt ZIP archives without plaintext on disk

### Tests

- Unit tests: `src/test/java/` — JUnit 4 + Hamcrest + Mockito
- Integration tests: `src/integration-test/java/` — GnuPG interop tests (require `gpg` binary); skipped by default
- Test keyring factory: `src/test/java/.../testtooling/Configs.java`
- Concordion BDD specs are present in some test resources
- Coverage target: >85% for non-example code; example modules are excluded from coverage

### Examples

Runnable demos in `examples/{encrypt,decrypt,reencrypt,maven}/` — useful reference for end-to-end usage patterns.
