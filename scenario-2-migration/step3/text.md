# Step 6 — Create GatewayClass and Gateway

Now that Traefik is running with the Gateway API provider enabled, you need two resources before you can route traffic:

1. **GatewayClass** — tells Traefik "this cluster uses you as the Gateway controller"
2. **Gateway** — declares what ports and protocols to listen on

## Create the GatewayClass

```
kubectl apply -f /root/manifests/03-gateway-api/gatewayclass.yaml
```

The manifest:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: traefik
spec:
  controllerName: traefik.io/gateway-controller
```

The `controllerName` must exactly match what Traefik watches for. Check the status:

```
kubectl get gatewayclass traefik
```

Look for `ACCEPTED: True` in the output. Traefik sets this once it recognises the class.

## Create the Gateway (HTTP listener only)

```
kubectl apply -f /root/manifests/03-gateway-api/gateway-http.yaml
```

The manifest:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: bookstore-gateway
  namespace: bookstore
spec:
  gatewayClassName: traefik
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: Same
```

Check the Gateway status:

```
kubectl get gateway -n bookstore
kubectl describe gateway bookstore-gateway -n bookstore
```

Look for the condition `Programmed: True` — this means Traefik has configured the listener.

## How this differs from Ingress

With Ingress you have a controller + an Ingress resource — no intermediary "Gateway" concept. Here:

- The **GatewayClass** is the cluster-level declaration of which controller to use
- The **Gateway** is an explicit declaration of infrastructure (ports, TLS, allowed namespaces)
- This separation lets platform teams control the Gateway while app teams manage their own routes

Click **Check** to verify the GatewayClass is accepted and Gateway is programmed.
