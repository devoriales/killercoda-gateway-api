#!/bin/bash
# Verify: TLS secret exists and Gateway has an HTTPS listener
set -e

# Check TLS secret
if ! kubectl get secret bookstore-tls -n bookstore &>/dev/null; then
  echo "TLS Secret 'bookstore-tls' not found in namespace 'bookstore'."
  echo "Run: kubectl create secret tls bookstore-tls --cert=... --key=... -n bookstore"
  exit 1
fi

# Check Gateway has the https listener
LISTENERS=$(kubectl get gateway bookstore-gateway -n bookstore \
  -o jsonpath='{.spec.listeners[*].name}' 2>/dev/null)

if [[ "$LISTENERS" != *"https"* ]]; then
  echo "Gateway 'bookstore-gateway' does not have an 'https' listener yet."
  echo "Run: kubectl apply -f /root/manifests/03-gateway-api/gateway-https.yaml"
  exit 1
fi

# Test HTTPS connectivity
CACERT="/root/.local/share/mkcert/rootCA.pem"
if [ -f "$CACERT" ]; then
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    --cacert "$CACERT" \
    --resolve "bookstore.local:30091:127.0.0.1" \
    https://bookstore.local:30091/health 2>/dev/null || echo "000")

  if [ "$HTTP_CODE" != "200" ]; then
    echo "HTTPS test returned $HTTP_CODE (expected 200). TLS may not be fully programmed yet."
    echo "Wait a moment and try: curl --cacert $CACERT --resolve bookstore.local:30091:127.0.0.1 https://bookstore.local:30091/health"
    exit 1
  fi
  echo "HTTPS is working (HTTP $HTTP_CODE)."
else
  echo "TLS secret and HTTPS listener present (mkcert CA not found for curl test, skipping live check)."
fi

exit 0
