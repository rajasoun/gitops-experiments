BASE_PATH=$(shell git rev-parse --show-toplevel)
VERSION := $(shell git describe --tags --always --dirty) # Version of the app
TRIMMED_VERSION := $(patsubst %,$(strip %),$(VERSION))

# Get the second args from the command line
APP := $(word 2,$(MAKECMDGOALS))

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# Go TASKS
build:  bin ## Build Go
	go build -v -installsuffix 'static' -o "$(BASE_PATH)/bin/" $(BASE_PATH)/$(APP)

all:'"

bin: clean
	mkdir -p "$(BASE_PATH)/bin/"

clean: ## Clean Go
	rm -rf "$(BASE_PATH)/bin/"



