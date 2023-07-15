#!/bin/bash

# shellcheck disable=SC2063
__main() {
    local _hy=$'\e[1;93m' _g=$'\e[32m' _y=$'\e[33m' _be=$'\e[34m' _w=$'\e[97m' _f=$'\e[m'
    read -r -p "Enter project name (${_hy}[${_g}a${_y}-${_g}z0${_y}-${_g}9_${_hy}]${_be}+${_f}): " pname
    read -r -p "Enter github repo owner (${_hy}[${_g}a${_y}-${_g}z0${_y}-${_g}9_-${_hy}]${_be}+${_f}): " powner
    read -r -p "Enter project description (${_w}.${_be}*${_f}): " pdesc

    find . -type f -not \( -path ./.\*/\* -or -name init.sh \) -print0 | \
      xargs -0n1 \
      sed -i -E \
        -e "s/[*]PROJECT_NAME/$pname/g" \
        -e "s/[*]PROJECT_DESCRIPTION/$pdesc/g" \
        -e "s/[*]PROJECT_URL/https:\/\/github.com\/$powner\/$pname/g" \
        -e "s/[*]CYR/$(date +%Y)/g"

    mv -v PROJECT_NAME "$pname"
}

__main "$@"
