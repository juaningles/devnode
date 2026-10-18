NAME := devnode

REPO ?= juaningles
DEFAULT_TAG ?= full
DEFAUL_WSL_TAG ?= noble
DOCKER ?= docker

# FLATTEN=1 builds the Dockerfile's `flat` stage: one squashed layer, so files replaced
# by apt upgrade or removed via ubuntu_installs/strip.list no longer take space.
# Off by default: flat images share no base layer, so every rebuild is a full push/pull.
FLATTEN ?=
BUILD_TARGET = $(if $(FLATTEN),--target flat)

# Vulnerability scanning (Trivy runs as a container; no host install needed)
TRIVY_IMAGE ?= aquasec/trivy:latest
TRIVY_SEVERITY ?= HIGH,CRITICAL
TRIVY_EXIT_CODE ?= 0
TRIVY_SCANNERS ?= vuln,secret
DOCKER_SOCK ?= /var/run/docker.sock
TRIVY = $(DOCKER) run --rm \
	-v $(DOCKER_SOCK):/var/run/docker.sock \
	-v trivy-cache:/root/.cache/trivy \
	-v $(CURDIR):/work -w /work \
	$(TRIVY_IMAGE)

.PHONY: evaluate eval-clean scan scan-all lint-dockerfiles all name info2 build info cloud-build clean clean-adaar docker-deps git-deps tag-all refresh quickview cves recommendations docker-deps $(DIR_SOURCES) $(SUB_DIRS)

all: build

UBUNTU_IMAGES=jammy mantic noble lunar resolute
ALPINE_IMAGES=alpine
FULL_IMAGES=full full-resolute full-noble
ALL_IMAGES= $(UBUNTU_IMAGES) $(ALPINE_IMAGES) $(FULL_IMAGES)


info:
# @echo $(DIR_SOURCES)
# @echo $(SUB_SOURCES)
# @echo $(SUB_DIRS)
	@echo NAME=$(NAME)
	@echo REPO=$(REPO)
	@echo DEFAULT_TAG=$(DEFAULT_TAG)
	@echo DOCKER=$(DOCKER)


info2:
	@echo "Original Sub Sources: $(SUB_SOURCES)"
	@echo "Sub Directories: $(SUB_DIRS)"

$(UBUNTU_IMAGES):
	echo Building $@
	$(DOCKER) build $(BUILD_TARGET) -t devnode:$@ -f Dockerfile.ubuntu --build-arg=VERSION=$@  .

$(ALPINE_IMAGES):
	echo Building $@
	$(DOCKER) build -t devnode:$@ -f Dockerfile.alpine --build-arg=VERSION=$@  .

$(FULL_IMAGES):
	echo Building $@
	$(DOCKER) build $(BUILD_TARGET) -t devnode:$@ -f Dockerfile.$@   .

build: $(DEFAULT_TAG)

# make scan                -> scan devnode:$(DEFAULT_TAG)
# make scan-noble          -> scan devnode:noble
# make build-scan-noble    -> build then scan; fails on findings
# make scan-all            -> scan every image in ALL_IMAGES
scan: scan-$(DEFAULT_TAG)

scan-%:
	$(TRIVY) image --scanners $(TRIVY_SCANNERS) --severity $(TRIVY_SEVERITY) \
		--ignore-unfixed --exit-code $(TRIVY_EXIT_CODE) devnode:$*

build-scan-%: %
	$(MAKE) scan-$* TRIVY_EXIT_CODE=1

scan-all: $(addprefix scan-,$(ALL_IMAGES))

scan-report-%:
	mkdir -p reports
	$(TRIVY) image --scanners $(TRIVY_SCANNERS) --format json \
		--output reports/devnode-$*.json devnode:$*
	$(TRIVY) image --format cyclonedx --output reports/devnode-$*.sbom.json devnode:$*

# make evaluate -> build the base images from the *current* registry bases, scan them,
# compare, and recommend which one Dockerfile.full should use. Reports land in reports/.
# Bases are pinned by digest (ubuntu:<t>@sha256:...) so the locally cached ubuntu:<t>
# tags are never pulled over, and results are tagged $(EVAL_REPO):<t> so devnode:<t>
# is untouched. `make eval-clean` removes the evaluation images.
EVAL_IMAGES ?= noble resolute
EVAL_REPO ?= devnode-eval

eval-build-%:
	mkdir -p reports
	DIGEST=$$(docker buildx imagetools inspect ubuntu:$* --format '{{json .Manifest.Digest}}' | tr -d '"') \
		&& test -n "$$DIGEST" \
		&& echo "ubuntu:$*@$$DIGEST" > reports/eval-$*.base \
		&& $(DOCKER) build $(BUILD_TARGET) -t $(EVAL_REPO):$* -f Dockerfile.ubuntu --build-arg=VERSION=$*@$$DIGEST .

evaluate: $(addprefix eval-build-,$(EVAL_IMAGES))
	for t in $(EVAL_IMAGES); do \
		$(TRIVY) image --scanners vuln --format json --output reports/eval-$$t.json $(EVAL_REPO):$$t || exit 1; \
	done
	DOCKER=$(DOCKER) EVAL_REPO=$(EVAL_REPO) python3 scripts/evaluate_scans.py \
		$(foreach t,$(EVAL_IMAGES),reports/eval-$(t).json) | tee reports/evaluate.txt

eval-clean:
	-$(DOCKER) rmi $(addprefix $(EVAL_REPO):,$(EVAL_IMAGES))

lint-dockerfiles:
	for f in Dockerfile*; do \
		echo "== $$f"; \
		$(TRIVY) config --severity $(TRIVY_SEVERITY) $$f || exit 1; \
	done

tag-all:

push-all:

test-trivy:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/install_trivy.sh ; trivy --version"

test-installed-trivy:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "trivy --version"

test-azcli:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/install_azcli.sh ; az --version"

test-installed-azcli:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "az --version"

test-databricks:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/install_databricks.sh ; databricks --version"

test-installed-databricks:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "databricks --version"

test-odbc:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/install_odbc.sh ; /opt/mssql-tools18/bin/sqlcmd -? | head -n 3"

test-installed-odbc:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "/opt/mssql-tools18/bin/sqlcmd -? | head -n 3"

test-$(DOCKER):
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/install_$(DOCKER).sh ; $(DOCKER) info"

test-installed-$(DOCKER):
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "$(DOCKER) info"

test-netutils:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/install_netutils.sh ; nmap --version"

test-installed-netutils:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "nmap --version"

test-devutils:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/install_devutils.sh ; git --version"

test-installed-devutils:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "git --version"

test-python:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/install_python.sh ; python --version"

test-installed-python:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "python --version"

test-installers: test-databricks test-azcli test-python test-odbc test-trivy
	@echo SUCCESS

test-installed: test-installed-netutils test-installed-devutils test-installed-odbc test-installed-python 
	@echo SUCCESS

runit:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG)

scout:
	docker scout quickview devnode:$(DEFAULT_TAG)

wsl: $(DEFAUL_WSL_TAG)
	echo $@
	docker run -d --name temp_wsl devnode:$(DEFAUL_WSL_TAG) sleep 900
	docker export --output=$(DEFAUL_WSL_TAG).tar  temp_wsl
	docker stop temp_wsl
	docker rm temp_wsl