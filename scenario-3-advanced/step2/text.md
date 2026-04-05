# Step 2 — Header-based routing

With a classic Ingress and ingress-nginx, header-based routing requires the `canary-by-header` annotation plus a second duplicate Ingress object pointing at the v2 Service. With the Gateway API it's a `matches.headers` block in one `HTTPRoute`.

## Apply the header-based route

```
kubectl apply -f /root/tutorial/manifests/04-httproutes/header-based-route.yaml
```

The route adds a rule that fires when the request carries `X-API-Version: v2`:

```yaml
rules:
- matches:
  - headers:
    - name: X-API-Version
      value: v2
  backendRefs:
  - name: bookstore-v2
    port: 80
- matches:
  - path:
      type: PathPrefix
      value: /
  backendRefs:
  - name: bookstore
    port: 80
    weight: 90
  - name: bookstore-v2
    port: 80
    weight: 10
```

Rules are evaluated top-to-bottom. The header match fires first; everything else falls through to the canary split.

## Test it

```
CACERT=/root/.local/share/mkcert/rootCA.pem

# No header → canary split (mostly v1)
curl -s --cacert $CACERT \
  --resolve bookstore.local:30091:127.0.0.1 \
  https://bookstore.local:30091/api/v2/books | jq '.version // "v1"'

# With header → always v2
curl -s --cacert $CACERT \
  --resolve bookstore.local:30091:127.0.0.1 \
  -H "X-API-Version: v2" \
  https://bookstore.local:30091/api/v2/books | jq '.version // "v2"'
```

The second request should consistently return v2 response structure.

> **Why this matters:** this pattern lets you route internal QA traffic (with the header) to a new version while production traffic still sees the canary split — all in one manifest, no duplicates.

Click **Check** to verify the header-based route is applied.
