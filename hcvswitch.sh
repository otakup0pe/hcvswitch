#!/usr/bin/env bash

function problems {
    echo "ERROR $1"
    exit 1
}

if [ -z "$HCVSWITCH_CONFIG" ] ; then
    problems "HCVSWITCH_CONFIG is not defined"
fi

HCVSWITCH_CURRENT="${HOME}/.hcvaccount"

function hcv_list {
    grep -e '^#[^ ]' "$HCVSWITCH_CONFIG" | cut -c 2-
}

function hcv_use {
    VAULT="$1"
    if [ -z "$TMPDIR" ] ; then
        T="/tmp/hcvswitch${RANDOM}"
    else
        T="${TMPDIR}/hcvswitch${RANDOM}"
    fi
    grep -A 2 -e "^#${VAULT}$" "$HCVSWITCH_CONFIG" &> "$T"
    if [ $? == 0 ] ; then
        mv "$T" "$HCVSWITCH_CURRENT"
        chmod 0600 "$HCVSWITCH_CURRENT"
    else
        rm -f "$T"
        problems "invalid vault"
    fi
}

function hcv_eval {
    if [ -e "$HCVSWITCH_CURRENT" ] ; then
        VAULT_ADDR="$(tail -n 1 $HCVSWITCH_CURRENT | cut -f 2- -d ':' | sed -e 's! !!g; s!\"!!g')"
        local skip="$(tail -n 2 $HCVSWITCH_CURRENT | cut -f 2 -d ':' | sed -e 's! !!g; s!\"!!g')"
        if [ "$skip" == "true" ] ; then
            VAULT_SKIP_VERIFY=1
        else
            VAULT_SKIP_VERIFY=0
        fi
        echo "export HCV_ENV=$(head -n 1 $HCVSWITCH_CURRENT | cut -f2 -d '#')"
        echo "export VAULT_ADDR=${VAULT_ADDR}"
        echo "export VAULT_SKIP_VERIFY=${VAULT_SKIP_VERIFY}"
    else
        echo "export HCV_ENV=none"
        echo "export VAULT_ADDR=\"\""
    fi
}

if [ $# == 2 ] ; then
    if [ $1 == "use" ] ; then
        hcv_use "$2"
    else
        problems "invalid usage"
    fi
elif [ $# == 1 ] ; then
    if [ $1 == "eval" ] ; then
        hcv_eval
    elif [ $1 == "list" ] ; then
        hcv_list
    else
        problems "invalid usage"
    fi
else
    problems "invalid usage"
fi
