#!/usr/bin/env bash

# Set up some base constants used by the script
HCVSWITCH_CURRENT="${HOME}/.hcvaccount"
HCV_CONFIGS="7"

problems() {
    echo "ERROR $1"
    exit 1
}

if [ -z "$HCVSWITCH_CONFIG" ] ; then
    problems "HCVSWITCH_CONFIG is not defined"
fi

hcv_list() {
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

hcv_use() {
    VAULT="$1"
    if [ -z "$TMPDIR" ] ; then
        T="/tmp/hcvswitch${RANDOM}"
    else
        T="${TMPDIR}/hcvswitch${RANDOM}"
    fi
    local len="$HCV_CONFIGS"
    grep -A "$len" -e "^#${VAULT}$" "$HCVSWITCH_CONFIG" &> "$T"
    if [ $? == 0 ] ; then
        local done=""
        local count="$len"
        while [ -z "$done" ] ; do
            local val
            val="$(head -n "$count" "$T" | tail -n 1 | cut -c 1)"
            if [ "$val" == "#" ] || [ -z "$val" ]; then
                done="oui"
            else
                count="$((count - 1))"
            fi
        done
        if [ ! -z "$len" ] ; then
            T2="${T}-a"
            head -n "$len" "$T" > "$T2"
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

hcv_conf() {
    local KEY="$1"
    VAL=$(grep -e "$KEY" "$HCVSWITCH_CURRENT" | cut -f "2-" -d ':' | sed -e 's! !!g; s!\"!!g')
    echo "$VAL"
}

hcv_auth() {
    if [ -e "$HCVSWITCH_CURRENT" ] ; then
        local user
        local method
        local code        
        user="$(hcv_conf auth_user)"
        method="$(hcv_conf auth_method)"
        if [ -z "$user" ] || [ -z "$method" ] ; then
            echo "auth config not set"
            return
        fi
        code="$(hcv_conf mfa_code | tr '[:upper:]' '[:lower:]')"
        if [ "$code" == "true" ] ; then
            echo "MFA Code"
            read -r code
            vault auth -method="$method" username="$user" passcode="$code"
        else
            vault auth -method="$method" username="$user"
        fi

    fi
}

hcv_eval() {
    if [ -e "$HCVSWITCH_CURRENT" ] ; then
        local sni
        local skip
        VAULT_ADDR="$(hcv_conf url)"
        skip="$(hcv_conf ignore_ssl | tr '[:upper:]' '[:lower:]')"
        if [ "$skip" == "true" ] ; then
            VAULT_SKIP_VERIFY='1'
            echo "export VAULT_SKIP_VERIFY=${VAULT_SKIP_VERIFY}"
        else
            echo "unset VAULT_SKIP_VERIFY"
        fi
        sni="$(hcv_conf sni)"
        if [ ! -z "$sni" ] && [ "$sni" != "hostname" ] ; then
            echo "export VAULT_TLS_SERVER_NAME=${sni}"
        else
            echo "unset VAULT_TLS_SERVER_NAME"
        fi
        echo "export HCV_ENV=$(head -n 1 "$HCVSWITCH_CURRENT" | cut -f 2 -d '#')"
        echo "export VAULT_ADDR=${VAULT_ADDR}"
    else
        echo "export HCV_ENV=none"
        echo "unset VAULT_ADDR"
        echo "unset VAULT_TLS_SERVER_NAME"
        echo "unset VAULT_SKIP_VERIFY"
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
    elif [ "$1" == "auth" ] ; then
        hcv_auth
    else
        problems "invalid usage"
    fi
else
    problems "invalid usage"
fi
