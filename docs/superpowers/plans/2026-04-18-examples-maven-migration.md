# Examples Maven Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert three Gradle example projects to standalone Maven, update the existing Maven example, and add three CI jobs that build and run all four examples against local, Maven Central, and GitHub Packages.

**Architecture:** Each example is a standalone `pom.xml` with three profiles (`local`/`central`/`github`). All examples use `exec-maven-plugin` for `mvn exec:java`. CI round-trips: encrypt writes to `/tmp`, decrypt reads from it, reencrypt re-encrypts a zip created from that same pipeline. All examples use the recipient keyring (`recipient@example.com`) for signing, encryption, and decryption so no cross-keyring signature verification issues arise.

**Tech Stack:** Maven 3, exec-maven-plugin 3.2.0, `io.github.xsavikx:bouncy-gpg:2.3.3`, BC 1.70, Java 8+, GitHub Actions.

---

## File Map

| Action | Path |
|---|---|
| Create | `examples/encrypt/pom.xml` |
| Copy | `examples/encrypt/src/test/resources/keys/recipient.gpg.d/pubring.gpg` |
| Copy | `examples/encrypt/src/test/resources/keys/recipient.gpg.d/secring.gpg` |
| Modify | `examples/encrypt/demo_encrypt.sh` |
| Delete | `examples/encrypt/build.gradle`, `settings.gradle`, `gradlew`, `gradlew.bat`, `gradle/` |
| Create | `examples/decrypt/pom.xml` |
| Copy | `examples/decrypt/src/test/resources/keys/recipient.gpg.d/pubring.gpg` |
| Copy | `examples/decrypt/src/test/resources/keys/recipient.gpg.d/secring.gpg` |
| Modify | `examples/decrypt/demo_decrypt.sh` |
| Delete | `examples/decrypt/build.gradle`, `settings.gradle`, `gradlew`, `gradlew.bat`, `gradle/` |
| Create | `examples/reencrypt/pom.xml` |
| Copy | `examples/reencrypt/src/test/resources/keys/recipient.gpg.d/pubring.gpg` |
| Copy | `examples/reencrypt/src/test/resources/keys/recipient.gpg.d/secring.gpg` |
| Modify | `examples/reencrypt/demo_reencrypt.sh` |
| Delete | `examples/reencrypt/build.gradle`, `settings.gradle`, `gradlew`, `gradlew.bat`, `gradle/` |
| Modify | `examples/maven/pom.xml` |
| Create | `.github/maven-settings.xml` |
| Modify | `.github/workflows/maven-ci.yml` |

---

## Task 1: Convert encrypt example to Maven

**Files:**
- Create: `examples/encrypt/pom.xml`
- Create: `examples/encrypt/src/test/resources/keys/recipient.gpg.d/pubring.gpg` (binary copy)
- Create: `examples/encrypt/src/test/resources/keys/recipient.gpg.d/secring.gpg` (binary copy)
- Modify: `examples/encrypt/demo_encrypt.sh`
- Delete: `examples/encrypt/build.gradle`, `settings.gradle`, `gradlew`, `gradlew.bat`, `gradle/`

- [ ] **Step 1.1: Create examples/encrypt/pom.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>name.neuhalfen.projects.crypto.bouncycastle.openpgp.examples</groupId>
  <artifactId>encrypt-example</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>

  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <bouncycastle.version>1.70</bouncycastle.version>
    <slf4j.version>1.7.36</slf4j.version>
    <maven.compiler.source>1.8</maven.compiler.source>
    <maven.compiler.target>1.8</maven.compiler.target>
  </properties>

  <dependencies>
    <dependency>
      <groupId>io.github.xsavikx</groupId>
      <artifactId>bouncy-gpg</artifactId>
      <version>2.3.3</version>
    </dependency>
    <dependency>
      <groupId>org.bouncycastle</groupId>
      <artifactId>bcprov-jdk15on</artifactId>
      <version>${bouncycastle.version}</version>
    </dependency>
    <dependency>
      <groupId>org.bouncycastle</groupId>
      <artifactId>bcpg-jdk15on</artifactId>
      <version>${bouncycastle.version}</version>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-api</artifactId>
      <version>${slf4j.version}</version>
    </dependency>
    <dependency>
      <groupId>ch.qos.logback</groupId>
      <artifactId>logback-classic</artifactId>
      <version>1.5.18</version>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.codehaus.mojo</groupId>
        <artifactId>exec-maven-plugin</artifactId>
        <version>3.2.0</version>
        <configuration>
          <mainClass>name.neuhalfen.projects.crypto.bouncycastle.openpgp.example.EncryptMain</mainClass>
        </configuration>
      </plugin>
    </plugins>
  </build>

  <profiles>
    <profile>
      <id>local</id>
      <activation>
        <activeByDefault>true</activeByDefault>
      </activation>
    </profile>
    <profile>
      <id>central</id>
      <repositories>
        <repository>
          <id>maven-central</id>
          <url>https://repo.maven.apache.org/maven2</url>
        </repository>
      </repositories>
    </profile>
    <profile>
      <id>github</id>
      <repositories>
        <repository>
          <id>github</id>
          <url>https://maven.pkg.github.com/xsavikx/bouncy-gpg</url>
        </repository>
      </repositories>
    </profile>
  </profiles>
</project>
```

- [ ] **Step 1.2: Copy recipient key files into encrypt example**

Run from repo root:
```bash
mkdir -p examples/encrypt/src/test/resources/keys/recipient.gpg.d
cp src/test/resources/recipient.gpg.d/pubring.gpg examples/encrypt/src/test/resources/keys/recipient.gpg.d/pubring.gpg
cp src/test/resources/recipient.gpg.d/secring.gpg examples/encrypt/src/test/resources/keys/recipient.gpg.d/secring.gpg
```

- [ ] **Step 1.3: Verify encrypt compiles from its directory**

```bash
cd examples/encrypt
mvn compile
```

Expected: BUILD SUCCESS

- [ ] **Step 1.4: Verify encrypt runs**

```bash
cd examples/encrypt
echo "Hello bouncy-gpg" > /tmp/hello.txt
mvn exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/hello.txt /tmp/hello.txt.gpg"
ls -la /tmp/hello.txt.gpg
```

Expected: BUILD SUCCESS, `/tmp/hello.txt.gpg` exists and is non-empty.

- [ ] **Step 1.5: Replace demo_encrypt.sh**

Write `examples/encrypt/demo_encrypt.sh`:
```bash
#!/usr/bin/env bash
# Usage: ./demo_encrypt.sh sourceFile destFile
if [ "x$2" = "x" ]; then
  echo "Usage: $0 sourceFile destFile"
  exit 1
fi
mvn exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient $1 $2"
```

```bash
chmod +x examples/encrypt/demo_encrypt.sh
```

- [ ] **Step 1.6: Delete Gradle files**

```bash
cd examples/encrypt
rm -f build.gradle settings.gradle gradlew gradlew.bat
rm -rf .gradle gradle
```

- [ ] **Step 1.7: Commit**

```bash
git add examples/encrypt/
git commit -m "feat(examples): convert encrypt example from Gradle to Maven"
```

---

## Task 2: Convert decrypt example to Maven

**Files:**
- Create: `examples/decrypt/pom.xml`
- Create: `examples/decrypt/src/test/resources/keys/recipient.gpg.d/pubring.gpg` (binary copy)
- Create: `examples/decrypt/src/test/resources/keys/recipient.gpg.d/secring.gpg` (binary copy)
- Modify: `examples/decrypt/demo_decrypt.sh`
- Delete: `examples/decrypt/build.gradle`, `settings.gradle`, `gradlew`, `gradlew.bat`, `gradle/`

- [ ] **Step 2.1: Create examples/decrypt/pom.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>name.neuhalfen.projects.crypto.bouncycastle.openpgp.examples</groupId>
  <artifactId>decrypt-example</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>

  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <bouncycastle.version>1.70</bouncycastle.version>
    <slf4j.version>1.7.36</slf4j.version>
    <maven.compiler.source>1.8</maven.compiler.source>
    <maven.compiler.target>1.8</maven.compiler.target>
  </properties>

  <dependencies>
    <dependency>
      <groupId>io.github.xsavikx</groupId>
      <artifactId>bouncy-gpg</artifactId>
      <version>2.3.3</version>
    </dependency>
    <dependency>
      <groupId>org.bouncycastle</groupId>
      <artifactId>bcprov-jdk15on</artifactId>
      <version>${bouncycastle.version}</version>
    </dependency>
    <dependency>
      <groupId>org.bouncycastle</groupId>
      <artifactId>bcpg-jdk15on</artifactId>
      <version>${bouncycastle.version}</version>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-api</artifactId>
      <version>${slf4j.version}</version>
    </dependency>
    <dependency>
      <groupId>ch.qos.logback</groupId>
      <artifactId>logback-classic</artifactId>
      <version>1.5.18</version>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.codehaus.mojo</groupId>
        <artifactId>exec-maven-plugin</artifactId>
        <version>3.2.0</version>
        <configuration>
          <mainClass>name.neuhalfen.projects.crypto.bouncycastle.openpgp.example.DecryptMain</mainClass>
        </configuration>
      </plugin>
    </plugins>
  </build>

  <profiles>
    <profile>
      <id>local</id>
      <activation>
        <activeByDefault>true</activeByDefault>
      </activation>
    </profile>
    <profile>
      <id>central</id>
      <repositories>
        <repository>
          <id>maven-central</id>
          <url>https://repo.maven.apache.org/maven2</url>
        </repository>
      </repositories>
    </profile>
    <profile>
      <id>github</id>
      <repositories>
        <repository>
          <id>github</id>
          <url>https://maven.pkg.github.com/xsavikx/bouncy-gpg</url>
        </repository>
      </repositories>
    </profile>
  </profiles>
</project>
```

- [ ] **Step 2.2: Copy recipient key files into decrypt example**

```bash
mkdir -p examples/decrypt/src/test/resources/keys/recipient.gpg.d
cp src/test/resources/recipient.gpg.d/pubring.gpg examples/decrypt/src/test/resources/keys/recipient.gpg.d/pubring.gpg
cp src/test/resources/recipient.gpg.d/secring.gpg examples/decrypt/src/test/resources/keys/recipient.gpg.d/secring.gpg
```

- [ ] **Step 2.3: Verify decrypt compiles**

```bash
cd examples/decrypt
mvn compile
```

Expected: BUILD SUCCESS

- [ ] **Step 2.4: Verify decrypt runs (requires Task 1 Step 1.4 to have produced /tmp/hello.txt.gpg)**

```bash
cd examples/decrypt
mvn exec:java -Dexec.args="src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/hello.txt.gpg /tmp/hello-decrypted.txt"
cat /tmp/hello-decrypted.txt
```

Expected: BUILD SUCCESS, output file contains `Hello bouncy-gpg`.

- [ ] **Step 2.5: Replace demo_decrypt.sh**

Write `examples/decrypt/demo_decrypt.sh`:
```bash
#!/usr/bin/env bash
# Usage: ./demo_decrypt.sh sourceFile.gpg destFile
if [ "x$2" = "x" ]; then
  echo "Usage: $0 sourceFile.gpg destFile"
  exit 1
fi
mvn exec:java -Dexec.args="src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient $1 $2"
```

```bash
chmod +x examples/decrypt/demo_decrypt.sh
```

- [ ] **Step 2.6: Delete Gradle files**

```bash
cd examples/decrypt
rm -f build.gradle settings.gradle gradlew gradlew.bat
rm -rf .gradle gradle
```

- [ ] **Step 2.7: Commit**

```bash
git add examples/decrypt/
git commit -m "feat(examples): convert decrypt example from Gradle to Maven"
```

---

## Task 3: Convert reencrypt example to Maven

**Files:**
- Create: `examples/reencrypt/pom.xml`
- Create: `examples/reencrypt/src/test/resources/keys/recipient.gpg.d/pubring.gpg` (binary copy)
- Create: `examples/reencrypt/src/test/resources/keys/recipient.gpg.d/secring.gpg` (binary copy)
- Modify: `examples/reencrypt/demo_reencrypt.sh`
- Delete: `examples/reencrypt/build.gradle`, `settings.gradle`, `gradlew`, `gradlew.bat`, `gradle/`

- [ ] **Step 3.1: Create examples/reencrypt/pom.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>name.neuhalfen.projects.crypto.bouncycastle.openpgp.examples</groupId>
  <artifactId>reencrypt-example</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>

  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <bouncycastle.version>1.70</bouncycastle.version>
    <slf4j.version>1.7.36</slf4j.version>
    <maven.compiler.source>1.8</maven.compiler.source>
    <maven.compiler.target>1.8</maven.compiler.target>
  </properties>

  <dependencies>
    <dependency>
      <groupId>io.github.xsavikx</groupId>
      <artifactId>bouncy-gpg</artifactId>
      <version>2.3.3</version>
    </dependency>
    <dependency>
      <groupId>org.bouncycastle</groupId>
      <artifactId>bcprov-jdk15on</artifactId>
      <version>${bouncycastle.version}</version>
    </dependency>
    <dependency>
      <groupId>org.bouncycastle</groupId>
      <artifactId>bcpg-jdk15on</artifactId>
      <version>${bouncycastle.version}</version>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-api</artifactId>
      <version>${slf4j.version}</version>
    </dependency>
    <dependency>
      <groupId>ch.qos.logback</groupId>
      <artifactId>logback-classic</artifactId>
      <version>1.5.18</version>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.codehaus.mojo</groupId>
        <artifactId>exec-maven-plugin</artifactId>
        <version>3.2.0</version>
        <configuration>
          <mainClass>name.neuhalfen.projects.crypto.bouncycastle.openpgp.example.MainExplodedSinglethreaded</mainClass>
        </configuration>
      </plugin>
    </plugins>
  </build>

  <profiles>
    <profile>
      <id>local</id>
      <activation>
        <activeByDefault>true</activeByDefault>
      </activation>
    </profile>
    <profile>
      <id>central</id>
      <repositories>
        <repository>
          <id>maven-central</id>
          <url>https://repo.maven.apache.org/maven2</url>
        </repository>
      </repositories>
    </profile>
    <profile>
      <id>github</id>
      <repositories>
        <repository>
          <id>github</id>
          <url>https://maven.pkg.github.com/xsavikx/bouncy-gpg</url>
        </repository>
      </repositories>
    </profile>
  </profiles>
</project>
```

- [ ] **Step 3.2: Copy recipient key files into reencrypt example**

```bash
mkdir -p examples/reencrypt/src/test/resources/keys/recipient.gpg.d
cp src/test/resources/recipient.gpg.d/pubring.gpg examples/reencrypt/src/test/resources/keys/recipient.gpg.d/pubring.gpg
cp src/test/resources/recipient.gpg.d/secring.gpg examples/reencrypt/src/test/resources/keys/recipient.gpg.d/secring.gpg
```

- [ ] **Step 3.3: Verify reencrypt compiles**

```bash
cd examples/reencrypt
mvn compile
```

Expected: BUILD SUCCESS

- [ ] **Step 3.4: Verify reencrypt runs (requires a .zip.gpg; use encrypt to create one)**

```bash
# From repo root — create a test zip then encrypt it
zip /tmp/test.zip /etc/hostname
cd examples/encrypt
mvn exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/test.zip /tmp/test.zip.gpg"
cd ../reencrypt
mkdir -p /tmp/reencrypt-out
mvn exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/test.zip.gpg /tmp/reencrypt-out"
ls /tmp/reencrypt-out
```

Expected: BUILD SUCCESS, `/tmp/reencrypt-out` contains at least one `.gpg` file.

- [ ] **Step 3.5: Replace demo_reencrypt.sh**

Write `examples/reencrypt/demo_reencrypt.sh`:
```bash
#!/usr/bin/env bash
# Usage: ./demo_reencrypt.sh sourceFile.zip.gpg destPath
if [ "x$2" = "x" ]; then
  echo "Usage: $0 sourceFile.zip.gpg destPath"
  exit 1
fi
DEST="$2"
mkdir -p "$DEST"
mvn exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient $1 $DEST"
```

```bash
chmod +x examples/reencrypt/demo_reencrypt.sh
```

- [ ] **Step 3.6: Delete Gradle files**

```bash
cd examples/reencrypt
rm -f build.gradle settings.gradle gradlew gradlew.bat
rm -rf .gradle gradle
```

- [ ] **Step 3.7: Commit**

```bash
git add examples/reencrypt/
git commit -m "feat(examples): convert reencrypt example from Gradle to Maven"
```

---

## Task 4: Update maven example pom.xml

**Files:**
- Modify: `examples/maven/pom.xml`

- [ ] **Step 4.1: Replace examples/maven/pom.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>name.neuhalfen.projects.crypto.bouncycastle.openpgp.examples</groupId>
  <artifactId>maven-example</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>

  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <bouncycastle.version>1.70</bouncycastle.version>
    <slf4j.version>1.7.36</slf4j.version>
    <maven.compiler.source>1.8</maven.compiler.source>
    <maven.compiler.target>1.8</maven.compiler.target>
  </properties>

  <dependencies>
    <dependency>
      <groupId>io.github.xsavikx</groupId>
      <artifactId>bouncy-gpg</artifactId>
      <version>2.3.3</version>
    </dependency>
    <dependency>
      <groupId>org.bouncycastle</groupId>
      <artifactId>bcprov-jdk15on</artifactId>
      <version>${bouncycastle.version}</version>
    </dependency>
    <dependency>
      <groupId>org.bouncycastle</groupId>
      <artifactId>bcpg-jdk15on</artifactId>
      <version>${bouncycastle.version}</version>
    </dependency>
    <dependency>
      <groupId>ch.qos.logback</groupId>
      <artifactId>logback-classic</artifactId>
      <version>1.5.18</version>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.codehaus.mojo</groupId>
        <artifactId>exec-maven-plugin</artifactId>
        <version>3.2.0</version>
        <configuration>
          <mainClass>name.neuhalfen.projects.crypto.bouncycastle.openpgp.example.maven.App</mainClass>
        </configuration>
      </plugin>
    </plugins>
  </build>

  <profiles>
    <profile>
      <id>local</id>
      <activation>
        <activeByDefault>true</activeByDefault>
      </activation>
    </profile>
    <profile>
      <id>central</id>
      <repositories>
        <repository>
          <id>maven-central</id>
          <url>https://repo.maven.apache.org/maven2</url>
        </repository>
      </repositories>
    </profile>
    <profile>
      <id>github</id>
      <repositories>
        <repository>
          <id>github</id>
          <url>https://maven.pkg.github.com/xsavikx/bouncy-gpg</url>
        </repository>
      </repositories>
    </profile>
  </profiles>
</project>
```

- [ ] **Step 4.2: Verify maven example compiles and runs**

```bash
cd examples/maven
mvn compile exec:java
```

Expected: BUILD SUCCESS, output includes `Encrypting ...`, `Decrypting ...`, and the original message `I'm a little teapot!`.

- [ ] **Step 4.3: Commit**

```bash
git add examples/maven/pom.xml
git commit -m "feat(examples): update maven example to bouncy-gpg 2.3.3 with source profiles"
```

---

## Task 5: Add GitHub Maven settings file

**Files:**
- Create: `.github/maven-settings.xml`

- [ ] **Step 5.1: Create .github/maven-settings.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0 http://maven.apache.org/xsd/settings-1.2.0.xsd">
  <servers>
    <server>
      <id>github</id>
      <username>${env.GITHUB_ACTOR}</username>
      <password>${env.GITHUB_TOKEN}</password>
    </server>
  </servers>
</settings>
```

- [ ] **Step 5.2: Commit**

```bash
git add .github/maven-settings.xml
git commit -m "ci: add Maven settings template for GitHub Packages authentication"
```

---

## Task 6: Add example CI jobs to maven-ci.yml

**Files:**
- Modify: `.github/workflows/maven-ci.yml`

The three jobs are appended after the existing `build` job. Each job checks out the repo, sets up Java 11, then runs all four examples in sequence. The sequence within each job is: maven → encrypt → decrypt (uses encrypt output) → reencrypt (uses encrypt output on a zip).

The `local` job installs the library from source first. The `central` and `github` jobs rely on remote registries and do NOT use `cache: maven` (so the local repo starts empty, ensuring a genuine remote download).

- [ ] **Step 6.1: Append three jobs to .github/workflows/maven-ci.yml**

Add the following to the end of `.github/workflows/maven-ci.yml` (after the existing `build` job):

```yaml
  examples-local:
    name: Examples (local install)
    needs: build
    runs-on: ubuntu-24.04
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Set up JDK 11
        uses: actions/setup-java@v5
        with:
          distribution: 'temurin'
          java-version: '11'
          cache: 'maven'

      - name: Install library to local Maven repo
        run: ./mvnw -B -DskipTests -DskipITs=true -DskipQuality=true install

      - name: Run maven example
        working-directory: examples/maven
        run: mvn exec:java

      - name: Run encrypt example
        working-directory: examples/encrypt
        run: |
          echo "Hello bouncy-gpg" > /tmp/hello.txt
          zip /tmp/test.zip /etc/hostname
          mvn exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/hello.txt /tmp/hello.txt.gpg"
          mvn exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/test.zip /tmp/test.zip.gpg"

      - name: Run decrypt example
        working-directory: examples/decrypt
        run: |
          mvn exec:java -Dexec.args="src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/hello.txt.gpg /tmp/hello-decrypted.txt"
          grep -q "Hello bouncy-gpg" /tmp/hello-decrypted.txt

      - name: Run reencrypt example
        working-directory: examples/reencrypt
        run: |
          mkdir -p /tmp/reencrypt-out
          mvn exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/test.zip.gpg /tmp/reencrypt-out"
          ls /tmp/reencrypt-out

  examples-central:
    name: Examples (Maven Central)
    needs: build
    runs-on: ubuntu-24.04
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Set up JDK 11
        uses: actions/setup-java@v5
        with:
          distribution: 'temurin'
          java-version: '11'

      - name: Run maven example
        working-directory: examples/maven
        run: mvn -P central exec:java

      - name: Run encrypt example
        working-directory: examples/encrypt
        run: |
          echo "Hello bouncy-gpg" > /tmp/hello.txt
          zip /tmp/test.zip /etc/hostname
          mvn -P central exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/hello.txt /tmp/hello.txt.gpg"
          mvn -P central exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/test.zip /tmp/test.zip.gpg"

      - name: Run decrypt example
        working-directory: examples/decrypt
        run: |
          mvn -P central exec:java -Dexec.args="src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/hello.txt.gpg /tmp/hello-decrypted.txt"
          grep -q "Hello bouncy-gpg" /tmp/hello-decrypted.txt

      - name: Run reencrypt example
        working-directory: examples/reencrypt
        run: |
          mkdir -p /tmp/reencrypt-out
          mvn -P central exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/test.zip.gpg /tmp/reencrypt-out"
          ls /tmp/reencrypt-out

  examples-github:
    name: Examples (GitHub Packages)
    needs: build
    runs-on: ubuntu-24.04
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Set up JDK 11
        uses: actions/setup-java@v5
        with:
          distribution: 'temurin'
          java-version: '11'

      - name: Run maven example
        working-directory: examples/maven
        run: mvn -P github --settings $GITHUB_WORKSPACE/.github/maven-settings.xml exec:java
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Run encrypt example
        working-directory: examples/encrypt
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          echo "Hello bouncy-gpg" > /tmp/hello.txt
          zip /tmp/test.zip /etc/hostname
          mvn -P github --settings $GITHUB_WORKSPACE/.github/maven-settings.xml exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/hello.txt /tmp/hello.txt.gpg"
          mvn -P github --settings $GITHUB_WORKSPACE/.github/maven-settings.xml exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/test.zip /tmp/test.zip.gpg"

      - name: Run decrypt example
        working-directory: examples/decrypt
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          mvn -P github --settings $GITHUB_WORKSPACE/.github/maven-settings.xml exec:java -Dexec.args="src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/hello.txt.gpg /tmp/hello-decrypted.txt"
          grep -q "Hello bouncy-gpg" /tmp/hello-decrypted.txt

      - name: Run reencrypt example
        working-directory: examples/reencrypt
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          mkdir -p /tmp/reencrypt-out
          mvn -P github --settings $GITHUB_WORKSPACE/.github/maven-settings.xml exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient /tmp/test.zip.gpg /tmp/reencrypt-out"
          ls /tmp/reencrypt-out
```

- [ ] **Step 6.2: Verify the YAML is syntactically valid**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/maven-ci.yml'))" && echo "YAML valid"
```

Expected: `YAML valid`

- [ ] **Step 6.3: Commit**

```bash
git add .github/workflows/maven-ci.yml
git commit -m "ci: add example validation jobs for local, central, and github profiles"
```
