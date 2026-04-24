# Makefile for syft - fork of anchore/syft

BINARY := syft
GO := go
GOFLAGS ?= -trimpath
LDFLAGS := -ldflags "-s -w"
BUILD_DIR := ./dist
CMD_DIR := ./cmd/syft

# Version information
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "v0.0.0-dev")
GIT_COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

LD_VERSION_FLAGS := -X main.version=$(VERSION) -X main.gitCommit=$(GIT_COMMIT) -X main.buildDate=$(BUILD_DATE)
LDFLAGS := -ldflags "-s -w $(LD_VERSION_FLAGS)"

.DEFAULT_GOAL := build

.PHONY: all
all: clean lint test build

.PHONY: build
build:
	@echo "Building $(BINARY) $(VERSION)..."
	@mkdir -p $(BUILD_DIR)
	$(GO) build $(GOFLAGS) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY) $(CMD_DIR)

.PHONY: install
install:
	@echo "Installing $(BINARY)..."
	$(GO) install $(GOFLAGS) $(LDFLAGS) $(CMD_DIR)

.PHONY: run
run:
	$(GO) run $(CMD_DIR) $(ARGS)

# Use -short to skip slow tests by default; use 'test-full' for the complete suite
.PHONY: test
test:
	@echo "Running unit tests..."
	$(GO) test ./... -v -race -count=1 -short

# Run the full test suite without -short
.PHONY: test-full
test-full:
	@echo "Running full unit tests (no -short)..."
	$(GO) test ./... -v -race -count=1

.PHONY: test-unit
test-unit:
	$(GO) test ./... -v -race -count=1 -short

.PHONY: test-integration
test-integration:
	@echo "Running integration tests..."
	$(GO) test ./... -v -race -count=1 -tags=integration

.PHONY: lint
lint:
	@echo "Running linter..."
	@which golangci-lint > /dev/null 2>&1 || (echo "golangci-lint not found, install via .binny.yaml tools"; exit 1)
	golangci-lint run ./...

.PHONY: fmt
fmt:
	$(GO) fmt ./...

.PHONY: vet
vet:
	$(GO) vet ./...

.PHONY: tidy
tidy:
	$(GO) mod tidy

.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	# Note: skipping 'go clean -cache' here to keep the build cache intact for faster rebuilds

# clean-all also wipes the Go build cache; useful when debugging strange cache issues
.PHONY: clean-all
clean-all: clean
	@echo "Purging Go build cache..."
	$(GO) clean -cache

.PHONY: snapshot
snapshot:
	@echo "Creating snapshot build with goreleaser..."
	@which goreleaser > /dev/null 2>&1 || (echo "goreleaser not found"; exit 1)
	goreleaser release --snapshot --clean --skip=publish

.PHONY: release
release:
	@echo "Creating release with goreleaser..."
	goreleaser release --clean

.PHONY: bootstrap
bootstrap:
	@echo "Bootstrapping tools..."
	@which binny > /dev/null 2>&1 && binny install || go install github.com/anchore/binny@latest
	binny install

.PHONY: show-version
show-version:
	@echo $(VERSION)

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build             - Build the binary"
	@echo "  install           - Install the binary"
	@echo "  test              - Run tests (short mode, skips slow tests)"
	@echo "  test-full         - Run all tests without -short flag"
	@echo "  test-unit         - Run unit tests only"
	@echo "  test-integration  - Run integration tests"
	@echo "  lint              - Run linter"
	@echo "  fmt               - Format code"
	@echo "  tidy              - Tidy go modules"
	@echo "  clean             - Remove build artifacts (keeps Go cache)"
	@echo "  clean-all         - Remove build artifacts AND purge Go build cache"
	@echo "  snapshot          - Create snapshot build via goreleaser"
	@echo "  release           - Create release via goreleaser"
	@echo "  bootstrap         - Install required tools via binny"
	@echo "  show-version      - Print current version"
