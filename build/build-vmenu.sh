#!/bin/bash
if [ -z "$__RUNTIME__" ] ;
then
        if [ -z "$_BUILD" ] ;
        then
          THIS_SCRIPT_ROOT=$(dirname $(readlink -f "$0")) ;
          BUILDCHECK=()
          BUILDCHECK+=( $(readlink -f "${THIS_SCRIPT_ROOT:?}/../../build") ) || true
          BUILDCHECK+=( $(readlink -f "${THIS_SCRIPT_ROOT:?}/../build") )    || true
          BUILDCHECK+=( $(readlink -f "${THIS_SCRIPT_ROOT:?}/build") )       || true
          BUILDCHECK+=( $(readlink -f "${THIS_SCRIPT_ROOT:?}") )             || true
          unset THIS_SCRIPT_ROOT ;
          for cf in "${BUILDCHECK[@]}" ;
          do
            if [ -d "$cf" ] && [ -f "${cf:?}/build-env.sh" ] ;
            then
                _BUILD="$cf"
            fi
          done
        fi
        [[ -z "$_BUILD" ]] && echo "Build folder undefined. Failed." && exit 1
        #-----------------------------------------------------------------------------------------------------------------------------------
        if [ -z "$APPMAIN" ] ;
        then
          APPMAIN="BUILD_VMENU"
          . "$_BUILD/build-env.sh" EXECUTE
        elif [ -z "$__RUNTIME__" ] ;
        then
                echo "Runtime not loaded... I'VE FAILED!"
                exit 1
        fi
        [[ -z "${SOURCE:?}" ]] &&  echo "Source undefined... " && exit 1

        [[ -n "$__INVALID_CONFIG__" ]] && echo "You'll need to run the quick configure before this will work..." && exit 1
fi
####################################################################################################################################
if [ ! -z "$1" ] && [ "$1" == "TEST" ]; then
    echo "TEST WAS A SUCCESS!"
elif [ ! -z "$1" ] && [ "$1" == "EXECUTE" ]; then

    [[ -z "$__RUNTIME__" ]] \
      && printf "\nRuntime not loaded. This script requires Belch Runtime.\n$0...failed.\n\n" \
      && exit 1

    VMENU_ROOT="${SOURCE:?}/vMenu"
    VMENU_FILE="$(${VMENU_ROOT:?}/vmenu-version.sh)"
    VMENU_PKG="vMenu-${VMENU_FILE:?}.zip"
    VMENU="${VMENU_ROOT:?}/${VMENU_PKG:?}"

    if [ -f "${VMENU:?}" ]; then
        if [ -d "${RESOURCES:?}/vMenu" ]; then
            rm -rf "${RESOURCES:?}/vMenu"
        fi
        if [ -f "$GAME/permissions.cfg" ]; then
            rm -f "$GAME/permissions.cfg"
        fi
        unzip "$VMENU" -d "${RESOURCES:?}/vMenu"
        cp -rfT "${VMENU_ROOT:?}/vmenu-permissions.cfg" "${GAME:?}/permissions.cfg"
    else
        echo "ERROR: Could not find the vmenu package."
    fi
else
    echo "This script must be executed by the deployment script"
fi


