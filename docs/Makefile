# Configurable
SHELL=/bin/bash
CI_SUPPORT_REPO="https://$$GITHUB_TOKEN@github.com/organisation/ci-support.git"
APP_IMAGE_NAME="ghcr.io/organisation/image-name"
CI_BRANCH="master"
CI_DIR_NAME="build/${CI_REPO_NAME}"
GIT_URL=github.com/organisation/app-name.git

# add to local env if wish to use local ci support folder
LOCAL_CI_PATH?=""

# Dynamic (do not touch)
PROJECT_ROOT="$$(cd "$$(dirname "$${BASH_SOURCE[0]}" )" && pwd)"
CI_REPO_NAME="$$(sed -E  's/(.*)\/([a-z0-9-]+)\.git$$/\2/' <<< ${CI_SUPPORT_REPO})"


build: all


prepare:
	if [ "${LOCAL_CI_PATH}" != "" ]; then \
		make prepare-dev; \
	else \
		if [ ! -d "${CI_DIR_NAME}" ]; then \
			git clone "${CI_SUPPORT_REPO}" --depth 1 --branch ${CI_BRANCH} "${CI_DIR_NAME}"; \
		else \
			pushd "${CI_DIR_NAME}" > /dev/null; \
				git reset --hard; \
				git pull origin ${CI_BRANCH}; \
			popd > /dev/null; \
		fi \
	fi


prepare-dev:
	echo "copying local ci folder into project"
	mkdir -p "${CI_DIR_NAME}"; \
	cp -R ${LOCAL_CI_PATH}/* "$$PWD/${CI_DIR_NAME}"


build-docker:
	make prepare
	export CI=${CI}; \
	export PROJECT_ROOT=${PROJECT_ROOT}; \
	export APP_IMAGE_NAME=${APP_IMAGE_NAME}; \
	./${CI_DIR_NAME}/common/build_cycle.sh ${args};


all:
	make audit
	make static-analysis
	make unit-test
	make system-test


audit:
	make prepare
	source ${CI_DIR_NAME}/common/docker.sh; \
	export PROJECT_ROOT=${PROJECT_ROOT}; \
	exec_ci_container python 3.8 "${CI_DIR_NAME}/python/audit.sh";


static-analysis:
	make prepare
	source ${CI_DIR_NAME}/common/docker.sh; \
	export PROJECT_ROOT=${PROJECT_ROOT}; \
	exec_ci_container common v1 "${CI_DIR_NAME}/common/static_analysis.sh"; \
	exec_ci_container python 3.8 "${CI_DIR_NAME}/python/static_analysis.sh";


unit-test:
	make prepare
	source ${CI_DIR_NAME}/common/docker.sh; \
	export PROJECT_ROOT=${PROJECT_ROOT}; \
	exec_ci_container python 3.8 "${CI_DIR_NAME}/python/unit_test.sh" ${args}


system-test:
	make build-docker
	source ${CI_DIR_NAME}/common/docker.sh; \
	export APP_IMAGE_NAME=${APP_IMAGE_NAME}; \
	./scripts/migration_test.sh ${args};


.PHONY: test
test:
	make prepare
	make unit-test
	make system-test


release:
	make prepare
	export CI=${CI}; \
	export GIT_URL=${GIT_URL}; \
	./${CI_DIR_NAME}/common/release.sh;
	make build-docker args="-t"
