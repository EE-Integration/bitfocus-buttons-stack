DOCKER_IMAGE ?= efg01/bitfocus-buttons
DOCKER_PLATFORM ?= linux/amd64
DOCKER_CONTEXT ?= colima
IMAGE_TAG ?= latest
BUTTONS_TARBALL ?= bitfocus-buttons-linux-x64-5585-918fc50d.tar.gz
BUTTONS_URL ?= https://s4-cf.bitfocus.io/builds/buttons/bitfocus-buttons-linux-x64-5585-918fc50d.tar.gz
BUILDER_NAME ?= colima-amd64

.PHONY: help docker-preflight docker-colima-up docker-build-amd64 docker-push-amd64 docker-build-local docker-push-local

help:
	@echo "Bitfocus Buttons stack - image build targets"
	@echo ""
	@echo "  make docker-build-amd64 Build linux/amd64 image with IMAGE_TAG + latest (load local)"
	@echo "  make docker-push-amd64  Buildx push linux/amd64 image with IMAGE_TAG + latest"
	@echo "  make docker-colima-up   Start Colima (qemu) if not running"
	@echo "  make docker-build-local Alias for docker-build-amd64"
	@echo "  make docker-push-local  Alias for docker-push-amd64"
	@echo ""
	@echo "Overrides:"
	@echo "  DOCKER_CONTEXT=$(DOCKER_CONTEXT)"
	@echo "  DOCKER_IMAGE=$(DOCKER_IMAGE)"
	@echo "  IMAGE_TAG=$(IMAGE_TAG)"
	@echo "  BUTTONS_TARBALL=$(BUTTONS_TARBALL)"
	@echo "  BUTTONS_URL=$(BUTTONS_URL)"
	@echo ""
	@echo "Example:"
	@echo "  make docker-push-amd64 IMAGE_TAG=5585 BUTTONS_TARBALL=bitfocus-buttons-linux-x64-5585-918fc50d.tar.gz"

docker-preflight:
	@docker --context $(DOCKER_CONTEXT) info >/dev/null 2>&1 || { \
		echo "Docker context '$(DOCKER_CONTEXT)' is not reachable."; \
		echo "Start Colima first: make docker-colima-up"; \
		exit 1; \
	}

docker-colima-up:
	colima start --vm-type qemu

docker-build-amd64: docker-preflight
	@docker --context $(DOCKER_CONTEXT) buildx inspect $(BUILDER_NAME) >/dev/null 2>&1 || \
		docker --context $(DOCKER_CONTEXT) buildx create --name $(BUILDER_NAME) --driver docker-container --use
	docker --context $(DOCKER_CONTEXT) buildx use $(BUILDER_NAME)
	docker --context $(DOCKER_CONTEXT) buildx build --platform $(DOCKER_PLATFORM) --load \
		--build-arg BUTTONS_TARBALL=$(BUTTONS_TARBALL) \
		--build-arg BUTTONS_URL=$(BUTTONS_URL) \
		-t $(DOCKER_IMAGE):$(IMAGE_TAG) \
		-t $(DOCKER_IMAGE):latest .

docker-push-amd64: docker-preflight
	@docker --context $(DOCKER_CONTEXT) buildx inspect $(BUILDER_NAME) >/dev/null 2>&1 || \
		docker --context $(DOCKER_CONTEXT) buildx create --name $(BUILDER_NAME) --driver docker-container --use
	docker --context $(DOCKER_CONTEXT) buildx use $(BUILDER_NAME)
	docker --context $(DOCKER_CONTEXT) buildx build --platform $(DOCKER_PLATFORM) --push \
		--build-arg BUTTONS_TARBALL=$(BUTTONS_TARBALL) \
		--build-arg BUTTONS_URL=$(BUTTONS_URL) \
		-t $(DOCKER_IMAGE):$(IMAGE_TAG) \
		-t $(DOCKER_IMAGE):latest .

docker-build-local: docker-build-amd64

docker-push-local: docker-push-amd64
