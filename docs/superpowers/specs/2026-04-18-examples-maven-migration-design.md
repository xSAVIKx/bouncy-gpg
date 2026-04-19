# Design: Migrate Examples to Maven + CI Validation

**Date:** 2026-04-18
**Status:** Approved

## Goal

Migrate all four bouncy-gpg example projects from Gradle to standalone Maven projects, update them to work with the fork's current version (`io.github.xsavikx:bouncy-gpg:2.3.3`), and add GitHub Actions CI jobs that build and run each example against three dependency sources.

---

## 1. Example Structure

Each example becomes a standalone Maven project. Gradle files (`build.gradle`, `settings.gradle`, `gradlew`, `gradlew.bat`, `.gradle/`, `gradle/`) are deleted from the three Gradle-based examples.

```
examples/
  encrypt/    pom.xml  src/  demo_encrypt.sh   (converted from Gradle)
  decrypt/    pom.xml  src/  demo_decrypt.sh   (converted from Gradle)
  reencrypt/  pom.xml  src/  demo_reencrypt.sh (converted from Gradle)
  maven/      pom.xml  src/                    (updated in-place)
```

### Dependency versions (all examples)

| Artifact | Version |
|---|---|
| `io.github.xsavikx:bouncy-gpg` | `2.3.3` |
| `org.bouncycastle:bcprov-jdk15on` | `1.70` |
| `org.bouncycastle:bcpg-jdk15on` | `1.70` |
| `org.slf4j:slf4j-api` | `1.7.36` |
| `ch.qos.logback:logback-classic` | `1.5.18` |

Java compiler source/target: `1.8` (matching the main library).

---

## 2. Maven Profiles

Each `pom.xml` defines three profiles to select the dependency source.

### `local` (default — activated when no `-P` flag is given)

No extra `<repositories>` block. Resolves `bouncy-gpg` from the local `~/.m2` repository, populated by running `mvn install` on the root project first.

```xml
<profile>
  <id>local</id>
  <activation><activeByDefault>true</activeByDefault></activation>
  <!-- no extra repositories -->
</profile>
```

### `central`

Explicitly targets Maven Central. Useful to verify the artifact is resolvable from the public registry.

```xml
<profile>
  <id>central</id>
  <repositories>
    <repository>
      <id>central</id>
      <url>https://repo.maven.apache.org/maven2</url>
    </repository>
  </repositories>
</profile>
```

### `github`

Adds the GitHub Packages registry for the fork. Requires a `<server id="github">` entry with a PAT in `~/.m2/settings.xml` (locally) or injected via CI secrets.

```xml
<profile>
  <id>github</id>
  <repositories>
    <repository>
      <id>github</id>
      <url>https://maven.pkg.github.com/xsavikx/bouncy-gpg</url>
    </repository>
  </repositories>
</profile>
```

---

## 3. Running Examples

Each example uses `maven-exec-plugin` to allow `mvn exec:java -Dexec.args="..."`. The `mainClass` is configured in the plugin inside each `pom.xml`.

For the three file-based examples (encrypt, decrypt, reencrypt), test PGP key files are copied from the main project's test resources into `src/test/resources/` of each example so CI can provide known file paths as arguments.

The `maven` example embeds keys inline in `App.java` — no extra key files needed.

---

## 4. CI Jobs

Added to `.github/workflows/maven-ci.yml` as three jobs that run after the existing build job succeeds (`needs: build`).

### `examples-local`

1. Check out repo
2. Set up Java 11
3. `mvn install -DskipTests -DskipITs=true -DskipQuality=true` on root (populates `~/.m2`)
4. For each example: `mvn package exec:java` (default `local` profile)

### `examples-central`

1. Check out repo
2. Set up Java 11
3. For each example: `mvn package exec:java -P central`

No root install needed — resolves from Maven Central.

### `examples-github`

1. Check out repo
2. Set up Java 11
3. Write a `settings.xml` that injects `GITHUB_TOKEN` as the PAT for the `github` server ID
4. For each example: `mvn package exec:java -P github --settings $GITHUB_WORKSPACE/.github/maven-settings.xml`

Requires repository secret `GITHUB_TOKEN` (available automatically in GitHub Actions).

### `maven-settings.xml` template (`.github/maven-settings.xml`)

```xml
<settings>
  <servers>
    <server>
      <id>github</id>
      <username>${env.GITHUB_ACTOR}</username>
      <password>${env.GITHUB_TOKEN}</password>
    </server>
  </servers>
</settings>
```

---

## 5. Files Changed / Created

| Action | Path |
|---|---|
| Delete | `examples/decrypt/build.gradle`, `settings.gradle`, `gradlew`, `gradlew.bat`, `gradle/` |
| Delete | `examples/encrypt/build.gradle`, `settings.gradle`, `gradlew`, `gradlew.bat`, `gradle/` |
| Delete | `examples/reencrypt/build.gradle`, `settings.gradle`, `gradlew`, `gradlew.bat`, `gradle/` |
| Create | `examples/decrypt/pom.xml` |
| Create | `examples/encrypt/pom.xml` |
| Create | `examples/reencrypt/pom.xml` |
| Update | `examples/maven/pom.xml` (versions + profiles) |
| Create | `.github/maven-settings.xml` |
| Update | `.github/workflows/maven-ci.yml` (add 3 jobs) |
| Copy | Test PGP key files into each file-based example's `src/test/resources/` |
