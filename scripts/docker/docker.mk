DOCKER_IMAGE := ghcr.io/nhs-england-tools/update-from-template-app
DOCKER_TITLE := Update from Template App

# ==============================================================================

docker-build: # Build Docker image
	source ./scripts/docker/docker.sh
	docker-build

clean:: # Remove Docker resources
	source ./scripts/docker/docker.sh
	docker-clean

# ==============================================================================

.SILENT: \
	clean \
	docker-build
