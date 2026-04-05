# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A **Killercoda monorepo** for [devoriales.com](https://devoriales.com) courses. Each top-level directory is a course; each course contains Killercoda scenarios. A single GitHub repo is linked to the Killercoda creator account, so all courses live here.

```
/
├── structure.json          # top-level: lists all courses by directory path
├── gateway-api/            # course: Kubernetes Gateway API (3 scenarios)
│   ├── structure.json      # lists scenarios as "scenario-N-..." (relative to course dir)
│   ├── manifests/          # reference YAML copied to student VM via assets
│   └── scenario-N-name/
└── <future-course>/        # add new courses as sibling directories
```

### Adding a new course

1. Create a directory: `<course-slug>/`
2. Add `<course-slug>/structure.json` listing its scenarios as `"scenario-N-name"` (paths are relative to the course directory, NOT the repo root)
3. Add `{ "path": "<course-slug>" }` to the root `structure.json`

### Gateway API course

Three scenarios forming a learning path:
1. `gateway-api/scenario-1-baseline` — Deploy bookstore + expose via ingress-nginx (beginner, ~20 min)
2. `gateway-api/scenario-2-migration` — Install Gateway API CRDs + Traefik v3, migrate to HTTPRoute, add TLS (intermediate, ~30 min)
3. `gateway-api/scenario-3-advanced` — Canary traffic splitting, header-based routing, decommission ingress-nginx (intermediate, ~20 min)

## Scenario structure

Each scenario directory follows the Killercoda format:

```
scenario-N-name/
  index.json          # scenario metadata: title, steps, backend image, asset mappings
  background.sh       # runs silently before the student arrives; sets up cluster state
  intro.md            # shown on first load
  finish.md           # shown on completion
  stepN/
    text.md           # student-facing instructions (rendered in Killercoda UI)
    verify.sh         # exit-code check Killercoda runs when student clicks "Check"
```

**Asset paths in `index.json` are relative to the scenario directory** (the folder containing `index.json`), not the repo root. Each scenario keeps its own `manifests/` subdirectory that gets copied to `/root/manifests/` on the student VM:
```json
{"file": "manifests/**/*.*", "target": "/root/manifests"}
```

## Background scripts and student state

Each `background.sh` is cumulative — it recreates the final state of all prior scenarios so students can start mid-series:
- **Scenario 1**: cluster ready, bookstore app deployed, Helm + mkcert available
- **Scenario 2**: everything from 1, plus ingress-nginx installed and routing `bookstore.local:30080`
- **Scenario 3**: everything from 2, plus Traefik + Gateway API CRDs installed, `bookstore-tls` secret created, HTTPS Gateway + basic HTTPRoute applied

## Manifests directory

`manifests/` contains reference YAML files that `background.sh` writes to `/root/manifests/` on the student VM via the `assets` key in `index.json`. Students apply these with `kubectl apply -f`. Numbered subdirectories map to lesson progression:

- `02-ingress-nginx/` — classic Ingress
- `03-gateway-api/` — GatewayClass + Gateway (HTTP and HTTPS variants)
- `04-httproutes/` — basic path routing, header-based routing
- `05-advanced/` — canary weighted routing
- `06-traefik-middlewares/` — ExtensionRef for Traefik Middleware attachment

## Port assignments (NodePort)

| Service | NodePort | Protocol |
|---|---|---|
| ingress-nginx HTTP | 30080 | HTTP |
| ingress-nginx HTTPS | 30443 | HTTPS |
| Traefik web | 30090 | HTTP |
| Traefik websecure | 30091 | HTTPS |

Traefik's internal container ports are 8000 (HTTP) and 8443 (HTTPS) — these are what Gateway listeners reference.

## Application

The bookstore app (`ghcr.io/devoriales/bookstore:v1` / `:v2`) runs in the `bookstore` namespace:
- Port: 8000 (container), exposed via Service on port 80
- Health endpoint: `GET /health`
- v2 requires `APP_VERSION=v2` env var to self-identify

## verify.sh conventions

- Use `set -e`
- Exit 0 on success with a brief confirmation message
- Exit 1 with a human-readable hint pointing to the exact `kubectl` command to fix the issue
- Check pod state via `kubectl get pods ... --field-selector=status.phase=Running`
- Check resource existence with `kubectl get <resource> <name> -n <ns> &>/dev/null`

## Key authoring constraints

- `background.sh` must be idempotent (`--dry-run=client | kubectl apply -f -`, `|| true` on helm installs)
- Manifests written inline in `background.sh` (heredocs) must stay in sync with files in `manifests/`
- The Killercoda backend image is `kubernetes-kubeadm-1node` (single-node, Kubernetes v1.30+)
- Gateway API CRDs version pinned at `v1.2.1` (standard-install.yaml)
- Traefik Helm chart from `https://traefik.github.io/charts`, installed with `kubernetesGateway.enabled=true` and `kubernetesIngress.enabled=false`
