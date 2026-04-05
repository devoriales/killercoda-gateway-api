# Step 4 — Install Gateway API CRDs

The Gateway API is not built into Kubernetes — it ships as a set of **CRDs** that you install separately. There are two channels:

| Channel | Maturity | Use |
|---|---|---|
| **Standard** | GA / stable | Production use (GatewayClass, Gateway, HTTPRoute) |
| Experimental | Alpha/Beta | Newer features (TCPRoute, GRPCRoute experimental fields) |

You'll install the **standard channel** — all features used in this tutorial are stable.

## Install the CRDs

```
kubectl apply --server-side \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
```

The `--server-side` flag is required because the Gateway API CRD manifests exceed the annotation size limit for client-side apply.

## Verify the CRDs are installed

```
kubectl get crd | grep gateway.networking.k8s.io
```

You should see:

```
gatewayclasses.gateway.networking.k8s.io
gateways.gateway.networking.k8s.io
grpcroutes.gateway.networking.k8s.io
httproutes.gateway.networking.k8s.io
referencegrants.gateway.networking.k8s.io
```

## What each resource does

- **GatewayClass** — cluster-scoped, names a controller (e.g., Traefik)
- **Gateway** — declares listeners: port, protocol, TLS cert
- **HTTPRoute** — attaches to a Gateway listener and routes traffic to Services
- **ReferenceGrant** — allows cross-namespace references (used later)

Click **Check** to confirm the HTTPRoute CRD is installed.
