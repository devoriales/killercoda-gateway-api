# Gateway API Lab 2/3 — The Migration: Traefik + Gateway API

> This scenario is part of the **[Gateway API Learning Lab: From Zero to Hero](https://devoriales.com/quiz/20/gateway-api-learning-lab-from-zero-to-hero)** course on [devoriales.com](https://devoriales.com).
> **Scenarios:** [1 — Baseline](https://killercoda.com/devoriales/scenario/gateway-api-lab-1-baseline) · [2 — Migration](#) · [3 — Advanced](https://killercoda.com/devoriales/scenario/gateway-api-lab-3-advanced)

In this scenario you will install the **Kubernetes Gateway API CRDs** and **Traefik v3**, then create the three core resources — `GatewayClass`, `Gateway`, and `HTTPRoute` — to route traffic to the bookstore. You'll also add HTTPS termination using **mkcert**.

## What's already set up

- Kubernetes cluster (single-node kubeadm)
- Bookstore app deployed in namespace `bookstore`
- ingress-nginx installed on NodePort **30080** — the baseline from scenario 1

## What you will do

1. Install Gateway API CRDs (standard channel v1.2.1)
2. Install Traefik v3 with `kubernetesGateway` provider enabled
3. Create `GatewayClass` and `Gateway`
4. Create your first `HTTPRoute`
5. Add TLS with mkcert — HTTPS on NodePort **30091**

## Environment

| What | Detail |
|---|---|
| ingress-nginx port | NodePort **30080** (HTTP) — already running |
| Traefik port | NodePort **30090** (HTTP), **30091** (HTTPS) — you install this |

Both controllers will run side by side so you can compare routing behaviour.

**Estimated time:** ~30 minutes
