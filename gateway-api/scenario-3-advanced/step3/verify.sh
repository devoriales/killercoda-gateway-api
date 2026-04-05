#!/bin/bash
# Verify: ingress-nginx is removed and Traefik still routes all endpoints
set -e

# Check ingress-nginx namespace is gone
if kubectl get namespace ingress-nginx &>/dev/null; then
  echo "Namespace 'ingress-nginx' still exists. Run:"
  echo "  helm uninstall ingress-nginx -n ingress-nginx"
  echo "  kubectl delete namespace ingress-nginx"
  exit 1
fi

# Check all key endpoints via Traefik
CACERT="/root/.local/share/mkcert/rootCA.pem"
ENDPOINTS=("/health" "/api/v1/books" "/api/v2/books")
FAILED=0

for ep in "${ENDPOINTS[@]}"; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    --cacert "$CACERT" \
    --resolve "bookstore.local:30091:127.0.0.1" \
    "https://bookstore.local:30091${ep}" 2>/dev/null || echo "000")

  if [ "$CODE" != "200" ]; then
    echo "FAIL  $ep  (HTTP $CODE)"
    FAILED=$((FAILED + 1))
  else
    echo "OK    $ep  (HTTP $CODE)"
  fi
done

if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "$FAILED endpoint(s) failed. Check HTTPRoutes:"
  echo "  kubectl get httproute -n bookstore"
  exit 1
fi

echo ""
echo "Migration complete! ingress-nginx removed, all endpoints healthy via Traefik."
exit 0
