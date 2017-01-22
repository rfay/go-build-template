# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

.PHONY: all build test push clean version

# The binary to build (just the basename).
BIN := myapp

# This repo's root import path (under GOPATH).
PKG := github.com/rfay/go-build-template

# Where to push the docker image.
REGISTRY ?= randyfay

# Which architecture to build
ARCH ?= amd64

# OS is darwin unless set on command line
OS ?= darwin

# This version-strategy uses git tags to set the version string
VERSION := $(shell git describe --tags --always --dirty)
#
# This version-strategy uses a manual value to set the version string
#VERSION := 1.2.3

###
### These variables should not need tweaking.
###

SRC_DIRS := cmd pkg # directories which hold app source (not vendored)

# Set default base image dynamically for each arch
ifeq ($(ARCH),amd64)
    BASEIMAGE?=alpine
endif

IMAGE := $(REGISTRY)/$(BIN)

BUILD_IMAGE ?= golang:1.7-alpine

# If you want to build all binaries, see the 'all-build' rule.
# If you want to build all containers, see the 'all-container' rule.
# If you want to build AND push all containers, see the 'all-push' rule.
all: build

build-%:
	$(MAKE) --no-print-directory OS=$* build

build: bin/$(OS)/$(BIN)

bin/$(OS)/$(BIN): build-dirs
	@echo "building: $@"
	@docker run                                                            \
	    -t                                                                \
	    -u $$(id -u):$$(id -g)                                             \
	    -v $$(pwd)/.go:/go                                                 \
	    -v $$(pwd):/go/src/$(PKG)                                          \
	    -v $$(pwd)/bin/$(OS):/go/bin                                     \
	    -v $$(pwd)/bin/$(OS):/go/bin/$(OS)                       \
	    -v $$(pwd)/.go/std/$(OS):/usr/local/go/pkg/$(OS)_$(ARCH)_static  \
	    -e GOOS=linux	\
	    -w /go/src/$(PKG)                                                  \
	    $(BUILD_IMAGE)                                                     \
	    /bin/sh -c "                                                       \
	        OS=$(OS)                                                   \
	        VERSION=$(VERSION)                                             \
	        PKG=$(PKG)                                                     \
	        ./build/build.sh                                               \
	    "

DOTFILE_IMAGE = $(subst /,_,$(IMAGE))-$(VERSION)

container: build-linux .container-$(DOTFILE_IMAGE) container-name

.container-$(DOTFILE_IMAGE): build-linux Dockerfile.in
	@sed \
	    -e 's|ARG_BIN|$(BIN)|g' \
	    -e 's|ARG_OS|linux|g' \
	    -e 's|ARG_FROM|$(BASEIMAGE)|g' \
	    Dockerfile.in > .dockerfile
	@docker build -t $(IMAGE):$(VERSION) -f .dockerfile .
	@docker images -q $(IMAGE):$(VERSION) > $@

container-name:
	@echo "container: $(IMAGE):$(VERSION)"

push: .push-$(DOTFILE_IMAGE) push-name
.push-$(DOTFILE_IMAGE): .container-$(DOTFILE_IMAGE)
	@gcloud docker -- push $(IMAGE):$(VERSION)
	@docker images -q $(IMAGE):$(VERSION) > $@

push-name:
	@echo "pushed: $(IMAGE):$(VERSION)"

version:
	@echo $(VERSION)

test: build-dirs build-linux
	@docker run                                                            \
	    -t                                                                \
	    -u $$(id -u):$$(id -g)                                             \
	    -v $$(pwd)/.go:/go                                                 \
	    -v $$(pwd):/go/src/$(PKG)                                          \
	    -v $$(pwd)/bin/linux:/go/bin                                     \
	    -v $$(pwd)/.go/std/linux:/usr/local/go/pkg/linux_$(ARCH)_static  \
	    -w /go/src/$(PKG)                                                  \
	    -e GOOS=linux	\
	    $(BUILD_IMAGE)                                                     \
	    /bin/sh -c "                                                       \
	        OS=linux                                                   \
	        ./build/test.sh $(SRC_DIRS)                                    \
	    "

build-dirs:
	@mkdir -p bin/$(OS)
	@mkdir -p .go/src/$(PKG) .go/pkg .go/bin .go/std/$(OS)

clean: container-clean bin-clean

container-clean:
	rm -rf .container-* .dockerfile* .push-*

bin-clean:
	rm -rf .go bin
