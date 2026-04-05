# Step 7 — Your first HTTPRoute

The Gateway is programmed and listening on port 80. Now create an `HTTPRoute` to connect it to the bookstore Service.

## Create a route for the HTTP listener

The tutorial's `basic-route.yaml` targets the `https` listener (for use after TLS is set up). For this step you'll apply a slightly modified version that targets the `http` listener:

```
cat > /root/bookstore-http-route.yaml <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bookstore-route
  namespace: bookstore
spec:
  parentRefs:
  - name: bookstore-gateway
    namespace: bookstore
    sectionName: http          # targets the HTTP listener from Step 6
  hostnames:
  - bookstore.local
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api/v1
    backendRefs:
    - name: bookstore
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /api/v2
    backendRefs:
    - name: bookstore
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: bookstore
      port: 80
EOF

kubectl apply -f /root/bookstore-http-route.yaml
```

## Verify the route status

```
kubectl get httproute -n bookstore
kubectl describe httproute bookstore-route -n bookstore
```

Look for `ResolvedRefs: True` and `Accepted: True` in the conditions.

## Test traffic through Traefik

```
curl -s -H "Host: bookstore.local" http://localhost:30090/health
curl -s -H "Host: bookstore.local" http://localhost:30090/api/v1/books
```

Both ingress-nginx (port **30080**) and Traefik (port **30090**) are now routing to the same bookstore Service. You can compare them side by side.

## Key differences from Ingress

| | Ingress | HTTPRoute |
|---|---|---|
| Traffic splitting | Annotation hack | Native `weight:` field |
| Header matching | Controller-specific annotations | `matches.headers` field |
| TLS | `spec.tls` + annotations | Gateway listener config |
| Cross-namespace | Not supported | `ReferenceGrant` |

Click **Check** to verify traffic reaches bookstore through Traefik.
