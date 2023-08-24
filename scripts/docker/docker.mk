# This file is for you! Edit it to implement your own Docker make targets.

# ==============================================================================
# Custom implementation

DOCKER_IMAGE := ghcr.io/nhs-england-tools/update-from-template-app
DOCKER_TITLE := Update from Template App

docker-build: # Build Docker image - optional: dir=[path to the Dockerfile to use, default is '.']
	source ./scripts/docker/docker.lib.sh
	docker-build

docker-test: # Test Docker image
	source ./scripts/docker/docker.lib.sh
	args=" \
		-e REPOSITORY_TEMPLATE \
		-e BRANCH_NAME \
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
	source ./scripts/docker/docker.lib.sh
	docker-clean

# ==============================================================================
# Quality checks

docker-shellscript-lint: # Lint all Docker module shell scripts
	for file in $$(find ./scripts/docker -type f -name "*.sh"); do
		file=$$file ./scripts/shellscript-linter.sh
	done

# ==============================================================================

.SILENT: \
	clean \
	docker-build \
	docker-shellscript-lint \
	docker-test
