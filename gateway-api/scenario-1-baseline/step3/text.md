# Step 3 — Route traffic with an Ingress resource

With ingress-nginx running, you can now create an `Ingress` resource to expose the bookstore at `bookstore.local`.

## Apply the Ingress manifest

```
kubectl apply -f /root/manifests/02-ingress-nginx/bookstore-ingress.yaml
```

This creates:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: bookstore-ingress
  namespace: bookstore
spec:
  ingressClassName: nginx
  rules:
  - host: bookstore.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: bookstore
            port:
              number: 80
```

## Test the route

```
curl -s -H "Host: bookstore.local" http://localhost:30080/health
```

Expected:
```json
{"status": "healthy", "service": "bookstore-api"}
```

Try the books endpoint:

```
curl -s -H "Host: bookstore.local" http://localhost:30080/api/v1/books
```

## What you're seeing — and its limitations

The Ingress works, but notice:
- All routing config lives in **annotations** (e.g., `nginx.ingress.kubernetes.io/...`)
- There's no concept of a **Gateway** that different teams can configure independently
- Adding TLS, rate limiting, or traffic splitting requires controller-specific annotations

The Gateway API solves all of this. Let's install it.

Click **Check** to verify traffic reaches the bookstore through ingress-nginx.
