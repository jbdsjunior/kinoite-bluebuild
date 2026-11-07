# Developer entry points for the kinoite-bluebuild image definitions.
#
# Note: this Makefile never builds or publishes an image. Builds are triggered
# manually (workflow_dispatch) or by .github/workflows/check-updates.yml.
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

YAMLLINT ?= yamllint
SHELLCHECK ?= shellcheck
ACTIONLINT ?= actionlint
BLUEBUILD ?= bluebuild

SHELL_SCRIPTS := $(shell git ls-files '*.sh' '.github/scripts/*.sh' 'files/**/usr/bin/*')
YAML_FILES := $(shell git ls-files '*.yml' '*.yaml')
RECIPES := $(shell git ls-files 'recipes/recipe-*.yml')

.DEFAULT_GOAL := help

.PHONY: help lint lint-shell lint-yaml lint-actions validate check hooks clean

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*## "; printf "Targets:\n"} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

lint: lint-shell lint-yaml lint-actions ## Run every available linter

lint-shell: ## Run shellcheck on repository scripts
	$(SHELLCHECK) -S warning $(SHELL_SCRIPTS)

lint-yaml: ## Run yamllint with the repository configuration
	$(YAMLLINT) --strict -f github $(YAML_FILES)

lint-actions: ## Lint GitHub Actions workflows (skipped when actionlint is absent)
	@if command -v $(ACTIONLINT) >/dev/null 2>&1; then \
		$(ACTIONLINT) -color; \
	else \
		echo "actionlint not installed; skipping workflow lint"; \
	fi

validate: ## Validate BlueBuild recipes with the BlueBuild CLI
	@if ! command -v $(BLUEBUILD) >/dev/null 2>&1; then \
		echo "ERROR: bluebuild CLI not found in PATH" >&2; \
		exit 1; \
	fi
	@for recipe in $(RECIPES); do \
		echo "==> $$recipe"; \
		$(BLUEBUILD) validate --all-errors "$$recipe"; \
	done

check: lint validate ## Run every static check (what CI does)

hooks: ## Enable the repository git hooks
	git config core.hooksPath .githooks
	@echo "core.hooksPath=$(shell git config --get core.hooksPath)"

clean: ## Remove local build/test artifacts
	rm -rf .bluebuild-scripts_* Containerfile
