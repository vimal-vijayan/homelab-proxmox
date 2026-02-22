# Kubernetes Homelab Observability

This document defines a practical observability roadmap for this homelab Kubernetes platform.

## Scope

Primary stack (baseline):

- Prometheus for metrics scraping
- Alertmanager for alert routing
- Grafana for dashboards and alert visualization

Planned scale-out stack (advanced):

- Grafana Mimir for long-term/scalable metrics storage
- Azure Blob Storage as Mimir object store backend
- Grafana Loki for logs
- Grafana Tempo for traces
- Grafana Alloy or OpenTelemetry Collector for unified telemetry pipelines

## Architecture

Baseline (today):

```text
Kubernetes cluster -> Prometheus -> Alertmanager
                           |
                           v
                        Grafana
```

Advanced (target):

```text
Kubernetes cluster -> Prometheus --remote_write--> Mimir --> Azure Blob Storage
       |                 |                             |
       |                 +--> Alertmanager             +--> Grafana (PromQL)
       +--> Logs (Loki) / Traces (Tempo) via Alloy or OTel Collector
```

## Metrics Sources

Prometheus should scrape:

- `kube-state-metrics`
- `node-exporter`
- kubelet/cAdvisor metrics
- Kubernetes control plane endpoints (where exposed)
- ingress controller metrics (Traefik)
- GitOps/controller metrics (Flux, cert-manager, etc.)
- application workload metrics

## Core Responsibilities

### Prometheus

- Scrape Kubernetes and workload metrics
- Evaluate recording and alerting rules
- Send alerts to Alertmanager
- Optionally forward metrics via `remote_write` to Mimir

### Alertmanager

- Group and route alerts
- Integrate notification channels (email/Slack/webhook)
- Apply silencing and inhibition policies

### Grafana

- Query Prometheus (baseline) and Mimir (advanced)
- Provide cluster/platform dashboards
- Visualize active alert state

### Grafana Mimir (advanced)

- Receive `remote_write` metrics from Prometheus
- Store blocks in object storage
- Serve scalable long-range PromQL queries

### Azure Blob Storage (advanced)

- Durable object store for Mimir blocks
- Retention backbone for historical metrics

## Deployment Phases

### Phase 1: Baseline Monitoring

- Deploy Prometheus + Alertmanager + Grafana
- Validate target discovery and scrape health
- Import core Kubernetes dashboards
- Create first critical alerts (node down, kubelet down, pod crash loops)

### Phase 2: Harden Baseline

- Add recording rules for expensive queries
- Add alert routing/silences in Alertmanager
- Tune scrape intervals and retention

### Phase 3: Introduce Mimir

- Deploy Grafana Mimir in-cluster (single-tenant)
- Configure object store backend (Azure Blob)
- Configure Prometheus `remote_write`
- Add Mimir data source in Grafana

### Phase 4: Extend to Logs and Traces

- Deploy Loki for logs
- Deploy Tempo for traces
- Add Alloy or OpenTelemetry Collector for unified pipelines
- Correlate metrics, logs, and traces in Grafana

### Phase 5: Multi-Cluster Expansion (Optional)

- Send metrics from additional clusters to shared Mimir
- Standardize dashboards and alerting across environments

## Example Prometheus `remote_write`

```yaml
remote_write:
  - url: http://mimir-nginx.monitoring.svc.cluster.local/api/v1/push
```

## Example Alertmanager Route (Minimal)

```yaml
route:
  receiver: default
  group_by: [alertname, cluster, namespace]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
receivers:
  - name: default
```

## Example Dashboard/Alert Priorities

- Cluster health and node saturation
- Control plane availability
- Pod restart/crash loop trends
- Ingress error rate and latency
- Resource pressure (CPU, memory, disk)
- Certificate expiration windows

## Outcomes

This roadmap delivers:

- Immediate baseline monitoring and alerting
- A clear path to production-style scalable observability
- Long-term metric retention using object storage
- Future-ready integration of logs and traces

## Notes

- The folder is currently named `docs/obervability/` in this repo.
- If you want, we can rename it to `docs/observability/` and update all references in a follow-up change.
