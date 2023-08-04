include ./scripts/init.mk
include ./scripts/docker.mk

cmd-unit-test: # Run command-line tool unit tests
	go test -coverprofile=coverage.out  -v ./...
	go tool cover -html=coverage.out -o coverage.html

cmd-contract-test: # Run command-line tool contract test - optional: DATASET=[test data set name, defaults to `small`]
	# Act
	go run ./cmd/compare-directories \
		-dir1=./tests/data/$(or $(DATASET), small)/dir1 \
		-dir2=./tests/data/$(or $(DATASET), small)/dir2 \
			> ./tests/contract-test/output.json
	# Assert
	go run ./tests/contract-test \
		-schema=./tests/contract-test/schema.json \
		-output=./tests/contract-test/output.json

cmd-build: # Build command-line tool
	go build -o ./build/compare-directories ./cmd/compare-directories/
	test -x ./build/compare-directories

cmd-run: # Run command-line tool - optional: DATASET=[test data set name, defaults to `small`]
	./build/compare-directories \
		-dir1=./tests/data/$(or $(DATASET), small)/dir1 \
		-dir2=./tests/data/$(or $(DATASET), small)/dir2 \
		-cfg=./tests/data/.config.yaml \
	| jq

clean:: # Clean the project
	rm -f \
		./build/compare-directories \
		./coverage.* \
		./tests/contract-test/output.json

config: # Configure development environment
	make \
		asdf-install \
		githooks-install

# ==============================================================================

.SILENT: \
	clean \
	cmd-build \
	cmd-contract-test \
	cmd-integration-test \
	cmd-performance-test \
	cmd-run \
	cmd-unit-test \
	config
