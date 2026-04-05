# Scenario 1 complete — The Baseline

You've installed ingress-nginx and routed the bookstore API using a classic `Ingress` resource. Notice what you had to work with:

- A single `Ingress` object with an `ingressClassName` field
- No separation between "infrastructure config" (ports, TLS) and "routing config"
- Any advanced behaviour (traffic splitting, header routing) would need controller-specific annotations

## Next: migrate to the Gateway API

Continue to **Scenario 2** to install the Gateway API CRDs and Traefik v3 alongside ingress-nginx, and create your first `HTTPRoute`.

**[→ Open Scenario 2: The Migration](https://killercoda.com/devoriales/scenario/gateway-api-lab-2-migration)**

---

Want to test your understanding first? Take the quiz for this section:
**[Gateway API Learning Lab: From Zero to Hero](https://devoriales.com/quiz/20/gateway-api-learning-lab-from-zero-to-hero)**
