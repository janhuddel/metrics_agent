# Makefile for Elixir Metrics Agent

.PHONY: help deps compile test run clean dev prod panic-test

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

deps: ## Install dependencies
	mix deps.get

test: deps ## Run tests
	mix test

run: compile ## Run the application (logs to stderr, line protocol to stdout)
	mix run --no-halt

dev: ## Run in development mode (logs to stderr, line protocol to stdout)
	MIX_ENV=dev mix run --no-halt

prod: ## Run in production mode (logs to stderr, line protocol to stdout)
	MIX_ENV=prod mix run --no-halt

shell: ## Start interactive shell
	iex -S mix

clean: ## Clean build artifacts
	mix clean
	rm -rf _build/
	rm -rf deps/
	rm -rf cover/

format: ## Format code
	mix format

release: test ## Create a release
	MIX_ENV=prod mix release

release-tarball: release ## Create a release tarball for distribution
	mkdir -p ./_build/release-tarballs
	# Create tarball with release
	tar -czf ./_build/release-tarballs/metrics_agent.tar.gz -C _build/prod/rel metrics_agent
	@echo "Release tarball created: metrics_agent.tar.gz"

install: deps compile ## Install and compile everything
	@echo "Installation complete!"
