# Scenario 2 complete — The Migration

You've installed the Gateway API CRDs and Traefik v3, and you now have both controllers running side by side:

- **ingress-nginx** on port 30080 — the old route
- **Traefik** on port 30091 (HTTPS) — the new route

The bookstore is reachable through both. TLS is terminated at the Gateway listener using a mkcert certificate — no per-Ingress TLS blocks needed.

## What you built

```
GatewayClass  traefik
     │
Gateway       bookstore-gateway   (http :80, https :443)
     │
HTTPRoute     bookstore-route  ──▶  Service/bookstore
```

## Next: advanced routing and cutover

Continue to **Scenario 3** to implement canary deployments and header-based routing, then remove ingress-nginx to complete the migration.

**[→ Open Scenario 3: Advanced Routing and Cutover](https://killercoda.com/devoriales/scenario/gateway-api-lab-3-advanced)**

---

Want to test your understanding first? Take the quiz for this section:
**[Gateway API Learning Lab: From Zero to Hero](https://devoriales.com/quiz/20/gateway-api-learning-lab-from-zero-to-hero)**
