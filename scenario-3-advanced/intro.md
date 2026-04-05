# Gateway API Lab 3/3 — Advanced Routing and Cutover

> This scenario is part of the **[Gateway API Learning Lab: From Zero to Hero](https://devoriales.com/quiz/20/gateway-api-learning-lab-from-zero-to-hero)** course on [devoriales.com](https://devoriales.com).
> **Scenarios:** [1 — Baseline](https://killercoda.com/devoriales/scenario/gateway-api-lab-1-baseline) · [2 — Migration](https://killercoda.com/devoriales/scenario/gateway-api-lab-2-migration) · [3 — Advanced](#)

In this final scenario you will use two advanced Gateway API features that would require controller-specific hacks with classic Ingress: **canary deployments** via traffic splitting and **header-based routing**. Then you'll complete the migration by decommissioning ingress-nginx entirely.

## What's already set up

- Bookstore v1 and v2 deployed in namespace `bookstore`
- Traefik v3 running on NodePort **30090** (HTTP) / **30091** (HTTPS)
- `GatewayClass`, `Gateway` with HTTP + HTTPS listeners
- TLS terminated with a mkcert certificate
- A working `HTTPRoute` routing all traffic to bookstore v1

## What you will do

1. Apply a canary `HTTPRoute` — 90% v1, 10% v2 — using the `weight:` field
2. Add header-based routing to direct `X-API-Version: v2` requests to v2
3. Remove ingress-nginx and verify the full migration

**Estimated time:** ~20 minutes

> **Before starting Step 1** — the background setup (Traefik, Gateway API CRDs, TLS) takes 3-5 minutes. Step 1 includes a one-liner to wait for readiness before you proceed.
