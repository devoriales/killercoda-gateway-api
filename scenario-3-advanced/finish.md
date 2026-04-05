# Migration complete!

You've finished all three scenarios. Here's what the full journey looked like:

```
Scenario 1  ingress-nginx installed, Ingress resource routing bookstore.local
Scenario 2  Gateway API CRDs + Traefik, GatewayClass, Gateway, HTTPRoute, TLS
Scenario 3  Canary routing, header-based routing, ingress-nginx decommissioned
```

## Key takeaways

- **GatewayClass** — cluster-scoped, identifies the controller (Traefik)
- **Gateway** — declares listeners (ports, protocols, TLS certs) — owned by platform team
- **HTTPRoute** — routes requests to backends — owned by app team
- **Traffic splitting** is a first-class Gateway API feature via `weight:` — no annotations
- **Header-based routing** uses `matches.headers` — no duplicate Ingress objects

## Continue learning

- Complete the full course and quizzes: **[Gateway API Learning Lab: From Zero to Hero](https://devoriales.com/quiz/20/gateway-api-learning-lab-from-zero-to-hero)**
- Try the advanced manifests in `/root/manifests/06-traefik-middlewares/`
- Explore cross-namespace routing with `ReferenceGrant` in `manifests/07-cross-namespace/`
- Review production-readiness patterns in `manifests/08-production/`
