# Step 5 — Install Traefik with Gateway API provider

Traefik v3 supports the Gateway API natively, but you must **explicitly enable** the `kubernetesGateway` provider — it's off by default.

## Create the Helm values file

```
cat > /root/traefik-values.yaml <<'EOF'
providers:
  kubernetesIngress:
    enabled: false        # Disable the classic Ingress provider
  kubernetesGateway:
    enabled: true         # Enable the Gateway API provider

# Do not auto-create GatewayClass or Gateway — you'll create them manually
gatewayClass:
  enabled: false
gateway:
  enabled: false

# Use NodePort so KillerCoda can expose the ports
service:
  type: NodePort

ports:
  web:
    port: 8000
    exposedPort: 80
    nodePort: 30090       # HTTP traffic tab port
  websecure:
    port: 8443
    exposedPort: 443
    nodePort: 30091       # HTTPS traffic tab port
EOF
```

## Add the Traefik Helm repo and install

```
helm repo add traefik https://traefik.github.io/charts
helm repo update

helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  -f /root/traefik-values.yaml
```

## Wait for Traefik to be ready

```
kubectl rollout status deployment traefik -n traefik
```

## Confirm Traefik is listening

```
kubectl get pods -n traefik
kubectl get svc -n traefik
```

The service should show NodePorts **30090** and **30091**.

> **Why disable kubernetesIngress?**
> This prevents Traefik from picking up the `bookstore-ingress` Ingress resource you created in Step 3. Both ingress-nginx and Traefik would otherwise compete for the same Ingress objects.

Click **Check** to verify Traefik is running.
