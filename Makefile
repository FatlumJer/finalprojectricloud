TF_DIR = infra
KUBECONFIG_FILE = $(shell pwd)/kubeconfig
MONITORING_NS = monitoring
HELM_RELEASE = monitoring

.PHONY: init apply deploy test destroy clean install-monitoring deploy-dashboards deploy-servicemonitor

init:
	@echo "Initializing Terraform..."
	cd $(TF_DIR) && terraform init

apply:
	@echo "Applying Infrastructure..."
	cd $(TF_DIR) && terraform apply -var-file="terraform.tfvars" -auto-approve
	@echo "Extracting Kubeconfig..."
	cd $(TF_DIR) && terraform output -raw kube_config > $(KUBECONFIG_FILE)
	@echo "Infrastructure is ready."

# --- Monitoring Targets (Pointed to new folder) ---

install-monitoring:
	@echo "Installing Prometheus and Grafana via Helm..."
	KUBECONFIG=$(KUBECONFIG_FILE) helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	KUBECONFIG=$(KUBECONFIG_FILE) helm repo update
	KUBECONFIG=$(KUBECONFIG_FILE) helm upgrade --install $(HELM_RELEASE) prometheus-community/kube-prometheus-stack \
		--namespace $(MONITORING_NS) --create-namespace

deploy-dashboards:
	@echo "Deploying Custom Dashboards..."
	KUBECONFIG=$(KUBECONFIG_FILE) kubectl apply -f monitoring-configs/grafana-dashboard.yaml

deploy-servicemonitor:
	@echo "Deploying ServiceMonitor..."
	KUBECONFIG=$(KUBECONFIG_FILE) kubectl apply -f monitoring-configs/servicemonitor.yaml

# --- Main Targets ---

deploy:
	@echo "1. Deploying Application manifests (API, Worker, Redis)..."
	# This folder now ONLY contains app/worker/redis
	KUBECONFIG=$(KUBECONFIG_FILE) kubectl apply -f k8s/
	
	@echo "2. Waiting for App to be ready..."
	KUBECONFIG=$(KUBECONFIG_FILE) kubectl wait --for=condition=ready pod --selector=app=todo-api --timeout=60s
	
	@echo "3. --- Monitoring Setup ---"
	$(MAKE) install-monitoring
	
	@echo "4. Waiting 45s for Prometheus CRDs to be registered..."
	sleep 45
	
	@echo "5. Deploying Monitoring specific manifests..."
	$(MAKE) deploy-servicemonitor
	$(MAKE) deploy-dashboards
	
	@echo "🚀 Full stack successfully deployed!"

test:
	@echo "Running connectivity tests..."
	KUBECONFIG=$(KUBECONFIG_FILE) kubectl get pods -A
	@echo "Checking API Health..."
	$(eval IP=$(shell KUBECONFIG=$(KUBECONFIG_FILE) kubectl get svc todo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'))
	@echo "Testing Endpoint: http://$(IP)/todoitems"
	curl -f http://$(IP)/todoitems || echo "App not reachable yet - wait for LoadBalancer IP"

destroy:
	@echo "Destroying Infrastructure..."
	cd $(TF_DIR) && terraform destroy -var-file="terraform.tfvars" -auto-approve
	rm -f $(KUBECONFIG_FILE)

clean:
	rm -f $(KUBECONFIG_FILE)
	find . -type d -name ".terraform" -exec rm -rf {} +
	find . -type f -name "*.tfstate*" -exec rm -f {} +