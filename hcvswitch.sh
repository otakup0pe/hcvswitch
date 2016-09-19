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
    grep -A 4 -e "^#${VAULT}$" "$HCVSWITCH_CONFIG" &> "$T"
    if [ $? == 0 ] ; then
        if [ "$(head -n 4 "$T" | tail -n 1 | cut -c 1)" == "#" ] ; then
            LEN=3
        elif [ "$(head -n 5 "$T" | tail -n 1 | cut -c 1)" == "#" ] ; then
            LEN=4
        fi
        if [ ! -z "$LEN" ] ; then
            T2="${T}-a"
            head -n "$LEN" "$T" > "$T2"
            mv "$T2" "$T"
        fi
        if [ -e "${HOME}/.vault-token" ] ; then
            OLD_VAULT="$(head -n 1 "$HCVSWITCH_CURRENT" | cut -c 2-)"
            mv "${HOME}/.vault-token" "${HOME}/.vault-token-${OLD_VAULT}"
        fi
        if [ -e "${HOME}/.vault-token-${VAULT}" ] ; then
            mv "${HOME}/.vault-token-${VAULT}" "${HOME}/.vault-token"
        fi
        mv "$T" "$HCVSWITCH_CURRENT"
        chmod 0600 "$HCVSWITCH_CURRENT"
    else
        rm -f "$T"
        problems "invalid vault"
    fi
}

function hcv_eval {
    if [ -e "$HCVSWITCH_CURRENT" ] ; then
        VAULT_ADDR="$(grep -e 'url' $HCVSWITCH_CURRENT | cut -f 2- -d ':' | sed -e 's! !!g; s!\"!!g')"
        local skip="$(grep -e 'ignore_ssl' $HCVSWITCH_CURRENT | cut -f 2 -d ':' | sed -e 's! !!g; s!\"!!g' | tr '[:upper:]' '[:lower:]')"
        if [ "$skip" == "true" ] ; then
            VAULT_SKIP_VERIFY='1'
        else
            VAULT_SKIP_VERIFY='0'
        fi
        local sni="$(grep -e 'sni' $HCVSWITCH_CURRENT | cut -f 2 -d ':' | sed -e 's! !!g; s!\"!!g')"
        if [ ! -z "$sni" ] && [ "$sni" != "hostname" ] ; then
            VAULT_TLS_SERVER_NAME="$sni"
        else
            VAULT_TLS_SERVER_NAME="$(echo $VAULT_ADDR | awk -F/ '{print $3}')"
        fi
        echo "export HCV_ENV=$(head -n 1 $HCVSWITCH_CURRENT | cut -f2 -d '#')"
        echo "export VAULT_ADDR=${VAULT_ADDR}" ; echo
        echo "export VAULT_SKIP_VERIFY=${VAULT_SKIP_VERIFY}"
        echo "export VAULT_TLS_SERVER_NAME=\"${VAULT_TLS_SERVER_NAME}\""
    else
        echo "export HCV_ENV=none"
        echo "export VAULT_ADDR=\"\""
        echo "export VAULT_TLS_SERVER_NAME=\"\""
    fi
}

if [ $# == 2 ] ; then
    if [ "$1" == "use" ] ; then
        hcv_use "$2"
    else
        problems "invalid usage"
    fi
elif [ $# == 1 ] ; then
    if [ "$1" == "eval" ] ; then
        hcv_eval
    elif [ "$1" == "list" ] ; then
        hcv_list
    else
        problems "invalid usage"
    fi
else
    problems "invalid usage"
fi
