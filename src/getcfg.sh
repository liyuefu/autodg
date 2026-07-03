#!/bin/bash
# read parameter from configuration file.
# para1: name of parameter

if [ -z "$1" ]; then
    echo "USAGE: parameter name"
    exit 0
fi

PARANAME="$1"
PARAFILE="$(pwd)/para.cfg"

value=$(gawk -v key="$PARANAME" -F= '
    $0 !~ /^#/ && $0 !~ /^$/ {
        if ($1 == key) {
            print $2
            exit
        }
    }' "$PARAFILE")

# 去掉前后空白（空格、tab、换行）
trimmed_value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

echo "$trimmed_value"

