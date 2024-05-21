#!/bin/bash

# shellcheck disable=SC2063
__main() {
    local _hy=$'\e[1;93m' _g=$'\e[32m' _y=$'\e[33m' _c=$'\e[36m' _be=$'\e[34m' _w=$'\e[97m' _b=$'\e[1m' _f=$'\e[m'
    local -r RE_PROJECT="${_hy}[${_g}a${_y}-${_g}z0${_y}-${_g}9_${_hy}]$_be+$_f"
    local -r RE_USER="${_hy}[${_g}a${_y}-${_g}z0${_y}-${_g}9_-${_hy}]$_be+$_f"
    local -r RE_KEYWORD="${_hy}[${_g}a${_y}-${_g}z${_hy}]$_f${_hy}[${_g}a${_y}-${_g}z0${_y}-${_g}9_-${_hy}]$_be*$_f"
    local -r RE_ANY="$_w.$_be*$_f"
    function _jb { d=${1-""} ; shift ; f=${1-""} ; shift ; printf %s "$f" "${@/#/$d}" ; }

    read -r -p "[1/9] Project name     (format: $RE_PROJECT)(enter=SKIP): " val_project
    if [[ -z $val_project ]]
    then echo "Substitution skipped"
    else
      local def_user="${GITHUB_USER}"
      [[ -z $def_user ]] && def_user="$(git config --get user.name)"
      [[ -z $def_user ]] && def_user="$(id -nu)"

      read -r -p "[2/9] GitHub username  (format: $RE_USER)(enter=${_c}${def_user@Q}${_f}): " val_user
      read -r -p "[3/9] Project summary  (format: $RE_ANY)(enter=EMPTY): " val_desc
      read -r -p "[4/9] Author fullname  (format: $RE_ANY)(enter=${_c}${def_user@Q}${_f}): " val_author

      local def_email="$(git config --get user.email)"
      read -r -p "[5/9] Author e-mail    (format: $RE_ANY)(enter=${_c}${def_email@Q}${_f}): " val_email

      local -a val_keywords
      function __prompt_keywords {
        printf "[6/9] Project keywords (format: %s)(enter=STOP" "$RE_KEYWORD"
        [[ ${#val_keywords} -gt 0 ]] && printf ", currently $_b%s$_f" "${#val_keywords[*]}"
        printf "): \n"
      }
      while read -r -p "$(__prompt_keywords)" buf_keyword ; do
        [[ -z $buf_keyword ]] && break
        [[ ${val_keywords[*]} =~ $buf_keyword ]] || val_keywords+=("$(tr -dc <<<"$buf_keyword" a-zA-Z0-9_-)")
      done
      # shellcheck disable=SC2086
      local -r quoted_keywords="$(printf \"%s\", ${val_keywords[*]})"

      val_user="${val_user:-$def_user}"
      val_email="${val_email:-$def_email}"

      local -a expr=(
        "s/[*]PROJECT_NAME/$val_project/g;"
        "s/[*]PROJECT_DESCRIPTION/$val_desc/g;"
        "s|[*]PROJECT_URL|https://github.com/$val_user/$val_project|g;"
        "s/[*]AUTHOR_NAME/$val_author/g;"
        "s/[*]AUTHOR_EMAIL/$val_email/g;"
        "s/[*]CYR/$(date +%Y)/g;"
      )
      [[ ${#val_keywords} -gt 0  && $quoted_keywords != "" ]] && \
        expr+=("s/[*]KEYWORDS/${quoted_keywords%,}/;")
      echo "${expr[@]}"
      return
      find . -type f -not \( -path ./.\*/\* -or -name init.sh \) -print0 | \
        tee /dev/stderr 2> >(tr '\0' '\n' | sed -Ee 's/^.+/Processing: &/' >&2 ) | \
        xargs -0n1 sed -i -E "${expr[*]}"

      [[ -d PROJECT_NAME ]] && mv -v PROJECT_NAME "$val_project"

      local mkfile=Makefile
      local mkline0="$(IFS=' ' grep $mkfile -nm1 -Ee '^init:' | cut -f1 -d:)"
      if [[ -n $mkline0 ]] ; then
          # shellcheck disable=SC2086,SC2046
          sed -i $mkfile -Ee $(printf "%sd;" $(( mkline0 - 1 )) $mkline0 $(( mkline0 + 1 )))
          echo "Updated: $mkfile"
      fi
    fi
}

__main "$@"
