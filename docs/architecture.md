# System Architecture

The project follows a "GitOps-lite" approach using a `Makefile` to orchestrate three distinct layers:

1.  **Infrastructure Layer (`infra/`)**: Managed by Terraform. Provisions the Kubernetes cluster and exports the `kubeconfig`.
2.  **Monitoring Layer (`monitoring-configs/`)**: 
    - **Helm**: Installs the `kube-prometheus-stack`.
    - **ServiceMonitor**: Tells Prometheus to scrape the `/metrics` endpoint of our API.
    - **ConfigMaps**: Injects custom Grafana dashboards automatically.
3.  **Application Layer (`k8s/`)**: Deploys the `.NET API`, `Worker`, and `Redis`.

### Data Flow
`Todo API` (Metrics) → `ServiceMonitor` → `Prometheus` → `Grafana` → `Discord Webhook`