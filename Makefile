# This file is for you! Edit it to implement your own hooks (make targets) into
# the project as automated steps to be executed on locally and in the CD pipeline.

include ./scripts/init.mk
include ./scripts/test.mk

# Example targets are: dependencies, build, publish, deploy, clean, etc.

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

clean:: # Clean-up project resources
	rm -rf \
		.docker/repository-template \
		.docker/repository-to-update \
		.docker/update-from-template.json \
		build/update-from-template \
		coverage.* \
		tests/contract-test/output.json

.SILENT: \
	clean \
	build \
	cmd-build \
	cmd-contract-test \
	cmd-run \
	cmd-unit-test \
	config
