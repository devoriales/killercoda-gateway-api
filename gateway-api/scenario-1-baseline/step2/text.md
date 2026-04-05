# Step 2 — Install ingress-nginx

Before migrating to the Gateway API, you'll install **ingress-nginx** — the controller the bookstore is currently designed to use. This gives you the "before" state to compare against.

## Add the Helm repo

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

## Install the controller

In KillerCoda there is no cloud load balancer, so you'll use `NodePort` and fix the ports so they're predictable:

```
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443
```

This maps:
- Port **30080** → ingress-nginx HTTP
- Port **30443** → ingress-nginx HTTPS

## Wait for the controller to be ready

```
kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx
```

## Confirm the IngressClass exists

```
kubectl get ingressclass
```

You should see `nginx` listed. This is the class name your Ingress resources will reference.

Click **Check** to verify ingress-nginx is running.
