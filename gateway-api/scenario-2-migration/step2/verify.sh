#!/bin/bash
# Verify: Traefik pod is Running in the traefik namespace
set -e

RUNNING=$(kubectl get pods -n traefik -l app.kubernetes.io/name=traefik \
  --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)

if [ "$RUNNING" -lt 1 ]; then
  echo "Traefik pod is not running yet."
  echo "Run: kubectl get pods -n traefik"
  exit 1
fi

# Verify the kubernetesGateway provider is configured (check deployment args or env)
# A lighter check: confirm NodePort 30090 is assigned to the service
NODEPORT=$(kubectl get svc traefik -n traefik \
  -o jsonpath='{.spec.ports[?(@.name=="web")].nodePort}' 2>/dev/null)

if [ "$NODEPORT" != "30090" ]; then
  echo "Expected Traefik NodePort 30090 for web, got: $NODEPORT"
  echo "Check your traefik-values.yaml and reinstall."
  exit 1
fi

echo "Traefik is running and exposed on NodePort 30090."
exit 0
