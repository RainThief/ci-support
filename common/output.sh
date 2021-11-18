#!/usr/bin/env bash


exitonfail() {
    if [ "$1" -ne "0" ]
    then
        echo_danger "$2 failed"
        exit 1
    fi
}

warnonfail() {
    if [ "$1" -ne "0" ]
    then
        echo_warning "$2 warning"
    fi
}

echo_colour() {
    colour=$2
    no_colour='\033[0m'
    echo -e "${colour}$1${no_colour}"
}

echo_warning(){
    yellow='\033[0;33;1m'
    echo_colour "$1" "${yellow}"
}

echo_success(){
    green='\033[0;32;1m'
    echo_colour "$1" "${green}"
}

echo_danger(){
    red='\033[0;31;1m'
    echo_colour "$1" "${red}"
}

echo_info(){
  cyan='\033[0;36;1m'
  echo_colour "$1" "${cyan}"
}

echo_await_info(){
    MSG="$1"
    COUNT="${2:-1}"
    echo -e "\033[0;36;1m"
    for _ in $(seq "$COUNT"); do
        echo -e "\e[1A\e[K${MSG} ."
        sleep 0.5
        echo -e "\e[1A\e[K${MSG} .."
        sleep 0.5
        echo -e "\e[1A\e[K${MSG} ..."
        sleep 0.5
    done
    echo -e "\033[0m"
}
