NAME := devnode

REPO ?= juaningles
DEFAULT_TAG ?= full
DEFAUL_WSL_TAG ?= noble
DOCKER ?= $(DOCKER)

.PHONY: all name info2 build info cloud-build clean clean-adaar docker-deps git-deps tag-all refresh quickview cves recommendations docker-deps $(DIR_SOURCES) $(SUB_DIRS)

all: build

UBUNTU_IMAGES=jammy mantic noble lunar resolute
ALPINE_IMAGES=alpine
FULL_IMAGES=full full-resolute
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
	$(DOCKER) build -t devnode:$@ -f Dockerfile.ubuntu --build-arg=VERSION=$@  .

$(ALPINE_IMAGES):
	echo Building $@
	$(DOCKER) build -t devnode:$@ -f Dockerfile.alpine --build-arg=VERSION=$@  .

$(FULL_IMAGES):
	echo Building $@
	$(DOCKER) build -t devnode:$@ -f Dockerfile.$@   .

build: $(DEFAULT_TAG)

tag-all:

push-all:

test-trivy:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/installers/install_trivy.sh ; trivy --version"

test-installed-trivy:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "trivy --version"

test-azcli:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/installers/install_azcli.sh ; az --version"

test-installed-azcli:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "az --version"

test-databricks:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/installers/install_databricks.sh ; databricks --version"

test-installed-databricks:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "databricks --version"

test-odbc:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/installers/install_odbc.sh ; /opt/mssql-tools18/bin/sqlcmd -? | head -n 3"

test-installed-odbc:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "/opt/mssql-tools18/bin/sqlcmd -? | head -n 3"

test-$(DOCKER):
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/installers/install_$(DOCKER).sh ; $(DOCKER) info"

test-installed-$(DOCKER):
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "$(DOCKER) info"

test-netutils:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/installers/install_netutils.sh ; nmap --version"

test-installed-netutils:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "nmap --version"

test-devutils:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/installers/install_devutils.sh ; git --version"

test-installed-devutils:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "git --version"

test-python:
	$(DOCKER) run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c  "bash /usr/depot/installers/install_python.sh ; python --version"

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