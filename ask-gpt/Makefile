APP := $(shell basename $(CURDIR))/ask-gpt
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
	go build -v -installsuffix 'static' -o bin/ -ldflags "-X main.Version='${VERSION}'"
	
check-for-updates:	## View minor/patch upgrades 
	go list -u -f '{{if (and (not (or .Main .Indirect)) .Update)}}{{.Path}}: {{.Version}} -> {{.Update.Version}}{{end}}' -m all 2> /dev/null

bin: clean
	mkdir -p bin/

clean: ## Clean Go
	rm -rf bin/


