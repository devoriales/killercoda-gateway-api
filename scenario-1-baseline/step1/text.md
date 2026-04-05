# Step 1 — Explore the environment

The Kubernetes cluster is up and the bookstore API is already deployed. Before installing anything, take a moment to understand what's running.

## Check the cluster

```
kubectl get nodes
```

You should see a single node in `Ready` state.

## Inspect the bookstore namespace

```
kubectl get all -n bookstore
```

You'll see:
- **Deployment** `bookstore` (v1) — 2 replicas
- **Deployment** `bookstore-v2` — 1 replica (used later for canary routing)
- **Service** `bookstore` and `bookstore-v2` — ClusterIP on port 80

## Reach the app directly

The app is running but not yet exposed outside the cluster. Let's hit it through a pod directly to confirm it works:

```
POD=$(kubectl get pod -n bookstore -l app=bookstore,version=v1 -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n bookstore $POD -- curl -s http://localhost:8000/health
```

Expected output:
```json
{"status": "healthy", "service": "bookstore-api"}
```

## Explore the API

```
kubectl exec -n bookstore $POD -- curl -s http://localhost:8000/api/v1/books
```

You'll get a JSON list of books. This is what you'll route externally via ingress-nginx and later via the Gateway API.

## Note on exposed ports

Throughout this scenario two NodePorts are used:

| Controller | HTTP port | HTTPS port |
|---|---|---|
| ingress-nginx | **30080** | 30443 |
| Traefik | **30090** | **30091** |

KillerCoda's **Traffic** tab can proxy to these ports so you can test from your browser.

Click **Check** to verify the bookstore pods are running.
