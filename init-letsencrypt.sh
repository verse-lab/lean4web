#!/bin/bash
set -e

DOMAIN="try.veil.dev"
EMAIL="george@pirlea.net"
CERT_PATH="/etc/letsencrypt/live/$DOMAIN"

# Create dummy certificate if none exists (allows nginx to start)
if [ ! -f "$CERT_PATH/fullchain.pem" ]; then
    echo "Creating dummy certificate for nginx startup..."
    mkdir -p "$CERT_PATH"
    openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
        -keyout "$CERT_PATH/privkey.pem" \
        -out "$CERT_PATH/fullchain.pem" \
        -subj "/CN=localhost"
fi

# Wait for nginx to be ready with dummy cert
sleep 10

# Check if we have a real Let's Encrypt cert (not our dummy)
if ! openssl x509 -in "$CERT_PATH/fullchain.pem" -text -noout | grep -q "Let's Encrypt"; then
    echo "Obtaining real certificate from Let's Encrypt..."

    # Delete dummy cert
    rm -rf "$CERT_PATH"

    certbot certonly --webroot \
        --webroot-path=/var/www/certbot \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        -d "$DOMAIN" \
        --non-interactive

    echo "Certificate obtained!"
fi

# Run renewal loop
echo "Starting certificate renewal daemon..."
while :; do
    certbot renew
    sleep 12h
done
