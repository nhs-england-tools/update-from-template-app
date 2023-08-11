DOCKER_IMAGE := ghcr.io/nhs-england-tools/update-from-template-app
DOCKER_TITLE := Update from Template App

# ==============================================================================

docker-build: # Build Docker image
	source ./scripts/docker/docker.sh
	docker-build

docker-test: # Test Docker image
	source ./scripts/docker/docker.sh
	args=" \
		-e REPOSITORY_TEMPLATE \
		-e REPOSITORY_TO_UPDATE \
		-e GIT_USER_NAME \
		-e GIT_USER_EMAIL \
		-e GITHUB_APP_ID \
		-e GITHUB_APP_PK \
		-e GITHUB_APP_SK_ID \
		-e GITHUB_APP_SK_CONTENT \
		-e GITHUB_APP_SK_PASSPHRASE \
		-e DRY_RUN \
		-e VERBOSE \
		-v ${PWD}/.docker:/github/workspace \
	" \
	docker-run

clean:: # Remove Docker resources
	source ./scripts/docker/docker.sh
	docker-clean

# ==============================================================================

.SILENT: \
	clean \
	docker-build
