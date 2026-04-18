#!/usr/bin/env bash
# Usage: ./demo_decrypt.sh sourceFile.gpg destFile
# NOTE: sourceFile and destFile paths must not contain spaces
if [ "x$2" = "x" ]; then
  echo "Usage: $0 sourceFile.gpg destFile"
  exit 1
fi
mvn exec:java -Dexec.args="src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient $1 $2"
