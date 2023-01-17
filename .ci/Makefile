BASE_PATH := $(shell git rev-parse --show-toplevel)
BUILD_PATH := $(BASE_PATH)/bin

APP_NAME := $(word 2,$(MAKECMDGOALS)) 
APP_PATH := $(BASE_PATH)/go-cli/$(APP_NAME)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

# Outputs the help for each task, which includes a brief description and usage information
help: ## This help. 
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# Build the Go application, creating a binary in the bin directory in the root of the project
# The APP variable is set to the second argument passed to the make command 
# specifies which app to build under go-cli directory
build:  bin  ## Build Go
	@echo "Building $(APP_NAME)..."
	@go build -v -installsuffix 'static' -o $(BASE_PATH) $(APP_PATH)
	@echo "Build Complete"

# Create the bin directory if it doesn't exist
bin: 
	@mkdir -p $(BUILD_PATH)

# Delete the bin directory. This will remove the binary created by the build command
clean: ## Clean Go
	@echo "Cleaning build files..."
	@rm -rf $(BUILD_PATH)
	@echo "Cleanup complete."




