#!/bin/bash
# Verify: bookstore pods are running in the bookstore namespace
set -e

RUNNING=$(kubectl get pods -n bookstore -l app=bookstore --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)

if [ "$RUNNING" -lt 1 ]; then
  echo "No running bookstore pods found in namespace 'bookstore'."
  echo "Run: kubectl get pods -n bookstore"
  exit 1
fi

echo "bookstore pods running: $RUNNING"
exit 0
