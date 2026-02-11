# 📕 Operations Runbook: High Traffic Alert

**Alert Trigger**: `http_requests_received_total` > 10 req/s (sustained for 2m)

### 🚨 Immediate Response
1. **Validate**: Check the Discord notification timestamp.
2. **Visualize**: Open the [Grafana Dashboard](http://localhost:3000). Is the spike continuing?
3. **Verify Health**: Run `make test` to ensure the API is still responding.

### 🛠️ Troubleshooting Steps
- **Scenario A: Legitimate Traffic Spike**
  - Increase replicas: `kubectl scale deployment todo-api --replicas=5`
- **Scenario B: Resource Exhaustion**
  - Check pod logs: `kubectl logs -l app=todo-api --tail=50`
  - Check for OOMKilled events: `kubectl get pods -A | grep -i terminate`

### ⏹️ Resolution
Once the traffic subsides, ensure the alert status in Grafana returns to **OK**.