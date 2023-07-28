OS   := $(shell uname | awk '{print tolower($$0)}')
ARCH := $(shell case $$(uname -m) in (x86_64) echo amd64 ;; (aarch64) echo arm64 ;; (*) echo $$(uname -m) ;; esac)

KUBERNETES_VERSION    := 1.27.3
KIND_VERSION          := 0.20.0
INGRESS_NGINX_VERSION := 1.8.1

BIN_DIR := $(shell pwd)/bin

KUBECTL := $(abspath $(BIN_DIR)/kubectl)
KIND    := $(abspath $(BIN_DIR)/kind)

KIND_CLUSTER_NAME := kubernetes-hands-on

KUBECTL_CMD := KUBECONFIG=./.kubeconfig $(KUBECTL)
KIND_CMD    := $(KIND) --name $(KIND_CLUSTER_NAME) --kubeconfig ./.kubeconfig

kubectl: $(KUBECTL)
$(KUBECTL):
	curl -Lso $(KUBECTL) https://storage.googleapis.com/kubernetes-release/release/v$(KUBERNETES_VERSION)/bin/$(OS)/$(ARCH)/kubectl
	chmod +x $(KUBECTL)

kind: $(KIND)
$(KIND):
	curl -Lso $(KIND) https://github.com/kubernetes-sigs/kind/releases/download/v$(KIND_VERSION)/kind-$(OS)-$(ARCH)
	chmod +x $(KIND)

.PHONY: cluster
cluster: $(KIND) $(KUBECTL) $(ISTIOCTL)
	$(KIND_CMD) delete cluster
	$(KIND_CMD) create cluster --image kindest/node:v${KUBERNETES_VERSION} --config ./kind.yaml
	$(KUBECTL_CMD) apply --filename ./ingress-nginx.yaml

.PHONY: ingress-nginx-manifest
ingress-nginx-manifest:
	@curl -s https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v$(INGRESS_NGINX_VERSION)/deploy/static/provider/kind/deploy.yaml > ./ingress-nginx.yaml

.PHONY: clean
clean:
	$(KIND_CMD) delete cluster
	rm -f $(BIN_DIR)/*
