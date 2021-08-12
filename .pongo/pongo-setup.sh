#!/bin/sh

NAME=testcert;

if [ ! -f /kong-plugin/$NAME.pem ] && [ ! -f /kong-plugin/$NAME-private.pem ]; then
  echo "Generating test certificates..."
  openssl genrsa -out $NAME-private.pem 2048
  openssl rsa -in $NAME-private.pem -outform PEM -pubout -out $NAME.pem
fi

# install rockspec, dependencies only
find /kong-plugin -maxdepth 1 -type f -name '*.rockspec' -exec luarocks install --only-deps {} \;
