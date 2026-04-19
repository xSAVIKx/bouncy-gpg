#!/usr/bin/env bash
# Usage: ./demo_reencrypt.sh sourceFile.zip.gpg destPath
# NOTE: sourceFile and destPath must not contain spaces
if [ "x$2" = "x" ]; then
  echo "Usage: $0 sourceFile.zip.gpg destPath"
  exit 1
fi
DEST="$2"
mkdir -p "$DEST"
mvn exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient $1 $DEST"
