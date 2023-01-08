APP := ask-gpt
VERSION := $(shell git describe --tags --always --dirty)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# Go TASKS
build:  bin ## Build Go
	cd $(APP) && go build -v -installsuffix 'static' -o bin/ -ldflags "-X main.Version='${VERSION}'"

bin: clean
	mkdir -p $(APP)/bin/

clean: ## Clean Go
	rm -rf $(APP)/bin/



