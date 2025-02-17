#This is an example top-level Makefile, inner Makefile-s would work similarly
SHELL := /usr/bin/env bash
# By default run multiple tools sequentially, when formatting  you may want to run "make -j1" to ensure formatters
# run sequentially
MAKEFLAGS += -j1

# resolver.mk and helpers.mk contain the AlphaBuild core logic
# Because some rules may be long, the Makefile is split in several smaller files (they all belong to the same namespace).
# It is recommended to keep all "nested" rules in this file if possible.
include build-support/alpha-build/core/resolver.mk  # Utilities to resolve targets
include build-support/alpha-build/core/helpers.mk

# Set PYTHONPATH
PY_SOURCES_ROOTS=app_iqor:app_paper_plane:lib_py_utils # (taken from https://github.com/cristianmatache/workspace)
include build-support/alpha-build/core/python/pythonpath.mk  # Let AlphaBuild set PYTHONPATH based on PY_SOURCES_ROOTS

# Aliases (short names given to one or more paths, can be used to define the default targets,)
iqor=app_iqor/
utils=lib_py_utils/py_utils lib_py_utils/test_utils
gen_script=build-support/python/packaging/generate_pip_install_files.py

# Default targets - for formatting, linting, type-checking, testing (taken from https://github.com/cristianmatache/workspace)
ONPY=algo/ iqor app_paper_plane/ utils lib_bzl_utils/ gen_script  # References actual directories and/or aliases
ONSH=build-support/ deploy-support/ lib_sh_utils/
ONHS=tutorials_hs/scheme_interpreter
ONNB=notebooks/
ONMD=*.md $(shell find build-support/ -name "*.md")
ONYML=.ci-azure/ build-support/ deploy-support/ .pre-commit-config.yaml
ONHTML=iqor app_paper_plane/
ONCSS=$(ONHTML)

# Config files (i.e., mostly <TOOL>_FLAGS variables, which contain the flags for tools like pytest, mypy etc.)
include build-support/alpha-build/config/bash.mk
include build-support/alpha-build/config/multi.mk
include build-support/alpha-build/config/python.mk
include build-support/alpha-build/config/yaml.mk
include build-support/alpha-build/config/jupyter.mk
include build-support/alpha-build/config/markdown.mk

# Targets - for packaging (e.g. generation of requirements.txt files)
PY_LIBS=lib_py_utils/  # can be pip-install-ed
PY_APPS=app_paper_plane/ app_iqor/  # cannot be pip-installed
PY_PROJECTS=$(PY_LIBS) $(PY_APPS)
PY_LIB_NAMES=$(foreach path,$(PY_PROJECTS),$(shell basename $(path)))  # To be able to pip uninstall

# Bash
include build-support/alpha-build/core/bash/env.mk
include build-support/alpha-build/core/bash/format.mk
include build-support/alpha-build/core/bash/lint.mk
include build-support/alpha-build/core/bash/test.mk

.PHONY: fmt-sh lint-sh test-sh
fmt-sh: shfmt
fmt-check-sh: shfmt-check
lint-sh: shellcheck fmt-check-sh
test-sh: bats

# Multi language
include build-support/alpha-build/core/multi/env.mk
include build-support/alpha-build/core/multi/pre-commit.mk

# Python
#export MYPYPATH := $(PYTHONPATH)  # Uncomment to set MYPYPATH to be the same as PYTHONPATH
include build-support/alpha-build/core/python/env.mk
include build-support/alpha-build/extensions/python/env.mk  # Also include custom goals coming from make/extensions/
include build-support/alpha-build/core/python/format.mk
include build-support/alpha-build/core/python/lint.mk
include build-support/alpha-build/core/python/type-check.mk
include build-support/alpha-build/core/python/test.mk
include build-support/alpha-build/core/python/package.mk
include build-support/alpha-build/core/python/clean.mk
include build-support/alpha-build/core/python/pre-commit.mk

.PHONY: fmt-py fmt-check-py lint-py test-py clean-py
fmt-py: docformatter isort autoflake black flynt
fmt-check-py: autoflake-check docformatter-check isort-check black-check flynt-check
lint-py: mypy flake8 bandit fmt-check-py pylint
test-py: pytest
clean-py: clean-pyc clean-mypy clean-pytest clean-egg-info clean-whl clean-bdist

# Notebooks
include build-support/alpha-build/core/jupyter/format.mk
include build-support/alpha-build/core/jupyter/lint.mk

.PHONY: fmt-nb fmt-check-nb lint-nb
fmt-nb: nbstripout jblack
fmt-check-nb: jblack-check
lint-nb: flake8-nb fmt-check-nb

# Haskell
include build-support/alpha-build/core/haskell/lint.mk
include build-support/alpha-build/core/haskell/clean.mk

.PHONY: lint-hs clean-hs
lint-hs: hlint
clean-hs: clean-hio

# YAML
include build-support/alpha-build/core/yaml/format.mk
include build-support/alpha-build/core/yaml/lint.mk

.PHONY: fmt-yml lint-yml
fmt-yml: prettier-yml
fmt-check-yml: prettier-yml-check
lint-yml: yamllint fmt-check-yml

# Markdown
include build-support/alpha-build/core/markdown/env.mk
include build-support/alpha-build/core/markdown/format.mk
include build-support/alpha-build/core/markdown/lint.mk

.PHONY: fmt-md lint-md
fmt-md: markdownlint-fmt prettier-md
fmt-check-md: markdownlint prettier-md-check
lint-md: markdownlint fmt-check-md

# HTML/CSS/Web
include build-support/alpha-build/core/html/lint.mk
include build-support/alpha-build/core/html/format.mk
include build-support/alpha-build/core/css/lint.mk
include build-support/alpha-build/core/css/format.mk

.PHONY: fmt-html lint-html fmt-css lint-css
fmt-html: prettier-html
fmt-check-html: prettier-html-check
lint-html: fmt-check-html
fmt-css: prettier-css
fmt-check-css: prettier-css-check
lint-css: fmt-check-css
fmt-web: fmt-html fmt-css
fmt-check-web: fmt-check-html fmt-check-css
lint-web: fmt-check-web

# Cross-language BUILD goals
.PHONY: env-default-replicate env-default-upgrade fmt lint type-check test clean

env-default-replicate: env-py-default-replicate env-sh-default-replicate env-md-default-replicate env-prettier-default-replicate
env-default-upgrade: env-py-default-upgrade env-sh-default-upgrade env-md-default-upgrade env-prettier-default-upgrade

fmt: fmt-py fmt-nb fmt-yml fmt-md fmt-sh fmt-html fmt-web

fmt-check: fmt-check-py fmt-check-nb fmt-check-sh fmt-check-web

lint: lint-py lint-sh lint-nb lint-yml lint-md

type-check: mypy

test: test-py test-sh

clean: clean-py clean-hs

# OTHER ----------------------------------------------------------------------------------------------------------------
.PHONY: pre-commit install-pre-commit-hook uninstall-pre-commit-hook

# Run as `make pre-commit since=--cached`
pre-commit: lint pre-commit-tool

install-pre-commit-hook:
	cp build-support/git-hooks/pre-commit .git/hooks/

uninstall-pre-commit-hook:
	rm .git/hooks/pre-commit

rm-envs:
	rm -rf 3rdparty/md-env/node_modules/ 3rdparty/sh-env/node_modules/  3rdparty/prettier-env/node_modules/

# ------------ SPECIFIC TO AlphaBuild ONLY -------------
# Code to build and release a new version of AlphaBuild
build-wheel-core:
	rm -rf dist/
	rm alpha_build_core.tar.gz || echo "alpha_build_core.tar.gz does not exist yet"
	tar -cvzf alpha_build_core.tar.gz build-support/alpha-build/core
	python build-support/alpha-build/core/setup.py bdist_wheel

publish-wheel-core: clean-py build-wheel-core
	twine upload --repository-url https://test.pypi.org/legacy/ dist/*

build-wheel-utils:
	rm -rf dist/
	rm alpha_build_git_bash_utils.tar.gz || echo "alpha_build_utils.tar.gz does not exist yet"
	tar -cvzf alpha_build_git_bash_utils.tar.gz build-support/git-bash-integration
	python build-support/git-bash-integration/setup.py bdist_wheel

publish-wheel-utils: clean-py build-wheel-utils
	twine upload --repository-url https://test.pypi.org/legacy/ dist/*


# Example upgrade script from a monorepo that uses AlphaBuild
# pip install -i https://test.pypi.org/simple/ alpha-build-core --target tmp/
# tar -xvf tmp/alpha_build_core.tar.gz
# rm -rf tmp/

# pip install -i https://test.pypi.org/simple/ alpha-build-git-bash-utils --target tmp/
# tar -xvf tmp/alpha_build_git_bash_utils.tar.gz
# rm -rf tmp/
