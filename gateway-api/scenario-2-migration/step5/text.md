# Step 8 — TLS with mkcert

The bookstore is currently reachable over plain HTTP. In this step you'll add HTTPS by:

1. Generating a locally-trusted certificate with **mkcert**
2. Storing it as a Kubernetes TLS Secret
3. Adding an HTTPS listener to the Gateway
4. Updating the HTTPRoute to target the HTTPS listener

## Generate the certificate

`mkcert` is already installed. Generate a certificate that covers both the apex domain and a wildcard:

```
cd /root
mkcert bookstore.local "*.bookstore.local"
```{{exec}}

This creates:
- `bookstore.local+1.pem` — the certificate
- `bookstore.local+1-key.pem` — the private key

## Create the TLS Secret

```
kubectl create secret tls bookstore-tls \
  --cert=/root/bookstore.local+1.pem \
  --key=/root/bookstore.local+1-key.pem \
  -n bookstore
```{{exec}}

Verify it was created:

```
kubectl get secret bookstore-tls -n bookstore
```{{exec}}

## Apply the HTTPS Gateway

```
kubectl apply -f /root/manifests/03-gateway-api/gateway-https.yaml
```{{exec}}

This replaces the HTTP-only Gateway with one that has two listeners:
- `http` on port 8000 (Traefik's internal `web` entryPoint)
- `https` on port 8443 (Traefik's internal `websecure` entryPoint), with `certificateRefs` pointing at `bookstore-tls`

Check both listeners are programmed:

```
kubectl get gateway bookstore-gateway -n bookstore -o jsonpath='{.status.listeners}' | jq .
```{{exec}}

## Update the HTTPRoute to use HTTPS

```
kubectl apply -f /root/manifests/04-httproutes/basic-route.yaml
```{{exec}}

This route targets `sectionName: https`. Because the route name (`bookstore-route`) is the same as the one created in the previous step, `kubectl apply` updates it in-place — no delete needed.

## Test HTTPS

```
curl -s --cacert /root/.local/share/mkcert/rootCA.pem \
  --resolve bookstore.local:30091:127.0.0.1 \
  https://bookstore.local:30091/health
```{{exec}}

Expected:
```json
{"status": "healthy", "service": "bookstore-api"}
```

Click **Check** to verify the TLS Secret exists and the Gateway has two listeners.
