IMAGE_NAME := instrumentisto/postfix

DOCKERFILE ?= .
VERSION ?= dev

no-cache ?= no


eq = $(if $(or $(1),$(2)),$(and $(findstring $(1),$(2)),\
                                $(findstring $(2),$(1))),1)



# Build Docker image.
#
# Usage:
#	make image [no-cache=(yes|no)] [DOCKERFILE=] [VERSION=]

no-cache-arg = $(if $(call eq,$(no-cache),yes),--no-cache,)

image:
	docker build $(no-cache-arg) -t $(IMAGE_NAME):$(VERSION) $(DOCKERFILE)



# Run tests for Docker image.
#
# Usage:
#	make test [VERSION=]

test: deps.bats
	IMAGE=$(IMAGE_NAME):$(VERSION) ./test/bats/bats test/suite.bats



# Resolve project dependencies for running tests.
#
# Usage:
#	make deps.bats [BATS_VER=]

BATS_VER ?= 0.4.0

deps.bats:
ifeq ($(wildcard $(PWD)/test/bats),)
	mkdir -p $(PWD)/test/bats/vendor
	curl -fL -o $(PWD)/test/bats/vendor/bats.tar.gz \
		https://github.com/sstephenson/bats/archive/v$(BATS_VER).tar.gz
	tar -xzf $(PWD)/test/bats/vendor/bats.tar.gz \
		-C $(PWD)/test/bats/vendor
	rm -f $(PWD)/test/bats/vendor/bats.tar.gz
	ln -s $(PWD)/test/bats/vendor/bats-$(BATS_VER)/libexec/* \
		$(PWD)/test/bats/
endif



.PHONY: image test deps.bats
