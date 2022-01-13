SHELL=/bin/bash
PROJECT_ROOT="$$(cd "$$(dirname "$${BASH_SOURCE[0]}" )" && pwd)"


all:
	make static-analysis


static-analysis:
	pushd "${PROJECT_ROOT}" > /dev/null; \
	source ${PROJECT_ROOT}/common/docker.sh; \
	export PROJECT_ROOT=${PROJECT_ROOT}; \
	exec_ci_container common v1 "./common/static_analysis.sh" || exit 1; \
	popd > /dev/null
