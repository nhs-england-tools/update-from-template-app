DOCKER_IMAGE := ghcr.io/nhs-england-tools/update-from-template-app
DOCKER_TITLE := Update from Template App

# ==============================================================================

docker-build: # Build Docker image
	source ./scripts/docker/docker.sh
	docker-build

docker-test: # Test Docker image
	source ./scripts/docker/docker.sh
	args=" \
		-e REPOSITORY_TEMPLATE=github.com/nhs-england-tools/repository-template \
		-e REPOSITORY_TO_UPDATE=github.com/nhs-england-tools/update-from-template-app \
		-v ${PWD}/tests/docker:/github/workspace \
	" \
	docker-run

clean:: # Remove Docker resources
	source ./scripts/docker/docker.sh
	docker-clean

# ==============================================================================

.SILENT: \
	clean \
	docker-build
