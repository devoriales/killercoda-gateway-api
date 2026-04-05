# Step 1 — Canary deployment with traffic splitting

One of the most compelling reasons to adopt the Gateway API is **native traffic splitting**. With ingress-nginx you'd need the `canary` annotation pattern with a duplicate Ingress resource. With the Gateway API it's a single `weight:` field.

## Wait for the environment to be ready

The background setup (Traefik, Gateway API CRDs, TLS) can take a few minutes. Run this before doing anything else — it will wait silently and print `Ready!` when everything is in place:

```
until kubectl get crd httproutes.gateway.networking.k8s.io &>/dev/null && \
      kubectl get gateway bookstore-gateway -n bookstore &>/dev/null && \
      kubectl get pods -n traefik --field-selector=status.phase=Running --no-headers 2>/dev/null | grep -q traefik; do
  echo "Waiting for environment..."; sleep 5
done
echo "Ready!"
```

## Check what's running

```
kubectl get httproute -n bookstore
kubectl get pods -n bookstore
```

You have `bookstore` (v1, 2 replicas) and `bookstore-v2` (1 replica) both running.

## Apply the canary route

```
kubectl apply -f /root/manifests/05-advanced/canary-route.yaml
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

## Remove the existing route

The background pre-installed a basic HTTPRoute (`bookstore-route`) that sends all traffic to v1. Delete it before testing — if both routes exist Traefik picks one and the split won't work:

```
kubectl delete httproute bookstore-route -n bookstore 2>/dev/null || true
```

## Test the split

Send 50 requests and observe the distribution:

```
CACERT=/root/.local/share/mkcert/rootCA.pem
for i in $(seq 1 50); do
  curl -s --cacert $CACERT \
    --resolve bookstore.local:30091:127.0.0.1 \
    https://bookstore.local:30091/ | grep -o '"version":"[^"]*"'
done | sort | uniq -c
```

You should see roughly 45 hits on v1 and 5 on v2. Traefik uses probabilistic weighted routing — with only 20 requests there's a ~12% chance of seeing zero v2 hits, so 50 requests gives a reliable demonstration.

Click **Check** to verify the canary route is in place.
