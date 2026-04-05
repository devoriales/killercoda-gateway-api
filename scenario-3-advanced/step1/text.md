# Step 1 — Canary deployment with traffic splitting

One of the most compelling reasons to adopt the Gateway API is **native traffic splitting**. With ingress-nginx you'd need the `canary` annotation pattern with a duplicate Ingress resource. With the Gateway API it's a single `weight:` field.

## Check what's running

```
kubectl get httproute -n bookstore
kubectl get pods -n bookstore
```

You have `bookstore` (v1, 2 replicas) and `bookstore-v2` (1 replica) both running.

## Apply the canary route

```
kubectl apply -f /root/tutorial/manifests/05-advanced/canary-route.yaml
```

The key part of the manifest:

```yaml
rules:
- matches:
  - path:
      type: PathPrefix
      value: /
  backendRefs:
  - name: bookstore      # v1 — 90%
    port: 80
    weight: 90
  - name: bookstore-v2   # v2 — 10%
    port: 80
    weight: 10
```

Weights are relative: `90 / (90 + 10) = 90%`. No annotations, no duplicate resources.

## Test the split

Send 20 requests and observe the distribution:

```
CACERT=/root/.local/share/mkcert/rootCA.pem
for i in $(seq 1 20); do
  curl -s --cacert $CACERT \
    --resolve bookstore.local:30091:127.0.0.1 \
    https://bookstore.local:30091/ | grep -o '"version":"[^"]*"'
done | sort | uniq -c
```

You should see roughly 18 hits on v1 and 2 on v2. The exact split varies — Traefik distributes at the connection level, not per-request.

## Delete the old basic route to avoid conflict

```
kubectl delete httproute bookstore-route -n bookstore 2>/dev/null || true
```

Click **Check** to verify the canary route is in place.
