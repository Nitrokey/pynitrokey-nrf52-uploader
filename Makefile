.PHONY: black build clean publish reinstall

PACKAGE_NAME=pynitrokey-nrf52-uploader
PACKAGE_DIR=pynitrokey_nrf52_uploader
VENV=venv
PYTHON3=python3

BLACK_FLAGS=-t py39
FLAKE8_FLAGS=
ISORT_FLAGS=--py 39

# whitelist of directories for flake8
FLAKE8_DIRS=


# setup development environment
init: update-venv

ARGS=
# ensure this passes before committing
check: lint
	@echo "Note: run semi-clean target in case this fails without any proper reason"
	$(VENV)/bin/python3 -m black $(BLACK_FLAGS) --check $(PACKAGE_DIR)/
	$(VENV)/bin/python3 -m isort $(ISORT_FLAGS) --check-only $(PACKAGE_DIR)/
	@echo All good!

# automatic code fixes
fix: black isort

black:
	$(VENV)/bin/python3 -m black $(BLACK_FLAGS) $(PACKAGE_DIR)/

isort:
	$(VENV)/bin/python3 -m isort $(ISORT_FLAGS) $(PACKAGE_DIR)/

lint:
	$(VENV)/bin/python3 -m flake8 $(FLAKE8_FLAGS) $(FLAKE8_DIRS)
	$(VENV)/bin/python3 -m mypy $(PACKAGE_DIR)

semi-clean:
	rm -rf ./**/__pycache__
	rm -rf ./.mypy_cache

clean: semi-clean
	rm -rf ./$(VENV)
	rm -rf ./dist


# Package management

VERSION_FILE := "$(PACKAGE_DIR)/VERSION"
VERSION := $(shell cat $(VERSION_FILE))

tag:
	git tag -a $(VERSION) -m"v$(VERSION)"
	git push origin $(VERSION)

.PHONY: build-forced
build-forced:
	$(VENV)/bin/python3 -m flit build

build: check
	$(VENV)/bin/python3 -m flit build

publish:
	$(VENV)/bin/python3 -m flit --repository pypi publish

$(VENV):
	$(PYTHON3) -m venv $(VENV)
	$(VENV)/bin/python3 -m pip install -U pip


# re-run if dev or runtime dependencies change,
# or when adding new scripts
update-venv: $(VENV)
	$(VENV)/bin/python3 -m pip install -U pip
	$(VENV)/bin/python3 -m pip install flit
	$(VENV)/bin/python3 -m flit install --symlink

.PHONY: CI
CI:
	env FLIT_ROOT_INSTALL=1 $(MAKE) init VENV=$(VENV)
	env FLIT_ROOT_INSTALL=1 $(MAKE) build-forced VENV=$(VENV)
	$(MAKE) check
	git describe

