#!/bin/bash
# Scenario 4 background.sh — everything from scenarios 1-3 PLUS no ingress-nginx
# Students arrive with Traefik routing bookstore.local on :30091 (HTTPS).
# Their task: create Traefik Middleware CRDs and attach them via ExtensionRef.
set -euo pipefail

# --- 1. Wait for cluster ---
until kubectl get nodes 2>/dev/null | grep -q " Ready"; do sleep 3; done

# --- 2. Helm ---
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash -s -- --no-sudo 2>/dev/null

# --- 3. mkcert ---
curl -fsSLo /usr/local/bin/mkcert "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x /usr/local/bin/mkcert
CAROOT=/root/.local/share/mkcert mkcert -install 2>/dev/null || true

# --- 4. Bookstore namespace + app ---
kubectl create namespace bookstore --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bookstore
  namespace: bookstore
  labels:
    app: bookstore
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: bookstore
      version: v1
  template:
    metadata:
      labels:
        app: bookstore
        version: v1
    spec:
      containers:
      - name: bookstore
        image: ghcr.io/devoriales/bookstore:v1
        ports:
        - containerPort: 8000
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: bookstore
  namespace: bookstore
spec:
  selector:
    app: bookstore
    version: v1
  ports:
  - port: 80
    targetPort: 8000
EOF

kubectl wait --for=condition=Ready pods -l app=bookstore -n bookstore --timeout=120s 2>/dev/null || true

# --- 5. /etc/hosts ---
echo "127.0.0.1 bookstore.local" >> /etc/hosts

# --- 6. Gateway API CRDs (scenario 2 outcome) ---
kubectl apply --server-side \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml \
  2>/dev/null || true

# --- 7. Traefik with kubernetesGateway provider (scenario 2 outcome, no ingress-nginx) ---
helm repo add traefik https://traefik.github.io/charts 2>/dev/null || true
helm repo update 2>/dev/null || true

cat > /tmp/traefik-values.yaml <<'HELMEOF'
providers:
  kubernetesIngress:
    enabled: false
  kubernetesGateway:
    enabled: true
gatewayClass:
  enabled: false
gateway:
  enabled: false
service:
  type: NodePort
ports:
  web:
    port: 8000
    exposedPort: 80
    nodePort: 30090
  websecure:
    port: 8443
    exposedPort: 443
    nodePort: 30091
HELMEOF

helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  -f /tmp/traefik-values.yaml \
  --wait --timeout=120s 2>/dev/null || true

# --- 8. GatewayClass ---
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: traefik
spec:
  controllerName: traefik.io/gateway-controller
EOF

# --- 9. TLS secret ---
cd /root
mkcert bookstore.local "*.bookstore.local" 2>/dev/null || true

kubectl create secret tls bookstore-tls \
  --cert=/root/bookstore.local+1.pem \
  --key=/root/bookstore.local+1-key.pem \
  -n bookstore \
  --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# --- 10. Gateway with HTTP + HTTPS listeners (scenario 2 outcome) ---
kubectl apply -f - <<'EOF'
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
    port: 8000
    allowedRoutes:
      namespaces:
        from: Same
  - name: https
    protocol: HTTPS
    port: 8443
    tls:
      mode: Terminate
      certificateRefs:
      - name: bookstore-tls
    allowedRoutes:
      namespaces:
        from: Same
EOF

# Wait for gateway to be programmed
sleep 10

# --- 11. Basic HTTPRoute (starting point for this scenario) ---
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bookstore-route
  namespace: bookstore
spec:
  parentRefs:
  - name: bookstore-gateway
    namespace: bookstore
    sectionName: https
  hostnames:
  - bookstore.local
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api
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

# --- 12. Write middleware manifests to /root/manifests ---
mkdir -p /root/manifests/06-traefik-middlewares

cat > /root/manifests/06-traefik-middlewares/rate-limit.yaml <<'YAML'
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: rate-limit
  namespace: bookstore
spec:
  rateLimit:
    average: 10
    burst: 20
YAML

cat > /root/manifests/06-traefik-middlewares/security-headers.yaml <<'YAML'
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: security-headers
  namespace: bookstore
spec:
  headers:
    customResponseHeaders:
      X-Frame-Options: "DENY"
      X-Content-Type-Options: "nosniff"
      Referrer-Policy: "strict-origin-when-cross-origin"
      Content-Security-Policy: "default-src 'self'"
YAML

cat > /root/manifests/06-traefik-middlewares/httproute-with-middleware.yaml <<'YAML'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bookstore-with-middleware
  namespace: bookstore
spec:
  parentRefs:
  - name: bookstore-gateway
    namespace: bookstore
    sectionName: https
  hostnames:
  - bookstore.local
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api
    filters:
    - type: ExtensionRef
      extensionRef:
        group: traefik.io
        kind: Middleware
        name: rate-limit
    - type: ExtensionRef
      extensionRef:
        group: traefik.io
        kind: Middleware
        name: security-headers
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
YAML

echo "[setup] Scenario 4 background complete. Traefik routing bookstore.local on :30091 (HTTPS)."
