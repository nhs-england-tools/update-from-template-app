DOCKER_IMAGE:=ghcr.io/nhs-england-tools/synchronise-template-action

docker-build: # Build Docker image
	docker build \
		--progress=plain \
		--build-arg IMAGE=${DOCKER_IMAGE} \
		--build-arg TITLE="Synchronise Template Action" \
		--build-arg DESCRIPTION="Synchronise Template Action" \
		--build-arg LICENCE=MIT \
		--build-arg GIT_URL=$$(git config --get remote.origin.url) \
		--build-arg GIT_BRANCH=$$(git rev-parse --abbrev-ref HEAD) \
		--build-arg GIT_COMMIT_HASH=$$(git rev-parse --short HEAD) \
		--build-arg BUILD_DATE=$$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
		--build-arg BUILD_VERSION=$$(cat VERSION) \
		--tag ${DOCKER_IMAGE}:$$(cat VERSION) \
		--rm \
		--file ./Dockerfile \
		.
	docker tag ${DOCKER_IMAGE}:$$(cat VERSION) ${DOCKER_IMAGE}:latest
	docker rmi --force $$(docker images | grep "<none>" | awk '{ print $$3 }') 2> /dev/null ||:

docker-test: # Test Docker image
	docker run --rm ${DOCKER_IMAGE}:$$(cat VERSION) 2>/dev/null \
		| grep -q "Hello" && echo PASS || echo FAIL

docker-run: # Run Docker image - mandatory: args=[command-line arguments]
	docker run --rm \
		--volume $$(PWD)/tests:/tests \
		${DOCKER_IMAGE}:$$(cat VERSION) \
		${args}

docker-clean: # Remove Docker image
	docker rmi ${DOCKER_IMAGE}:$$(cat VERSION) > /dev/null 2>&1 ||:
	docker rmi ${DOCKER_IMAGE}:latest > /dev/null 2>&1 ||:

docker-push: # Push Docker image
	docker push ${DOCKER_IMAGE}:$$(cat VERSION)
	docker push ${DOCKER_IMAGE}:latest

clean:: # Remove resources created by Docker
	make docker-clean

# ==============================================================================

.SILENT: \
	clean \
	docker-build \
	docker-clean \
	docker-run \
	docker-push \
	docker-test
