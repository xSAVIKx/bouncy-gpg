#!/usr/bin/env bash
# Usage: ./demo_encrypt.sh sourceFile destFile
if [ "x$2" = "x" ]; then
  echo "Usage: $0 sourceFile destFile"
  exit 1
fi
# NOTE: sourceFile and destFile paths must not contain spaces
mvn exec:java -Dexec.args="recipient@example.com recipient@example.com src/test/resources/keys/recipient.gpg.d/pubring.gpg src/test/resources/keys/recipient.gpg.d/secring.gpg recipient $1 $2"
