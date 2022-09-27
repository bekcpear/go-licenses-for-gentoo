#!/usr/bin/env bash
#
# @author: cwittlut <i@bitbili.net>
#

_data_dir=${XDG_DATA_HOME:-${HOME:-~}/.local/share}/go-licenses-for-gentoo
_go_cmd="go"
_go_licenses_cmd="go-licenses"
_gentoo_repo="/var/db/repos/gentoo"


#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
set -e
export LC_ALL=C

_do() {
  echo -ne "\x1b[32m\x1b[1m>>> \x1b[0m" >&2
  echo "${@}" >&2
  eval "${@}"
}

_echo() {
  echo -ne "\x1b[32m\x1b[1m===\x1b[0m "
  echo -e "${@}"
}

_warn() {
  echo -ne "\x1b[33m\x1b[1m===\x1b[0m " >&2
  echo -e "${@}" >&2
}

_golic() {
  _data_csv="${_data_dir}/${_date}.csv"
  _data_msg="${_data_dir}/${_date}.msg"

  local _licenses
  _do ${_go_licenses_cmd} report "$@" >>"${_data_csv}" 2> >(tee -a "${_data_msg}" >&2)

  echo
  _echo "CSV: ${_data_csv}"
  _echo "MSG: ${_data_msg}"
  echo
}

_parselic() {
  local _licenses_file="${_data_dir}/${_date}.lic"

  # get last licenses file to compare with now to get the new added licenses
  local _last_licenses_file
  _last_licenses_file=$(ls -v1 "${_data_dir}"/*.lic 2>/dev/null | tail -1 || true)
  local -A _last_licenses
  if [[ -f ${_last_licenses_file} ]]; then
    . "${_data_dir}/$(basename ${_last_licenses_file})"
    for _l in "${_parsed_licenses[@]}" "${_unparsed_licenses[@]}"; do
      _last_licenses["${_l}"]=1
    done
  fi
  local -a _parsed_licenses=()
  local -a _unparsed_licenses=()
  local -i _license_name_max_len=0
  __update_max_len() {
    if [[ ${1} -gt ${_license_name_max_len} ]]; then
      _license_name_max_len=${1}
    fi
  }

  . "$(dirname $(realpath $0))/_extra_licenses_mappings.txt"

  local -a _gentoo_licenses=( $(ls -1 ${_gentoo_repo%/}/licenses/) )
  while read _license; do
    local -a _matches=()
    for _l in "${_gentoo_licenses[@]}"; do
      if [[ ${_l@U} =~ ^${_license@U} ]]; then
        _matches+=( "${_l}" )
      fi
    done
    local _parsed_license=""
    for _l in "${_matches[@]}"; do
      if [[ ${#_parsed_license} -eq 0 ]] || [[ ${#_parsed_license} -gt ${#_l} ]]; then
        _parsed_license="${_l}"
      fi
    done
    if [[ ${#_parsed_license} -gt 0 ]]; then
      _parsed_licenses+=( ${_parsed_license} )
      __update_max_len ${#_parsed_license}
    else
      _parsed_license=${_lic_mappings[${_license}]}
      if [[ ${#_parsed_license} -gt 0 ]]; then
        _parsed_licenses+=( ${_parsed_license} )
        __update_max_len ${#_parsed_license}
      else
        _unparsed_licenses+=( ${_license} )
        __update_max_len ${#_license}
      fi
    fi
  done <<<"$(<"${_data_csv}" cut -d',' -f3 | sort -u)"

  declare -p _parsed_licenses _unparsed_licenses >${_licenses_file}

  local _license_name_placeholder=''
  for (( i=0; i<${_license_name_max_len}; i++ )); do
    _license_name_placeholder+=' '
  done

  local _new_l_string="\x1b[32m*new\x1b[0m"
  local -i _new_flag=0
  __lic_print() {
    for _l in "${@}"; do
      echo -n "${_l}"
      local _new_l=""
      if [[ -z ${_last_licenses[${_l}]} ]]; then
        _new_l=${_new_l_string}
        _new_flag=1
      fi
      echo -e "${_license_name_placeholder:${#_l}} ${_new_l}"
    done
  }
  _echo "Corresponding Gentoo Linux LICENSES names:"
  _echo "\x1b[32m\x1b[1m================================\x1b[0m"
  __lic_print "${_parsed_licenses[@]}"
  _echo "\x1b[32m\x1b[1m================================\x1b[0m"
  if [[ ${_new_flag} -eq 1 ]]; then
    _echo "${_new_l_string} means: compared with the last run, this license has been added."
  fi
  if [[ ${#_unparsed_licenses[@]} -eq 0 ]]; then
    return
  fi
  echo
  _warn "Unparsed LICENSES names:"
  _warn "\x1b[33m\x1b[1m================================\x1b[0m"
  __lic_print "${_unparsed_licenses[@]}"
  _warn "\x1b[33m\x1b[1m================================\x1b[0m"
}

# push to go module directory if provided
if [[ -n ${1} ]] && [[ -d ${1} ]]; then
  _do pushd "${1}" >/dev/null
fi

# cache modules
_do ${_go_cmd} mod download

# get module path and create data path
_module=$(_do ${_go_cmd} list -m -f '{{.Path}}')
_echo "Module: ${_module}"
_data_dir=${_data_dir}/${_module}
[[ -d ${_data_dir} ]] || _do mkdir -p ${_data_dir}

# a start date which used as the filename prefix
_date=$(date '+%s.%Y%m%d.%H-%M-%S%z')

# get licenses
_golic ./...

# parse licenses
_parselic
