## *PROJECT_NAME             ## *PROJECT_DESCRIPTION
## (C) *CYR                  ## A. Shavykin <0.delameter@gmail.com>
##---------------------------##-------------------------------------------------------------
.ONESHELL:
.PHONY: help test docs

PROJECT_NAME = *PROJECT_NAME
PROJECT_NAME_PUBLIC = ${PROJECT_NAME}
PROJECT_NAME_PRIVATE = ${PROJECT_NAME}-delameter
DEPENDS_PATH = misc/depends
COVERAGE_PATH = misc/coverage

include .env.dist
-include .env
export
VERSION ?= 0.0.0

BOLD   := $(shell tput -Txterm bold)
UNDERL := $(shell tput -Txterm smul)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
BLUE   := $(shell tput -Txterm setaf 4)
DIM   := $(shell tput -Txterm dim)
RESET  := $(shell tput -Txterm sgr0)

##
## Common commands

help:   ## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v @fgrep | sed -Ee 's/^(##)\s?(\s*#?[^#]+)#*\s*(.*)/\1${YELLOW}\2${RESET}#\3/; s/(.+):(#|\s)+(.+)/##   ${GREEN}\1${RESET}#\3/; s/\*(\w+)\*/${BOLD}\1${RESET}/g; 2~1s/<([*A-Za-z0-9_-]+)>/${DIM}\1${RESET}/gi' -e 's/(\x1b\[)33m#/\136m/' | column -ts#

all:   ## Prepare, run tests, generate docs and reports, build module
all: prepare test doctest coverage build

prepare:  ## Prepare environment for module building
	rm -vrf venv
	python -m venv venv
	python -m pip install pipx
	venv/bin/pip install --upgrade build twine
	venv/bin/pip install -r requirements.txt
	venv/bin/pip install -r requirements-dev.txt

prepare-extra:  ## Prepare system for pdf rendering and dependency graph building
	sudo apt install texlive-latex-recommended \
					 texlive-fonts-recommended \
					 texlive-latex-extra \
					 latexmk \
					 graphviz

##
## Pre-build

demolish-build:  ## Delete build output folders
	rm -f -v dist/* ${PROJECT_NAME_PUBLIC}.egg-info/* ${PROJECT_NAME_PRIVATE}.egg-info/*

show-version: ## Show current package version
	@echo "Current version: ${YELLOW}${VERSION}${RESET}"

set-version: ## Set new package version
set-version: show-version
	@echo "Current version: ${YELLOW}${VERSION}${RESET}"
	read -p "New version (press enter to keep current): " VERSION
	if [ -z $$VERSION ] ; then echo "No changes" && return 0 ; fi
	if [ ! -f .env ] ; then cp -u .env.dist .env ; fi
	sed -E -i "s/^VERSION.+/VERSION=$$VERSION/" .env .env.dist
	sed -E -i "s/^version.+/version = $$VERSION/" setup.cfg
	sed -E -i "s/^__version__.+/__version__ = '$$VERSION'/" ${PROJECT_NAME}/__init__.py
	echo "Updated version: ${GREEN}$$VERSION${RESET}"

depends:  ## Build and display module dependency graph
	rm -vrf ${DEPENDS_PATH}
	mkdir -p ${DEPENDS_PATH}
	venv/bin/pydeps ${PROJECT_NAME} --rmprefix ${PROJECT_NAME}. --start-color 120 \
	    --max-bacon 1 -o ${DEPENDS_PATH}/imports-ext0.svg
	venv/bin/pydeps ${PROJECT_NAME} --rmprefix ${PROJECT_NAME}. --start-color 0 \
	    --max-bacon 2 -o ${DEPENDS_PATH}/imports-ext1.svg --no-show
	venv/bin/pydeps ${PROJECT_NAME} --show-cycle --start-color 120 \
	    --max-bacon 1 -o ${DEPENDS_PATH}/cycles.svg --no-show

purge-cache:  ## Clean up pycache
	find . -type d \( -name __pycache__ -or -name .pytest_cache \) -print -exec rm -rf {} +

##
## Testing

test: ## Run pytest
	venv/bin/pytest tests

test-verbose: ## Run pytest with detailed output
	venv/bin/pytest tests -v

test-debug: ## Run pytest with VERY detailed output
	venv/bin/pytest tests -v --log-cli-level=DEBUG

doctest: ## Run doctest
	venv/bin/sphinx-build docs docs/_build -b doctest -q && echo "Doctest ${GREEN}OK${RESET}"

coverage: ## Run coverage and make a report
	rm -vrf ${COVERAGE_PATH}
	venv/bin/python -m coverage run tests -vv
	venv/bin/coverage report
	venv/bin/coverage html
	if [ -n $$DISPLAY ] ; then xdg-open ${COVERAGE_PATH}/index.html ; fi

##
## Documentation

reinit-docs: ## Erase and reinit docs with auto table of contents
	rm -v docs/*.rst
	venv/bin/sphinx-apidoc --force --separate --module-first --tocfile index --output-dir docs ${PROJECT_NAME}

demolish-docs:  ## Purge docs output folder
	rm -rvf docs/_build

docs: ## Build HTML documentation
docs: demolish-docs
	venv/bin/sphinx-build -aEn docs docs/_build -b html
	@if [ -n "${DISPLAY}" ] ; then xdg-open docs/_build/index.html ; fi

docs-pdf: ## Build PDF documentation
	mkdir -p docs-build
	. venv/bin/activate
	yes "" | make -C docs latexpdf  # twice for building pdf toc
	yes "" | make -C docs latexpdf  # @FIXME broken unicode
	mv docs/_build/latex/${PROJECT_NAME}.pdf docs-build/${PROJECT_NAME}.pdf
	@if [ -n "${DISPLAY}" ] ; then xdg-open docs-build/${PROJECT_NAME}.pdf ; fi

docs-all: ## Build documentation in all formats
docs-all: docs docs-pdf

##
## Building / Packaging
### local <*PROJECT_NAME>

reinstall-local:  ## (Re)install as editable package
	pipx uninstall ${PROJECT_NAME}
	pipx install ${PROJECT_NAME} --pip-args="-e ."

### dev <*PROJECT_NAME-delameter>

build-dev: ## Create new private build
build-dev: demolish-build
	sed -E -i "s/^name.+/name = ${PROJECT_NAME_PRIVATE}/" setup.cfg
	venv/bin/build --outdir dist-dev
	sed -E -i "s/^name.+/name = ${PROJECT_NAME_PUBLIC}/" setup.cfg

upload-dev: ## Upload last private build (=> dev registry)
	venv/bin/twine upload \
	    --repository testpypi \
	    -u ${PYPI_USERNAME} \
	    -p ${PYPI_PASSWORD_DEV} \
	    --verbose \
	    dist-dev/*

install-dev: ## Install latest private build from dev registry
	pipx uninstall ${PROJECT_NAME_PRIVATE}
	pipx install ${PROJECT_NAME_PRIVATE}==${VERSION} --pip-args="-i https://test.pypi.org/simple/"

### release <*PROJECT_NAME>

build: ## Create new *public* build
build: demolish-build
	venv/bin/build

upload: ## Upload last *public* build (=> PRIMARY registry)
	venv/bin/twine upload \
	    -u ${PYPI_USERNAME} \
	    -p ${PYPI_PASSWORD} \
	    --verbose \
	    dist/*

install: ## Install latest *public* build from PRIMARY registry
	pipx install ${PROJECT_NAME_PUBLIC}

##
