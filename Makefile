SHELL := /bin/bash
.DEFAULT_GOAL := help

.PHONY: help setup resolve build run test check clean xcode

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

setup: resolve ## Resolve Swift package dependencies

resolve: ## Resolve SwiftPM dependencies
	swift package resolve

build: ## Build all Swift targets
	swift build

run: ## Run SparkAI app target
	swift run SparkAIApp

test: ## Run all tests
	swift test

check: build test ## Build + test

xcode: ## Generate Xcode project (if needed)
	swift package generate-xcodeproj || true

clean: ## Clean build artifacts
	swift package clean
