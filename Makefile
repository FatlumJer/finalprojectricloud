
TF_DIR = infra
KUBECONFIG_FILE = $(shell pwd)/kubeconfig

.PHONY: init apply deploy test destroy clean

init:
	@echo "Initializing Terraform..."
	cd $(TF_DIR) && terraform init


apply:
	@echo "Applying Infrastructure..."
	cd $(TF_DIR) && terraform apply -var-file="terraform.tfvars" -auto-approve
	@echo "Extracting Kubeconfig..."
	cd $(TF_DIR) && terraform output -raw kube_config > $(KUBECONFIG_FILE)
	@echo "Infrastructure is ready."


deploy:
	@echo "Deploying K8s manifests..."
	KUBECONFIG=$(KUBECONFIG_FILE) kubectl apply -f k8s/

test:
	@echo "Running connectivity tests..."
	@# Example: checking if the .NET API is responding
	KUBECONFIG=$(KUBECONFIG_FILE) kubectl get pods -A
	@echo "API Health check..."
	@# Replace with your LoadBalancer IP once deployed
	@# curl -f http://$(shell kubectl get svc -n app api-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/health || echo "App not ready"


destroy:
	@echo "Destroying Infrastructure..."
	cd $(TF_DIR) && terraform destroy -var-file="terraform.tfvars" -auto-approve
	rm -f $(KUBECONFIG_FILE)

clean:
	rm -f $(KUBECONFIG_FILE)
	find . -type d -name ".terraform" -exec rm -rf {} +
	find . -type f -name "*.tfstate*" -exec rm -f {} +