#!/usr/bin/env bash

# node modules may contain incompaitble binaries accross platforms so ignore host copy

move_modules() {
    if [ -d /node_modules ]; then
        if [ -d "/usr/app/node_modules" ]; then
            mv "/usr/app/node_modules" "/usr/app/node_modules.local"
        fi
        ln -s /node_modules /usr/app/node_modules
    fi
}

restore_modules() {
    if [ -d /node_modules ] && [ -L "/usr/app/node_modules" ] ; then
        rm node_modules
        if [ -d "/usr/app/node_modules.local" ]; then
            mv "/usr/app/node_modules.local" "/usr/app/node_modules"
        fi
    fi
}
