#!/bin/bash
# Scenario 2 background.sh — everything from scenario 1 PLUS ingress-nginx pre-installed
# Students arrive with ingress-nginx already routing bookstore.local on port 30080.
# They install the Gateway API stack themselves.
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
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bookstore-v2
  namespace: bookstore
  labels:
    app: bookstore
    version: v2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bookstore
      version: v2
  template:
    metadata:
      labels:
        app: bookstore
        version: v2
    spec:
      containers:
      - name: bookstore
        image: ghcr.io/devoriales/bookstore:v2
        env:
        - name: APP_VERSION
          value: "v2"
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
  name: bookstore-v2
  namespace: bookstore
spec:
  selector:
    app: bookstore
    version: v2
  ports:
  - port: 80
    targetPort: 8000
EOF

kubectl wait --for=condition=Ready pods -l app=bookstore -n bookstore --timeout=120s 2>/dev/null || true

# --- 5. /etc/hosts ---
echo "127.0.0.1 bookstore.local api.bookstore.local admin.bookstore.local" >> /etc/hosts

# --- 6. Write manifests to /root/manifests ---
mkdir -p /root/manifests/02-ingress-nginx \
         /root/manifests/03-gateway-api \
         /root/manifests/04-httproutes \
         /root/manifests/05-advanced \
         /root/manifests/06-traefik-middlewares

cat > /root/manifests/02-ingress-nginx/bookstore-ingress.yaml <<'YAML'
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
YAML

cat > /root/manifests/03-gateway-api/gatewayclass.yaml <<'YAML'
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: traefik
spec:
  controllerName: traefik.io/gateway-controller
YAML

cat > /root/manifests/03-gateway-api/gateway-http.yaml <<'YAML'
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
YAML

cat > /root/manifests/03-gateway-api/gateway-https.yaml <<'YAML'
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
YAML

cat > /root/manifests/04-httproutes/basic-route.yaml <<'YAML'
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
        value: /api/v1
    backendRefs:
    - name: bookstore
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /api/v2
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

cat > /root/manifests/04-httproutes/header-based-route.yaml <<'YAML'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bookstore-header-route
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
      headers:
      - name: X-Api-Version
        value: v2
    backendRefs:
    - name: bookstore-v2
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /api
    backendRefs:
    - name: bookstore
      port: 80
YAML

cat > /root/manifests/05-advanced/canary-route.yaml <<'YAML'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bookstore-canary
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
        value: /
    backendRefs:
    - name: bookstore
      port: 80
      weight: 90
    - name: bookstore-v2
      port: 80
      weight: 10
YAML

# --- 7. Install ingress-nginx (scenario 1 outcome) ---
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm repo update 2>/dev/null || true

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443 \
  --wait --timeout=120s 2>/dev/null || true

# --- 8. Apply the bookstore Ingress (scenario 1 outcome) ---
kubectl apply -f /root/manifests/02-ingress-nginx/bookstore-ingress.yaml 2>/dev/null || true

echo "[setup] Scenario 2 background complete. ingress-nginx routing bookstore.local on :30080."
