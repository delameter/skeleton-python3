## *PROJECT_NAME             ## *PROJECT_DESCRIPTION
## (C) *CYR                  ## A. Shavykin <0.delameter@gmail.com>
##---------------------------##-------------------------------------------------------------
.ONESHELL:
.PHONY: help test docs

PROJECT_NAME = *PROJECT_NAME
PROJECT_NAME_PUBLIC = ${PROJECT_NAME}
PROJECT_NAME_PRIVATE = ${PROJECT_NAME}-delameter

include .env.dist
-include .env
export
VERSION ?= 0.0.0

BOLD   := $(shell tput -Txterm bold)
UNDERL := $(shell tput -Txterm smul)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
RESET  := $(shell tput -Txterm sgr0)


## Common commands

help:   ## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v @fgrep | sed -Ee 's/^(##)\s*([^#]+)#*\s*(.*)/\1${YELLOW}\2${RESET}#\3/; s/(.+):(#|\s)+(.+)/##   ${GREEN}\1${RESET}#\3/; s/\*(\w+)\*/${UNDERL}\1${RESET}/g' | column -t -s '#'

all:   ## Prepare, run tests, generate docs and reports, build module
all: prepare test doctest coverage build

prepare:  ## Prepare environment for module building
	python3 -m venv venv
	. venv/bin/activate
	pip3 install --upgrade build twine
	pip3 install -r requirements.txt
	pip3 install -r requirements-dev.txt

prepare-pdf:  ## Prepare environment for pdf rendering
	sudo apt install texlive-latex-recommended \
					 texlive-fonts-recommended \
					 texlive-latex-extra latexmk

demolish-build:  ## Purge build output folders
	rm -f -v dist/* ${PROJECT_NAME_PUBLIC}.egg-info/* ${PROJECT_NAME_PRIVATE}.egg-info/*


## Testing / Pre-build

set-version: ## Set new package version
	@echo "Current version: ${YELLOW}${VERSION}${RESET}"
	read -p "New version (press enter to keep current): " VERSION
	if [ -z $$VERSION ] ; then echo "No changes" && return 0 ; fi
	if [ ! -f .env ] ; then cp -u .env.dist .env ; fi
	sed -E -i "s/^VERSION.+/VERSION=$$VERSION/" .env .env.dist
	sed -E -i "s/^version.+/version = $$VERSION/" setup.cfg
	sed -E -i "s/^__version__.+/__version__ = '$$VERSION'/" ${PROJECT_NAME}/_version.py
	echo "Updated version: ${GREEN}$$VERSION${RESET}"

test: ## Run pytest
	. venv/bin/activate
	PYTHONPATH=`pwd` python3 -m pytest tests

test-verbose: ## Run pytest with detailed output
	. venv/bin/activate
	PYTHONPATH=`pwd` python3 -m pytest tests -v

test-debug: ## Run pytest with VERY detailed output
	. venv/bin/activate
	PYTHONPATH=`pwd` python3 -m pytest tests -v --log-cli-level=DEBUG

doctest: ## Run doctest
	. venv/bin/activate
	sphinx-build docs docs/_build -b doctest -q && echo "Doctest ${GREEN}OK${RESET}"

coverage: ## Run coverage and make a report
	rm -v coverage-report/*
	. venv/bin/activate
	PYTHONPATH=`pwd` coverage run tests -vv
	coverage report
	coverage html
	if [ -n $$DISPLAY ] ; then xdg-open coverage-report/index.html ; fi

depends:  ## Build and display module dependency graph
	mkdir -p scripts/diagrams
	. venv/bin/activate
	pydeps ${PROJECT_NAME} --rmprefix ${PROJECT_NAME}. -o scripts/diagrams/imports.svg
	pydeps ${PROJECT_NAME} --rmprefix ${PROJECT_NAME}. -o scripts/diagrams/cycles.svg 	   --show-cycle                       --no-show
	pydeps ${PROJECT_NAME} --rmprefix ${PROJECT_NAME}. -o scripts/diagrams/imports-ext.svg --pylib  --collapse-target-cluster --no-show


## Documentation

reinit-docs: ## Erase and reinit docs with auto table of contents
	rm -v docs/*.rst
	. venv/bin/activate
	sphinx-apidoc --force --separate --module-first --tocfile index --output-dir docs ${PROJECT_NAME}

demolish-docs:  ## Purge docs output folder
	rm -rvf docs/_build

docs: ## Build HTML documentation
docs: demolish-docs
	. venv/bin/activate
	sphinx-build -aEn docs docs/_build -b html
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


## Releasing (dev)

build-dev: ## Create new private build ("*PROJECT_NAME-delameter")
build-dev: demolish-build
	sed -E -i "s/^name.+/name = ${PROJECT_NAME_PRIVATE}/" setup.cfg
	. venv/bin/activate
	python3 -m build --outdir dist-dev
	sed -E -i "s/^name.+/name = ${PROJECT_NAME_PUBLIC}/" setup.cfg

upload-dev: ## Upload latest private build to dev repo
	. venv/bin/activate
	python3 -m twine upload --repository testpypi dist-dev/* \
			-u ${PYPI_USERNAME} -p ${PYPI_PASSWORD_DEV} --verbose

install-dev: ## Install latest private build from dev repo
	. "${ES7S_VENV}/bin/activate"
	pip install -i https://test.pypi.org/simple/ ${PROJECT_NAME_PRIVATE}==${VERSION}

install-dev-public: ## Install latest *public* build from dev repo
	. "${ES7S_VENV}/bin/activate"
	pip install -i https://test.pypi.org/simple/ ${PROJECT_NAME_PUBLIC}==${VERSION}


## Releasing (MASTER)

build: ## Create new *public* build ("*PROJECT_NAME")
build: demolish-build
	. venv/bin/activate
	python3 -m build

upload: ## Upload latest *public* build to MASTER repo
	. venv/bin/activate
	python3 -m twine upload dist/* -u ${PYPI_USERNAME} -p ${PYPI_PASSWORD} --verbose

install: ## Install latest *public* build from MASTER repo using pipx
	pipx install ${PROJECT_NAME_PUBLIC}

##-----------------------##-------------------------------------------------------------
## To install private    ## #
## build as public one:## #
# make build upload-dev install-dev-public :##
##                       ## #                                               (dont do that)
########################### #
