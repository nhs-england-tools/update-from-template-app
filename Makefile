include ./scripts/init.mk
include ./scripts/test.mk
include ./scripts/docker/docker.mk

# ==============================================================================

build: # Build the project
	make \
		cmd-build \
		docker-build

cmd-unit-test: # Run command-line tool unit tests
	go test -coverprofile=coverage.out  -v ./...
	go tool cover -html=coverage.out -o coverage.html

cmd-contract-test: # Run command-line tool contract test - optional: DATASET=[test data set name, defaults to `small`]
	# Act
	go run ./cmd/update-from-template \
		--source-dir ./tests/data/$(or $(DATASET), small)/dir1 \
		--destination-dir ./tests/data/$(or $(DATASET), small)/dir2 \
		--app-config-file ./tests/data/.config-app.yaml \
		--template-config-file ./tests/data/.config-template.yaml \
			> ./tests/contract-test/output.json
	# Assert
	go run ./tests/contract-test \
		-schema=./tests/contract-test/schema.json \
		-output=./tests/contract-test/output.json

cmd-build: # Build command-line tool
	go build -o ./build/update-from-template ./cmd/update-from-template/
	test -x ./build/update-from-template

cmd-run: # Run command-line tool - optional: DATASET=[test data set name, defaults to `small`]
	./build/update-from-template \
		--source-dir ./tests/data/$(or $(DATASET), small)/dir1 \
		--destination-dir ./tests/data/$(or $(DATASET), small)/dir2 \
		--app-config-file ./tests/data/.config-app.yaml \
		--template-config-file ./tests/data/.config-template.yaml \
	| jq

clean:: # Clean the project
	rm -rf \
		.docker/repository-template \
		.docker/repository-to-update \
		.docker/update-from-template.json \
		build/update-from-template \
		coverage.* \
		tests/contract-test/output.json

config: # Configure development environment
	make \
		asdf-install \
		githooks-install

# ==============================================================================

.SILENT: \
	clean \
	build \
	cmd-build \
	cmd-contract-test \
	cmd-integration-test \
	cmd-performance-test \
	cmd-run \
	cmd-unit-test \
	config
