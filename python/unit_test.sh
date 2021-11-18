#!/usr/bin/env bash
set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

if pip list | grep alembic >> /dev/null 2>&1 ; then
    # shellcheck source=./python/postgres.sh
    source "$CI_SUPPORT_ROOT/python/postgres.sh"

    # alembic needs config file even though connection is mocked
    export DB_URL=postgresql://user:pass@localhost/dbname
    prepare_connection "postgresql" "db" "localhost" "user" "pass"
fi

coverage run -m pytest -o cache_dir=./build/.pytest_cache
exitonfail $? "Unit tests"

coverage report --fail-under=80 --skip-covered --show-missing --skip-empty
exitonfail $? "Coverage check"

echo_success "Unit tests passed"
