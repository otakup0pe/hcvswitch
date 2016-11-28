# -*-Shell-script-*-

hcvswitch()
{
    local VAULT="$1"
    if [ -z "$VAULT" ] ; then
        echo "invalid vault"
    else
        if [[ "$VAULT" == "none" ]] ; then
            rm "${HOME}/.hcvaccount" &> /dev/null
            eval "$("${HCVSWITCH_PATH}/hcvswitch.sh" eval)"
        else
            if ! grep -e "$VAULT" "$HCVSWITCH_CONFIG" &> /dev/null ; then
                echo "invalid vault"
            else
                "${HCVSWITCH_PATH}/hcvswitch.sh" use "$VAULT" && eval "$("${HCVSWITCH_PATH}/hcvswitch.sh" eval)"
            fi
        fi
    fi
}

hcvlist()
{
    "${HCVSWITCH_PATH}/hcvswitch.sh" list
}

hcvversion()
{
    cat "${HCVSWITCH_PATH}/version"
}
