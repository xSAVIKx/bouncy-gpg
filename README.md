**Looking for contributors**: *_It's boring to work alone_ - If you are interested in contributing to an open source project please open an issue to discuss your ideas or create a PR*

[![Build Status](https://github.com/neuhalje/bouncy-gpg/actions/workflows/ci.yaml/badge.svg)](https://github.com/neuhalje/bouncy-gpg/actions/workflows/ci.yaml)
[![codecov](https://codecov.io/gh/neuhalje/bouncy-gpg/branch/master/graph/badge.svg)](https://codecov.io/gh/neuhalje/bouncy-gpg)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/86c099743f8b484c8da833495d7dc209)](https://www.codacy.com/app/neuhalje/bouncy-gpg?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=neuhalje/bouncy-gpg&amp;utm_campaign=Badge_Grade)
[![license](https://img.shields.io/badge/license-APACHE%202.0-brightgreen.svg)](https://www.apache.org/licenses/LICENSE-2.0.html)
[![Download](https://api.bintray.com/packages/neuhalje/maven/bouncy-gpg/images/download.svg)](https://bintray.com/neuhalje/maven/bouncy-gpg/_latestVersion)
[![Known Vulnerabilities](https://snyk.io/test/github/neuhalje/bouncy-gpg/badge.svg?targetFile=build.gradle)](https://snyk.io/test/github/neuhalje/bouncy-gpg?targetFile=build.gradle)

[![Say Thanks!](https://img.shields.io/badge/Say%20Thanks-!-1EAEDB.svg)](https://saythanks.io/to/neuhalje)


Mission Statement
=======================

  **Make using [Bouncy Castle](http://bouncycastle.org/) with [OpenPGP](https://tools.ietf.org/html/rfc4880) ~~great~~ fun again!**

This project gives you the following super-powers

- encrypt, decrypt, sign and verify GPG/PGP files with just a few lines of code
- protect all the data at rest by reading encrypted files with [transparent GPG decryption](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/decrypting/DecryptionStreamFactory.java)
- you can even [decrypt a gpg encrypted ZIP and re-encrypt each file in it again](examples/reencrypt/src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/example/MainExplodedSinglethreaded.java) -- never again let plaintext hit your servers disk!

Examples
==========

_Bouncy GPG_ comes with several [examples](examples) build in.

Key management
-----------------

_Bouncy GPG_ supports [reading `gpg` keyrings](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/keys/keyrings/FileBasedKeyringConfig.java) and [parsing keys exported](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/keys/keyrings/InMemoryKeyring.java) via `gpg --export` and  `gpg --export-secret-key`.

The unit tests have some [examples creating/reading keyrings](src/test/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/testtooling/Configs.java).

The easiest way to manage keyrings is to use the pre-defined [KeyringConfigs](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/keys/keyrings/KeyringConfigs.java).

Encrypt & sign a file and then decrypt it & validate the signature
-------------------

The following snippet encrypts a secret message to `recipient@example.com` (and also self-encrypts it to `sender@example.com`), and signs with `sender@example.com`.

The encrypted message is then decrypted and the signature is verified. (This is from a [documentation test](https://github.com/neuhalje/bouncy-gpg/blob/master/src/test/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/roundtrip/EncryptionDecryptionRoundtripIntegrationTest.java#L496-L556)).

```java

    final String original_message = "I love deadlines. I like the whooshing sound they make as they fly by. Douglas Adams";

    // Most likely you will use  one of the KeyringConfigs.... methods.
    // These are wrappers for the test.
    KeyringConfig keyringConfigOfSender = Configs
        .keyringConfigFromResourceForSender();

    ByteArrayOutputStream result = new ByteArrayOutputStream();

    try (
        BufferedOutputStream bufferedOutputStream = new BufferedOutputStream(result);

        final OutputStream outputStream = BouncyGPG
            .encryptToStream()
            .withConfig(keyringConfigOfSender)
            .withStrongAlgorithms()
            .toRecipients("recipient@example.com", "sender@example.com")
            .andSignWith("sender@example.com")
            .binaryOutput()
            .andWriteTo(bufferedOutputStream);
        // Maybe read a file or a webservice?
        final ByteArrayInputStream is = new ByteArrayInputStream(original_message.getBytes())
    ) {
      Streams.pipeAll(is, outputStream);
    // It is very important that outputStream is closed before the result stream is read.
    // The reason is that GPG writes the signature at the end of the stream.
    // This is triggered by closing the stream.
    // In this example outputStream is closed via the try-with-resources mechanism of Java
    }

    result.close();
    byte[] chipertext = result.toByteArray();

    //////// Now decrypt the stream and check the signature

    // Most likely you will use  one of the KeyringConfigs.... methods.
    // These are wrappers for the test.
    KeyringConfig keyringConfigOfRecipient = Configs
        .keyringConfigFromResourceForRecipient();

    final OutputStream output = new ByteArrayOutputStream();
    try (
        final InputStream cipherTextStream = new ByteArrayInputStream(chipertext);

        final BufferedOutputStream bufferedOut = new BufferedOutputStream(output);

        final InputStream plaintextStream = BouncyGPG
            .decryptAndVerifyStream()
            .withConfig(keyringConfigOfRecipient)
            .andRequireSignatureFromAllKeys("sender@example.com")
            .fromEncryptedInputStream(cipherTextStream)

    ) {
      Streams.pipeAll(plaintextStream, bufferedOut);
    }

    output.close();
    final String decrypted_message = new String(((ByteArrayOutputStream) output).toByteArray());

    assertEquals(original_message, decrypted_message);
```


Performance
--------------

Bouncy castle is often fast enough to _not be the bottleneck_. That said, here are some metrics to give you an indication of the performance:

| Use Case                                        | MBP 2,9 GHz Intel Core i5, Java 1.8.0_111  |  (please add more via PR) |
|:------------------------------------------------|:-------------------------------------------|:--------------------------|
| [Encrypt & sign 1GB random](examples/encrypt)   | ~64s (16 MB/s)                             |                           |
| [Decrypt 1GB random](examples/encrypt)          | ~32s (32 MB/s)                             |                           |

Demos
=========

The directory [examples](examples) contains several examples that show how easy some common use cases are implemented.

[demo_decrypt.sh](examples/decrypt)
-----------------------------------------

Decrypt a file and verify the signature.

* `decrypt.sh  SOURCEFILE DESTFILE`

Uses the testing keys to decrypt a file. Useful for performance measurements and `gpg` interoperability.

[demo_encrypt.sh](examples/encrypt)
-----------------------------------------

Encrypt and sign a file.

* `encrypt.sh  SOURCEFILE DESTFILE`

Uses the testing keys to encrypt a file. Useful for performance measurements and `gpg` interoperability.


[demo_reencrypt.sh](examples/reencrypt)
-----------------------------------------

A GPG encrypted ZIP file is decrypted on the fly. The structure of the ZIP is then written to disk. All files are re-encrypted before saving them.

* `demo_reencrypt.sh TARGET` -- decrypts an encrypted ZIP file containing  three files (total size: 1.2 GB) AND
   re-encrypts each of the files in the ZIP to the `TARGET` dir.

[The sample](examples/reencrypt/src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/example/MainExplodedSinglethreaded.java)
shows how e.g. batch jobs can work with large files without leaving plaintext on disk (together with
[Transparent GPG decryption](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/decrypting/SignatureValidatingInputStream.java)).

This scheme has some very appealing benefits:
* Data in transit is _always_ encrypted with public key cryptography. Indispensable when you have to use `ftp`,
  comforting when you use `https` and the next Heartbleed pops up.
* Data at rest is _always_ encrypted with public key cryptography. When (not if) you get hacked, this can make all the
  difference between _"Move along folks, nothing to see here!"_ and _"I lost confidential customer data to the competition"_.
* You still need to protect the private keys, but this is considerable easier than the alternatives.

Consider the following batch job:

1. The customer sends a large (several GB) GPG encrypted ZIP archive containing a directory structure with several
   data files
2. Your `pre-processing` needs to split up the data for further processing
3. `pre-processing` stream-processes the GPG/ZIP archive
    1. The GPG stream is decrypted using the [BouncyGPG.decryptAndVerifyStream()](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/BouncyGPG.java) `InputStream`
    2. The ZIP file is processed with [ExplodeAndReencrypt](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/reencryption/ExplodeAndReencrypt.java)
        1. Each file from the archive is [processed](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/reencryption/ZipEntityStrategy.java)
        2. And transparently  encrypted with GPG and stored for further processing
4. The `processing` job  [transparently reads](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/decrypting/SignatureValidatingInputStream.java) the files without writing plaintext to the disk.


HOWTO
===========

Have a look at the example classes to see how easy it is to use Bouncy Castle PGP.

#1 Register Bouncy Castle Provider
-------------------------------

Add bouncy castle as a dependency and then install the provider before in your application.

### Add Build Dependency

#### Gradle

```groovy
// build.gradle
// in build.gradle add a dependency to bouncy castle and bouncy-gpg

//...

repositories {
    mavenCentral()
    // jcenter() - optional.
}

//...

//  ...
dependencies {
    compile 'org.bouncycastle:bcprov-jdk15on:1.67'
    compile 'org.bouncycastle:bcpg-jdk15on:1.67'
    //  ...
    compile 'name.neuhalfen.projects.crypto.bouncycastle.openpgp:bouncy-gpg:2.+'
   // ...
  }
```
#### Maven

```xml
    <dependency>
        <groupId>name.neuhalfen.projects.crypto.bouncycastle.openpgp</groupId>
        <artifactId>bouncy-gpg</artifactId>
        <version>2.3.0</version>
    </dependency>
```
 
### Install Provider

```java
    // in one of you classed install the BC provider
    BouncyGPG.registerProvider();
```

#2 Important Classes
-------------------


| Class                         | Use when you want to                                                                |
|:------------------------------|:------------------------------------------------------------------------------------|
| [`BouncyGPG`](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/BouncyGPG.java) | Starting point for the convenient fluent en- and decryption API. |
| [`KeyringConfigs`](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/keys/keyrings/KeyringConfigs.java) | Create default implementations for GPG keyring access. You can also create your own implementations by implementing  [`KeyringConfig`](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/keys/keyrings/KeyringConfig.java). |
| [`KeyringConfigCallbacks`](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/keys/callbacks/KeyringConfigCallbacks.java) | Used by  [`KeyringConfigs`](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/keys/keyrings/KeyringConfigs.java). Create default implementations to provide secret-key passwords.  |
| [`DefaultPGPAlgorithmSuites`](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/algorithms/DefaultPGPAlgorithmSuites.java) |  Select from predefined algorithms suites or create your won with `PGPAlgorithmSuite`. |
| [`ReencryptExplodedZipSinglethread`](src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/reencryption/ReencryptExplodedZipSinglethread.java) | [Work with encrypted ZIPs](examples/reencrypt/src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/example/MainExplodedSinglethreaded.java) |

FAQ
=====

<dl>
  <dt>Why should I use this?</dt>
  <dd>For common use cases this project is easier than vanilla Bouncy Castle. It also has a pretty decent unit test
  coverage. It is free (speech & beer).</dd>

  <dt>Can I just grab a class or two for my project?</dt>
  <dd>Sure! Just grab it and hack away! The code is placed under the <a href="LICENSE">Apache License 2.0</a>, you can't get much
   more permissive than this.</dd>

   <dt>Why is the test coverage so low?</dt>
   <dd>Test coverage for 'non-example' code is &gt;85%. Most of the not tested cases are either trivial OR lines that
   throw exceptions when the input format is broken/handled by bouncycastle directly. </dd>

   <dt>How can I contribute?</dt>
   <dd>Pullrequests are welcome! Please state in your PR that you put your code under the LICENSE.</dd>

   <dt>I am getting 'org.bouncycastle.openpgp.PGPException: checksum mismatch ..' exceptions</dt>
   <dd>The passphrase to your private key is very likely wrong (or you did not pass a passphrase).</dd>

   <dt>I am getting 'java.security.InvalidKeyException: Illegal key size' / 'java.lang.SecurityException: Unsupported keysize or algorithm parameters'</dt>
   <dd>The unrestricted policy files for the JVM are <a href="http://www.bouncycastle.org/wiki/display/JA1/Frequently+Asked+Questions">probably not installed</a>.</dd>

   <dt>I am getting 'java.io.EOFException: premature end of stream in PartialInputStream' while decrypting / Sender can't validate signature</dt>
   <dd>This often happens when encrypting to a 'ByteArrayOutputStream' and the <a href="https://stackoverflow.com/questions/48870074/bouncy-castle-pgp-premature-end-of-stream-in-partialinputstream/49544870#49544870">encryption stream is not propely closed</a>. The reason is that GPG writes the signature at the end of the stream. This is triggered by closing the stream.</dd>

   <dt>Where is 'secring.pgp'?</dt>
   <dd>'secring.gpg' has been <a href="https://gnupg.org/faq/whats-new-in-2.1.html#nosecring">removed in gpg 2.1</a>. Use the other methods to read private keys.</dd>

   <dt>Should I <i>use</i> secring.pgp?</dt>
   <dd>No, you should implement your own key handling strategy. See <a href="#using_sec_pubring">On using (sec|pub)ring.gpg</a> below.

   <dt>Can I generate keys?</dt>
   <dd>Yes, RSA key generation is supported since 2.2.0. Generating ECC keys is NOT supported yet, although the code is there (<a href="https://github.com/neuhalje/bouncy-gpg/blob/master/src/integration-test/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/integration/KeyRingGenerators.java">gpg integration tests</a> fail)</dd>

   <dt>Is compatibility with GnuPG tested?</dt>
   <dd>Yes, since 2.2.0 the gradle task integrationTest  <a href="https://github.com/neuhalje/bouncy-gpg/blob/master/src/integration-test/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/integration/">tests the interoperability with gpg</a>.</dd>
</dl>


## <a name="using_sec_pubring"></a>On using (sec|pub)ring.gpg

*I strongly advise against using `secring.gpg` or `pubring.gpg` for production systems*. These files are an undocumented API of gnupg: usable, but can change or show unexpected results. E.g. with GPG 2.1 the `secring.gpg` file gets no longer updated [and will provide you with stale data](https://gnupg.org/faq/whats-new-in-2.1.html#nosecring) (emphasis by me):

> To ease the migration to the no-secring method, gpg detects the presence of a secring.gpg and converts the keys on-the-fly to the the key store of gpg-agent (this is the private-keys-v1.d directory below the GnuPG home directory (~/.gnupg)). **This is done only once and an existing secring.gpg is then not anymore touched by gpg.** This allows co-existence of older GnuPG versions with GnuPG 2.1. However, any change to the private keys using the new gpg will not show up when using pre-2.1 versions of GnuPG and vice versa.

## Recommendation: InMemoryKeyring

Most applications should manage their keys in an application specific database. Though this might seem more complex than just using the existing keyring files it has a some nice advantages:

* No dependency on the `gpg` executable
* Keys can be managed remotely (e.g. via the applications database)
* Key management is enforced to happen via the application
* Key management for distributed (_scale out_ / _cloud_) systems is much easier when keys are not managed by the operating system

### HOWTO use InMemoryKeyring

To use the  [InMemoryKeyring](https://github.com/neuhalje/bouncy-gpg/blob/master/src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/keys/keyrings/KeyringConfigs.java) you first need to export the keys. Then you put them in your  application data(base).

#### Exporting the keys from gpg

Export the keys  with `gpg` (`gpg --export-secret-key -a user@example.com` and `gpg --export -a user@example.com`):

```text
gpg --export -a user@example.com > user@example.com.pub.gpg
cat user@example.com.pub.gpg

-----BEGIN PGP PUBLIC KEY BLOCK-----
...
-----END PGP PUBLIC KEY BLOCK-----

# You need to input keys passphrase here
gpg --export-secret-key -a user@example.com > user@example.com.secret.gpg
cat user@example.com.secret.gpg

-----BEGIN PGP PRIVATE KEY BLOCK-----
...
-----END PGP PRIVATE KEY BLOCK-----
```

#### Importing the keys

A few examples for using the [InMemoryKeyring](https://github.com/neuhalje/bouncy-gpg/blob/master/src/main/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/keys/keyrings/KeyringConfigs.java)  can be found in the [Test code](https://github.com/neuhalje/bouncy-gpg/blob/master/src/test/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/testtooling/Configs.java).

Here is the short version:

```java
  public static KeyringConfig keyringConfigInMemoryForKeys(final String exportedPubKey, final String exportedPrivateKey, final String passphrase) throws IOException, PGPException {

    final InMemoryKeyring keyring = KeyringConfigs.forGpgExportedKeys(KeyringConfigCallbacks.withPassword(passphrase);

    keyring.addPublicKey(exportedPubKey.getBytes("US-ASCII"));
   // you can add many more public keys

    keyring.addSecretKey(exportedPrivateKey.getBytes("US-ASCII"));
   // you can add many more privvate keys

    return keyring;
  }
```

#### Generating Keys

The most straight forward way is to call  `BouncyGPG::createSimpleKeyring()`:

```java
    final KeyringConfig rsaKeyRing = BouncyGPG.createSimpleKeyring()
        .simpleRsaKeyRing(UID_JULIET, RsaLength.RSA_3072_BIT);

```
Here is a more complex case with dedicated subkeys for signing, encryption, and authentication:
```java
        final KeySpec signingSubey = KeySpecBuilder
                .newSpec(RSAForSigningKeyType.withLength(RsaLength.RSA_2048_BIT))
                .allowKeyToBeUsedTo(KeyFlag.SIGN_DATA)
                .withDefaultAlgorithms();

        final KeySpec authenticationSubey = KeySpecBuilder
                .newSpec(RSAForEncryptionKeyType.withLength(RsaLength.RSA_2048_BIT))
                .allowKeyToBeUsedTo(KeyFlag.AUTHENTICATION)
                .withDefaultAlgorithms();

        final KeySpec encryptionSubey = KeySpecBuilder
                .newSpec(RSAForEncryptionKeyType.withLength(RsaLength.RSA_2048_BIT))
                .allowKeyToBeUsedTo(KeyFlag.ENCRYPT_COMMS, KeyFlag.ENCRYPT_STORAGE)
                .withDefaultAlgorithms();

        final KeySpec masterKey = KeySpecBuilder.newSpec(
                RSAForSigningKeyType.withLength(RsaLength.RSA_3072_BIT)
        )
                .allowKeyToBeUsedTo(KeyFlag.CERTIFY_OTHER)
                .withDetailedConfiguration()
                .withPreferredSymmetricAlgorithms(
                        PGPSymmetricEncryptionAlgorithms.recommendedAlgorithms()
                )
                .withPreferredHashAlgorithms(
                        PGPHashAlgorithms.recommendedAlgorithms()
                )
                .withPreferredCompressionAlgorithms(
                        PGPCompressionAlgorithms.recommendedAlgorithms()
                )
                .withFeature(Feature.MODIFICATION_DETECTION)
                .done();

        final KeyringConfig complexKeyRing = BouncyGPG
                .createKeyring()
                .withSubKey(signingSubey)
                .withSubKey(authenticationSubey)
                .withSubKey(encryptionSubey)
                .withMasterKey(masterKey)
                .withPrimaryUserId(uid)
                .withPassphrase(Passphrase.fromString(passphrase))
                .build();

        return complexKeyRing;
```

##### Persisting generated keys

The bouncy castle functions can be used to persist keys. [ExportGeneratedKeysTest.java](src/test/java/name/neuhalfen/projects/crypto/bouncycastle/openpgp/examples/howto/ExportGeneratedKeysTest.java) shows how to do that.

#### Using the config

```java
final InMemoryKeyring keyring = keyringConfigInMemoryForKeys(...);

final InputStream decryptedPlaintextStream = BouncyGPG
        .decryptAndVerifyStream()
        .withConfig(keyring)
        ....
```

Building
=======

Project uses Maven as a build tool. Run `./mvnw clean install` to build the project.

Use `-DskipITs=true` to skip the integration tests.

Use `-DskipQuality=true` to skip the quality checks.

Publish to GitHub and Maven Central
--------------------

`mvn clean --batch-mode -P default,github -Dpublish=github deploy`

`mvn clean --batch-mode -P default,central -Dpublish=central deploy`

CAVE
=====

* Only one keyring per userid ("sender@example.com") supported.
* Only one signing key per userid supported.
* [TODOs](TODO.md)

## LICENSE

This code is placed under the Apache License 2.0. Don't forget to adhere to the BouncyCastle License (http://bouncycastle.org/license.html).
