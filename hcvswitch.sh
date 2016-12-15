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
    current=""
    if [ -e "$HCVSWITCH_CURRENT" ] ; then
        current="$(head -n 1 "$HCVSWITCH_CURRENT" | cut -f2 -d '#')"
    fi
    while read -r vault ; do
        if [ "$vault" == "$current" ] ; then
            echo "* ${vault}"
        else
            echo "  ${vault}"
        fi
    done < <(grep -e '^#[^ ]' "$HCVSWITCH_CONFIG" | cut -c 2-)
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
        if [ -e "${HOME}/.vault-token" ] && [ ! -L "${HOME}/.vault-token" ] ; then
            PRE_FILE="${HOME}/.vault-token-pre-install"
            echo "Existing token has been moved to ${PRE_FILE}"
            mv "${HOME}/.vault-token" "$PRE_FILE"
        fi
        if [ -L "${HOME}/.vault-token" ] ; then
            rm "${HOME}/.vault-token"
        fi
        ln -s "${HOME}/.vault-token-${VAULT}" "${HOME}/.vault-token"
        mv "$T" "$HCVSWITCH_CURRENT"
        chmod 0600 "$HCVSWITCH_CURRENT"
    else
        rm -f "$T"
        problems "invalid vault"
    fi
}

function hcv_eval {
    if [ -e "$HCVSWITCH_CURRENT" ] ; then
        local sni
        local skip
        VAULT_ADDR="$(grep -e 'url' "$HCVSWITCH_CURRENT" | cut -f 2- -d ':' | sed -e 's! !!g; s!\"!!g')"
        skip="$(grep -e 'ignore_ssl' "$HCVSWITCH_CURRENT" | cut -f 2 -d ':' | sed -e 's! !!g; s!\"!!g' | tr '[:upper:]' '[:lower:]')"
        if [ "$skip" == "true" ] ; then
            VAULT_SKIP_VERIFY='1'
        else
            VAULT_SKIP_VERIFY='0'
        fi
        sni="$(grep -e 'sni' "$HCVSWITCH_CURRENT" | cut -f 2 -d ':' | sed -e 's! !!g; s!\"!!g')"
        if [ ! -z "$sni" ] && [ "$sni" != "hostname" ] ; then
            VAULT_TLS_SERVER_NAME="$sni"
        else
            VAULT_TLS_SERVER_NAME="$(echo "$VAULT_ADDR" | awk -F/ '{print $3}' | cut -f 1 -d ':')"
        fi
        echo "export HCV_ENV=$(head -n 1 "$HCVSWITCH_CURRENT" | cut -f2 -d '#')"
        echo "export VAULT_ADDR=${VAULT_ADDR}" ; echo
        echo "export VAULT_SKIP_VERIFY=${VAULT_SKIP_VERIFY}"
        echo "export VAULT_TLS_SERVER_NAME=${VAULT_TLS_SERVER_NAME}"
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
