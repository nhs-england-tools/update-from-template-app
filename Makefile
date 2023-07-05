include ./scripts/init.mk
include ./docker/include.mk

config: # Configure development environment
	make \
		asdf-install \
		githooks-install

.SILENT: \
	config
