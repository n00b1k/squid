#!/bin/sh
set -e

SSL_DIR=/var/lib/squid/ssl
CA_KEY=$SSL_DIR/ca.key
CA_CRT=$SSL_DIR/ca.crt
PROXY_KEY=$SSL_DIR/proxy.key
PROXY_CRT=$SSL_DIR/proxy.crt
PROXY_PEM=$SSL_DIR/proxy.pem

mkdir -p $SSL_DIR
chown squid:squid $SSL_DIR

# Генерация CA, если нет
if [ ! -f "$CA_KEY" ] || [ ! -f "$CA_CRT" ]; then
    echo "Generating CA..."
    openssl genrsa -out $CA_KEY 4096
    openssl req -x509 -new -nodes -key $CA_KEY -sha256 -days 3650 \
        -out $CA_CRT -subj "/C=US/ST=NY/O=fakesoft/CN=fakesoft Root CA"
    chmod 600 $CA_KEY
fi

# Генерация серверного сертификата, если нет
if [ ! -f "$PROXY_PEM" ]; then
    echo "Generating proxy server certificate..."
    openssl genrsa -out $PROXY_KEY 2048
    openssl req -new -key $PROXY_KEY -out $SSL_DIR/proxy.csr \
        -subj "/C=US/ST=NY/O=fakesoft/CN=proxy"

    openssl x509 -req -in $SSL_DIR/proxy.csr -CA $CA_CRT -CAkey $CA_KEY \
        -CAcreateserial -out $PROXY_CRT -days 3650 -sha256

    # Собираем один PEM для Squid
    cat $PROXY_CRT $PROXY_KEY > $PROXY_PEM
    chmod 600 $PROXY_KEY
fi

echo "Starting Squid..."
exec /usr/sbin/squid -f /etc/squid/squid.conf --foreground -YCd 1
