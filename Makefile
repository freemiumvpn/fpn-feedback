GOPATH:=$(shell go env GOPATH)

# ----- Install -----

.PHONY: install
install:
	go mod download

# ----- Test -----

BUILDENV := CGO_ENABLED=0
TESTFLAGS := -short -cover -v
SERVICE=fpn-feedback

.PHONY: test
test:
	$(BUILDENV) go test $(TESTFLAGS) ./...

# ----- Protos -----
CONTRACTS_DIR=$(shell pwd)/contracts
GENERATED_BUILD_DIR=$(shell pwd)/generated

protos-clean:
	rm -rf $(GENERATED_BUILD_DIR)

protos: protos-clean
	go get github.com/golang/protobuf/protoc-gen-go

	mkdir -p $(GENERATED_BUILD_DIR)/feedback

	# export GO_PATH=~/go
	# export PATH=$PATH:/$GO_PATH/bin

	protoc \
		-I=$(CONTRACTS_DIR)/fpn-contracts/feedback \
		--go_out=$(GENERATED_BUILD_DIR)/feedback \
		$(CONTRACTS_DIR)/fpn-contracts/feedback/*.proto

# ----- Build -----

.PHONY: build
build:
	CGO_ENABLED=0 go build -o $(SERVICE)


.PHONY: dev
dev:
	go run .

# ----- CI -----

DOCKER_REGISTRY=freemiumvpn
DOCKER_CONTAINER_NAME=$(SERVICE)
DOCKER_REPOSITORY=$(DOCKER_REGISTRY)/$(DOCKER_CONTAINER_NAME)
SHA8=$(shell echo $(GITHUB_SHA) | cut -c1-8)

docker-image:
	docker build --rm \
		--build-arg SERVICE=$(SERVICE) \
		--tag $(DOCKER_REPOSITORY):local .
		

ci-docker-auth:
	@echo "${DOCKER_PASSWORD}" | docker login --username "${DOCKER_USERNAME}" --password-stdin

ci-docker-build:
	@docker build --rm \
		--build-arg SERVICE=$(SERVICE) \
		--tag $(DOCKER_REPOSITORY):$(SHA8) \
		--tag $(DOCKER_REPOSITORY):latest .

ci-docker-build-push: ci-docker-build
	@docker push $(DOCKER_REPOSITORY):$(SHA8)
	@docker push $(DOCKER_REPOSITORY):latest
