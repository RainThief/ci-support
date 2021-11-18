#!/usr/bin/env bash

set -euo pipefail

parse_db_url() {
    python -c "from sqlalchemy.engine.url import make_url; print(make_url('$DB_URL').$1)"
}

get_db_connection_details_from_env() {
    DB_URL="${DB_URL:-""}"

    # if database url is in env use it but allow cli args to take precedence
    if [ "$DB_URL" != "" ]; then
        DB="$(parse_db_url database)"
        exitonfail $? "parsing database url"
        DB_NAME=${DB_NAME:-"$DB"}
        DB_USERNAME=${DB_USERNAME:-"$(parse_db_url username)"}
        DB_PASSWORD=${DB_PASSWORD:-"$(parse_db_url password)"}
        DB_HOST=${DB_HOST:-"$(parse_db_url host)"}
        DB_DRIVER=${DB_DRIVER:-"$(parse_db_url drivername)"}
        DB_PORT=${DB_PORT:-"$(parse_db_url port)"}
        if [ "$DB_PORT" == "None" ]; then
            DB_PORT="5432"
        fi
    fi
}

# driver dbname user password
prepare_connection(){

    get_db_connection_details_from_env

    if [ "$DB_USERNAME" == "" ] || [ "$DB_PASSWORD" == "" ] || [ "$DB_HOST" == "" ] || [ "$DB_NAME" == "" ] || [ "$DB_DRIVER" = "" ]; then
        usage
    fi

    INI_FILE="$(sed "s/driver/$DB_DRIVER/g" migrations/alembic.ini-dist)"
    INI_FILE="${INI_FILE//dbname/$DB_NAME}"
    INI_FILE="${INI_FILE//localhost/$DB_HOST}"
    INI_FILE="${INI_FILE//user/$DB_USERNAME}"
    INI_FILE="${INI_FILE//pass/$DB_PASSWORD}"
    INI_FILE="${INI_FILE//port/$DB_PORT}"
    echo "$INI_FILE" > './alembic.ini'
}
