# Managed by makego. DO NOT EDIT.

# Must be set
$(call _assert_var,MAKEGO)
$(call _conditional_include,$(MAKEGO)/base.mk)
$(call _conditional_include,$(MAKEGO)/dep_golangci_lint.mk)
$(call _conditional_include,$(MAKEGO)/dep_go_pr_comment.mk)
# Must be set
$(call _assert_var,GO_MODULE)
$(call _assert_var,GOLANGCI_LINT)
$(call _assert_var,TMP)
$(call _assert_var,OPEN_CMD)

# Settable
GO_BINS ?=
# Settable
GO_TEST_BINS ?=
# Settable
GO_GET_PKGS ?=
# Settable
GO_MOD_VERSION ?= 1.18
# Settable
GO_ALL_REPO_PKGS ?= ./cmd/... ./internal/... ./pkg/...
# Settable
SKIP_GOLANGCI_LINT ?=

# Runtime
GOPKGS ?= $(GO_ALL_REPO_PKGS)
# Runtime
GOLANGCILINTTIMEOUT ?= 3m0s

COVER_HTML := $(TMP)/cover.html
COVER_TXT := $(TMP)/cover.txt
COVER_JSON := $(TMP)/cover.json
COVER_XML := $(TMP)/report.xml

ifdef GONOTESTCACHE
GO_TEST_FLAGS := -count=1
else
GO_TEST_FLAGS :=
endif

.DEFAULT_GOAL := shortall

.PHONY: all
all: ## Run make lint and make test.
	@$(MAKE) lint
	@$(MAKE) test

postupgrade:: all

.PHONY: shortall
shortall: ## Run make shortlint and make shorttest.
	@$(MAKE) shortlint
	@$(MAKE) shorttest

.PHONY: ci
ci:
	@$(MAKE) lint
	@$(MAKE) test

.PHONY: upgradegodeps
upgradegodeps:
	rm -f go.mod go.sum
	go mod init $(GO_MODULE)
	go mod edit -go=$(GO_MOD_VERSION)
ifneq ($(GO_GET_PKGS),)
	go get $(GO_GET_PKGS)
endif
	go get -u -t $(GO_ALL_REPO_PKGS) $(GO_GET_PKGS)
	go mod tidy -v

preupgrade:: upgradegodeps

initmakego:: upgradegodeps

.PHONY: godeps
godeps: deps
	go mod download

.PHONY: gofmtmodtidy
gofmtmodtidy:
	@echo gofmt -s -w ALL_GO_FILES
	@gofmt -s -w $(shell find . -name '*.go')
	go mod tidy -v

postgenerate:: gofmtmodtidy

.PHONY: checknonolint
checknonolint:
	@if grep '//nolint' $(shell find . -name '*.go'); then \
		echo '//nolint directives found, surface ignores in .golangci.yml instead' >&2; \
		exit 1; \
	fi

.PHONY: golangcilint
golangcilint: $(GOLANGCI_LINT)
ifneq ($(SKIP_GOLANGCI_LINT),)
	@echo Skipping golangci-lint...
else
	@echo "${GOBIN}"
	golangci-lint run --timeout $(GOLANGCILINTTIMEOUT)
endif

.PHONY: reportci
reportcoveragegithub: $(GO_COVER_VIEW)
	git fetch origin main
	go-cover-view -ci github-actions -git-diff-base origin/main -report $(COVER_TXT)
	go-junit-report -in $(COVER_JSON) -iocopy -out $(COVER_XML)

.PHONY: postlint
postlint::

.PHONY: postlonglint
postlonglint::

.PHONY: shortlint
shortlint: ## Run all linters but exclude long-running linters.
	@$(MAKE) checknodiffgenerated
	@$(MAKE) golangcilint postlint

.PHONY: lint
lint: ## Run all linters.
	@$(MAKE) shortlint
	@$(MAKE) postlonglint

.PHONY: goprebuild
goprebuild::

.PHONY: gopostbuild
gopostbuild::

.PHONY: gobuild
gobuild::

.PHONY: gorelease
gorelease::

.PHONY: build
build:
	@$(MAKE) gobuild

.PHONY: release
release:
	@$(MAKE) gorelease

.PHONY: pretest
pretest::

.PHONY: test
test: pretest installtest ## Run all go tests.
	go test $(GO_TEST_FLAGS) $(GOPKGS)

.PHONY: testrace
testrace: pretest installtest
	go test -race $(GO_TEST_FLAGS) $(GOPKGS)

.PHONY: shorttest
shorttest: pretest installtest ## Run all go tests but exclude long-running tests.
	go test -test.short $(GO_TEST_FLAGS) $(GOPKGS)

.PHONY: deppkgs
deppkgs:
	@go list -f '{{join .Deps "\n"}}' $(GOPKGS) | xargs go list -f '{{if not .Standard}}{{.ImportPath}}{{end}}'

.PHONY: coverpkgs
coverpkgs:
	@go list $(GOPKGS) | grep -v \/gen\/ | tr '\n' ',' | sed "s/,$$//"

.PHONY: cover
cover: pretest installtest
	@mkdir -p $(dir $(COVER_HTML)) $(dir $(COVER_TXT)) $(dir $(COVER_JSON))
	@rm -f $(COVER_HTML) $(COVER_TXT) $(COVER_JSON)
	go test -race -coverprofile=$(COVER_TXT) -json -v -coverpkg=$(shell GOPKGS=$(GOPKGS) $(MAKE) -s coverpkgs) $(GOPKGS) >> $(COVER_JSON)
	@go tool cover -html=$(COVER_TXT) -o $(COVER_HTML)
	@echo
	@go tool cover -func=$(COVER_TXT) | grep total
	@echo
ifndef COVEROPEN
	@echo $(OPEN_CMD) $(COVER_HTML)
else
	$(OPEN_CMD) $(COVER_HTML)
endif

.PHONY: install
install:: ## Install all go binaries.

define gobinfunc
.PHONY: install$(notdir $(1))
install$(notdir $(1)):
	go install ./$(1)

install:: install$(notdir $(1))
endef

$(foreach gobin,$(sort $(GO_BINS)),$(eval $(call gobinfunc,$(gobin))))
$(foreach gobin,$(sort $(GO_BINS)),$(eval FILE_IGNORES := $(FILE_IGNORES) $(gobin)/$(notdir $(gobin))))

.PHONY: installtest
installtest::

define gotestbinfunc
.PHONY: installtest$(notdir $(1))
installtest$(notdir $(1)):
	go install ./$(1)

installtest:: installtest$(notdir $(1))
endef

$(foreach gobin,$(sort $(GO_TEST_BINS)),$(eval $(call gotestbinfunc,$(gobin))))
$(foreach gobin,$(sort $(GO_TEST_BINS)),$(eval FILE_IGNORES := $(FILE_IGNORES) $(gobin)/$(notdir $(gobin))))
