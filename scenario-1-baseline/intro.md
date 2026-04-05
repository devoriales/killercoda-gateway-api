# Gateway API Lab 1/3 — The Baseline: ingress-nginx

> This scenario is part of the **[Gateway API Learning Lab: From Zero to Hero](https://devoriales.com/quiz/20/gateway-api-learning-lab-from-zero-to-hero)** course on [devoriales.com](https://devoriales.com).
> **Scenarios:** [1 — Baseline](#) · [2 — Migration](https://killercoda.com/devoriales/scenario/gateway-api-lab-2-migration) · [3 — Advanced](https://killercoda.com/devoriales/scenario/gateway-api-lab-3-advanced)

In this first scenario you will install **ingress-nginx** and expose a bookstore REST API using a classic `Ingress` resource. This is the *before* state — the baseline you'll migrate away from in scenarios 2 and 3.

## What you will do

1. Explore the pre-deployed bookstore API
2. Install ingress-nginx via Helm
3. Create an `Ingress` resource and test HTTP routing

## Environment

| What | Detail |
|---|---|
| Cluster | Single-node kubeadm (Kubernetes v1.30+) |
| App namespace | `bookstore` |
| App domain | `bookstore.local` |
| ingress-nginx NodePort | **30080** (HTTP) |

The bookstore app is already deployed. You focus on the routing layer.

**Estimated time:** ~20 minutes
