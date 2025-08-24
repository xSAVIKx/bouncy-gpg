bouncy-gpg – Development Guidelines (Project-specific)

Date verified: 2025-08-15 13:34 local (Windows 11, Java 11, Gradle Wrapper 7.6.2)

Overview
- Build system: Gradle Wrapper 7.6.2 (java-library). Source/target: Java 8. Tested on JDK 8 and 11 (CI matrix), local run on JDK 11.
- Test stack: JUnit 4.13, Hamcrest 1.3, Mockito 3.2.4, Concordion extension for documentation-specs. Integration tests are a dedicated source set.
- Code quality: Checkstyle 8.24 and PMD 6.20.0 (applied to main sources only). JaCoCo 0.8.11 for coverage.
- Packaging: OSGi (bnd), publishing via maven-publish/signing. Historical Bintray plugin present; not used in routine dev.

Build and configuration
1) JDK
   - Build targets Java 8. Use JDK 8 or 11 locally. CI runs both (see .github/workflows/ci.yaml).
   - Verify toolchain: .\gradlew.bat --version

2) Standard builds
   - Full build (runs unit + integration tests via check):
     .\gradlew.bat build --stacktrace --warning-mode all
   - Build without integration tests (useful if GnuPG 2 is not installed):
     .\gradlew.bat build -x integrationTest --stacktrace --warning-mode all
   - Only compile (no tests):
     .\gradlew.bat assemble

3) Repositories
   - mavenCentral is primary. jcenter() is still referenced and will emit a deprecation warning on Gradle 7.x; safe to ignore for local dev. Consider removing it in future maintenance.

4) Useful tasks and plugins
   - dependencyUpdates (com.github.ben-manes.versions):
     .\gradlew.bat dependencyUpdates -Drevision=release
   - OSGi manifest (biz.aQute.bnd.builder) is configured implicitly; no special local steps.
   - Website/docs (requires Hugo): see “Website tasks” below.

Testing
A) Layout and execution
- Unit tests: src\test\java and src\test\resources
  Run all unit tests:
  .\gradlew.bat test

- Integration tests: src\integration-test\java and src\integration-test\resources
  Run integration tests only:
  .\gradlew.bat integrationTest

- All verification (unit + integration + quality gates):
  .\gradlew.bat check
  Note: build depends on check, and check depends on integrationTest (see build.gradle). If GnuPG 2 is missing, use -x integrationTest.

B) Selecting tests
- Run one unit test class:
  .\gradlew.bat test --tests name.neuhalfen.projects.crypto.bouncycastle.openpgp.decrypting.DecryptionStreamFactoryTest
- Pattern match across methods/classes:
  .\gradlew.bat test --tests "*DecryptionStreamFactoryTest*"
- For integration tests, use the same flag against the integrationTest task:
  .\gradlew.bat integrationTest --tests name.neuhalfen.projects.crypto.bouncycastle.openpgp.integration.BouncyGPGCanEncryptToGPG

C) Integration test prerequisites and quirks
- Requires GnuPG 2 (>= 2.0). The test driver auto-detects gpg2 or gpg (GPGExec.locateGpg2()). On Windows, Gpg4win’s gpg.exe is sufficient.
  - Verify: gpg --version  (should report major version 2)
  - Make sure gpg is on PATH.
- Tests run gpg with a temporary GNUPGHOME and enable pinentry-mode loopback on >= 2.1. They also set trust-model always. Expect per-command logs in that temp GNUPGHOME during execution.
- IPC instability of gpg-agent: The driver serializes execution and uses shorter timeouts (15s). If you see intermittent failures, re-run with:
  .\gradlew.bat --no-daemon -Dorg.gradle.workers.max=1 integrationTest --info

D) Resources/fixtures
- Test keys live in src\test\resources\sender.gpg.d and src\test\resources\recipient.gpg.d.
- Concordion specs are under src\test\resources\specs; Gradle sets system property concordion.output.dir.

E) Coverage and test reports
- Generate coverage report (JaCoCo):
  .\gradlew.bat jacocoTestReport
  HTML: build\jacocoHtml\index.html
- Concordion output:
  build\reports\specs\concordion (configured via specifications_concordion_target in build.gradle)

F) Adding new tests
- Use JUnit 4 (org.junit.Test) and Hamcrest assertions as in existing tests. Place unit tests under src\test\java, integration tests under src\integration-test\java.
- Prefer deterministic tests that don’t depend on external binaries unless placed in integration-test.
- Example minimal unit test (validated locally):
  File: src\test\java\demo\DemoSanityTest.java
  --------------------------------------------------
  package demo;

  import org.junit.Test;
  import static org.junit.Assert.*;

  public class DemoSanityTest {
      @Test public void sanity() { assertTrue(true); }
  }
  --------------------------------------------------
  Run just this test:
  .\gradlew.bat test --tests demo.DemoSanityTest
  Validation: Executed successfully on 2025-08-15 with Gradle 7.6.2 and JDK 11.
  Clean-up: Remove the demo file after verifying the flow (it is not needed by the project).

Code quality and style
- Checkstyle (8.24): configured for main sources only (tests are excluded). Config file: config\checkstyle\checkstyle.xml. Reports: build\reports\checkstyle\main.xml
  Run: .\gradlew.bat checkstyleMain
- PMD (6.20.0): applies to main sources. Config: config\pmd\ruleset.xml. Reports under build\reports\pmd
  Run: .\gradlew.bat pmdMain
- Both are typically wired into the check lifecycle. For quick iteration while writing tests, run only test or integrationTest.
- Known dependency resolution quirk: For Checkstyle, build.gradle configures a capability resolution to avoid the legacy google-collections vs guava conflict.

Website tasks (documentation site)
- Generate site from Concordion output using Hugo (optional, for documentation contributors):
  - Ensure Hugo is installed. To specify a custom executable, pass -PHUGO_EXEC=path\to\hugo.exe
  - Generate static site:
    .\gradlew.bat generateWebsite
    Output: build\website
  - Preview site with live server:
    .\gradlew.bat previewWebsite
  - Publishing uses org.ajoberstar.git-publish and targets gh-pages; requires repo access. Task alias:
    .\gradlew.bat publishWebsite

Publishing (advanced)
- maven-publish and signing plugins are applied. Credentials/keys are expected via gradle.properties (see gradle.properties.tpl for template). Not required for local development.
- The com.jfrog.bintray plugin remains for historical reasons; Bintray/JCenter are EOL.

Troubleshooting tips
- jcenter deprecation warnings are expected with Gradle 7.x; safe to ignore for dev tasks.
- If integration tests fail due to GPG version or agent issues, either install/configure GnuPG 2 properly or exclude integrationTest (-x integrationTest) while iterating on code.
- To inspect failing test output, re-run with --info or --stacktrace. Concordion HTML output in build\reports\specs\concordion can be useful when working on documentation-driven specs.

Quick commands (Windows PowerShell)
- Unit tests only:           .\gradlew.bat test
- Specific unit test:       .\gradlew.bat test --tests full.class.Name
- Integration tests only:   .\gradlew.bat integrationTest
- Skip integration tests:   .\gradlew.bat build -x integrationTest
- Coverage HTML:            .\gradlew.bat jacocoTestReport
- Lint (main sources):      .\gradlew.bat checkstyleMain pmdMain
- Dependency updates:       .\gradlew.bat dependencyUpdates
