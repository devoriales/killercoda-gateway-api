# Step 10 — Complete the migration

Everything is routing through Traefik and the Gateway API. The last step is to decommission ingress-nginx and verify nothing breaks.

## Remove the Ingress resource

First delete the legacy Ingress object from the bookstore namespace:

```
kubectl delete ingress bookstore-ingress -n bookstore
```

## Uninstall ingress-nginx

```
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx
```

## Verify ingress-nginx is gone

```
kubectl get ns ingress-nginx
```

Expected: `Error from server (NotFound)` — the namespace is deleted.

## Confirm Traefik still routes everything

Run the full endpoint test against the Traefik port:

```
for endpoint in /health /api/v1/books /api/v2/books /admin; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    --cacert /root/.local/share/mkcert/rootCA.pem \
    --resolve bookstore.local:30091:127.0.0.1 \
    https://bookstore.local:30091${endpoint})
  echo "$CODE  $endpoint"
done
```

All endpoints should return **200**.

## What you've achieved

```
BEFORE                         AFTER
──────────────────────────     ──────────────────────────────────
ingress-nginx controller        Traefik v3 (Gateway API provider)
Ingress resource                GatewayClass + Gateway + HTTPRoute
Annotation-based config         Declarative API resources
No native traffic split         weight: field in HTTPRoute
```

## Clean up (optional)

To remove everything and start fresh:

```
kubectl delete httproute --all -n bookstore
kubectl delete gateway bookstore-gateway -n bookstore
kubectl delete gatewayclass traefik
helm uninstall traefik -n traefik
kubectl delete namespace traefik bookstore
```

Click **Check** to complete the scenario.
