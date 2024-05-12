## *PROJECT_NAME             ## *PROJECT_DESCRIPTION
## (C) *CYR                  ## A. Shavykin <0.delameter@gmail.com>
##---------------------------##-------------------------------------------------------------
.ONESHELL:
.PHONY: help test docs

HOST_DEFAULT_PYTHON ?= /usr/bin/python

ENV_BUILD_DIST_FILE_PATH ?= .env.build.dist
ENV_BUILD_LOCAL_FILE_PATH ?= .env.build
ENV_RUN_DIST_FILE_PATH ?= .env.dist
ENV_RUN_LOCAL_FILE_PATH ?= .env.local
ENV_RUN_DOCKER_FILE_PATH ?= .env.docker

include ${DOTENV_DIST}
-include ${DOTENV}
export
VERSION := $(shell ./.version)
VERSION ?= 0.0.0

DOCKER_IMAGE = $(REGISTRY_NAME)/$(PACKAGE_NAME)
DOCKER_TAG = ${DOCKER_IMAGE}:${VERSION}
DOCKER_CONTAINER = $(PACKAGE_NAME)-build-${VERSION}

NOW    := $(shell date '+%Y-%b-%0e.%H%M%S.%3N')
BOLD   := $(shell tput -Txterm bold)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
BLUE   := $(shell tput -Txterm setaf 4)
DIM    := $(shell tput -Txterm dim)
RESET  := $(shell printf '\e[m')
                                # tput -Txterm sgr0 returns SGR-0 with
                                # nF code switching esq, which displaces the columns
## Common commands

help:   ## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v @fgrep | sed -Ee 's/^(##)\s?(\s*#?[^#]+)#*\s*(.*)/\1${YELLOW}\2${RESET}#\3/; s/(.+):(#|\s)+(.+)/##   ${GREEN}\1${RESET}#\3/; s/\*(\w+)\*/${BOLD}\1${RESET}/g; 2~1s/<([*<@>.A-Za-z0-9_-]+)>/${DIM}\1${RESET}/gi' -e 's/(\x1b\[)33m#/\136m/' | column -ts# | sed -Ee 's/ {3}>/ >/'

_cp_env = ([ ! -s $2 ] && { sed -E < $1 > $2  -e "1i\# This file has a higher priority than $1\n" -e "/^(\#|$$)/d" && echo "File created: $2" ; } || echo "Skipping: $2 already exists" ; )

prepare:  ## Initialize local configuration file for module building
	@$(call _cp_env,$(ENV_BUILD_DIST_FILE_PATH),$(ENV_BUILD_LOCAL_FILE_PATH))
	@$(call _cp_env,$(ENV_RUN_DIST_FILE_PATH),$(ENV_RUN_LOCAL_FILE_PATH))
	@$(call _cp_env,$(ENV_RUN_DIST_FILE_PATH),$(ENV_RUN_DOCKER_FILE_PATH))

init-skeleton:  ## Replace placeholders throughout the skeleton
	./init.sh

reinit-venv:  ## > Prepare environment for module building  <venv>
	@:


##
## Pre-build

freeze:  ## Actualize the requirements.txt file(s)
	@:

demolish-build:  ## Delete build output folders
	@:

show-version: ## Show current package version
	@echo "Current version: ${YELLOW}${VERSION}${RESET}"

set-version: ## Set new package version
set-version: show-version
	@:

depends:  ## Build and display module dependency graph
	rm -vrf ${OUT_DEPS_PATH}
	mkdir -p ${OUT_DEPS_PATH}
	./pydeps.sh ${VENV_PATH}/bin/pydeps ${PROJECT_NAME} ${OUT_DEPS_PATH}

purge-cache:  ## Clean up pycache
	find . -type d \( -name __pycache__ -or -name .pytest_cache \) -print -exec rm -rf {} +

##
## Testing

test: ## Run pytest
	@:

test-verbose: ## Run pytest with detailed output
	@:

test-debug: ## Run pytest with VERY detailed output
	@:

coverage: ## Run coverage and make a report
	@:
