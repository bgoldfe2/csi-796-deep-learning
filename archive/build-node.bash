#!/bin/bash

# Filename: build-node.bash
# Purpose:  MAI Assist deployment script. This script is scp'd to the
#             target AWS server and executed there.
# Created:  March 2019

set -o pipefail

###############################################################################

function main() {

  local -r env_filename="$DEEAHOME/sca_env.bash"
  local -r target_www_dir="/var/www/html"
  local -r backend_dir="${target_www_dir}/sca/backend"
  local -r frontend_dir="${target_www_dir}/sca/frontend"
  local -r ng_config_file="${frontend_dir}/assets/config.json"
  local msg

  ###############################################################################

  # Set up mandatory environment variables
  [ -f "$env_filename" ] || { dea_show_err "Cannot find environment file '$env_filename'!" && return 1; }
  source "$env_filename" || return $?

  # Verify that mandatory environment variables have been defined
  [ -z "$SCA_EXPRESS_HOST" ]  && { dea_show_err "Environment variable 'SCA_EXPRESS_HOST' is undefined!" && return 1; }
  [ -z "$SCA_EXPRESS_PORT" ]  && { dea_show_err "Environment variable 'SCA_EXPRESS_PORT' is undefined!" && return 1; }

  mkdir -p "$backend_dir"  || return $?
  mkdir -p "$frontend_dir" || return $?

  # Validate local variables exist
  [ -d "$backend_dir" ]  || { dea_show_err "backend_dir folder '$backend_dir' cannot be found!" && return 1; }
  [ -d "$frontend_dir" ] || { dea_show_err "frontend_dir folder '$frontend_dir' cannot be found!" && return 1; }

  # Display variables (for debugging)
  dea_trace_parm "DEEAHOME"
  dea_trace_parm "env_filename"
  dea_trace_parm "SCA_EXPRESS_HOST"
  dea_trace_parm "SCA_EXPRESS_PORT"
  dea_trace_parm "backend_dir"
  dea_trace_parm "frontend_dir"
  dea_trace_parm "ng_config_file"

  ###############################################################################

  dea_trace "Copying web files to $target_www_dir"
  echo "(should delete old backend/frontend folders)"
  cp -r "$DEEAHOME"/backend/*  "$backend_dir"/
  cp -r "$DEEAHOME"/frontend/* "$frontend_dir"/

  [ -f "$ng_config_file" ] || { dea_show_err "ng_config_file file '$ng_config_file' cannot be found!" && return 1; }

  ###############################################################################

  dea_trace "Swapping REPLACE-ME with actual SERVER:PORT"
  grep -q "REPLACE-ME" "$ng_config_file" || \
    { dea_show_err "ng_config_file file '$ng_config_file' does not contain 'REPLACE-ME'!" && return 1; }
  sed -i "s/REPLACE-ME/$SCA_EXPRESS_HOST:$SCA_EXPRESS_PORT/g" "$ng_config_file" || return $?

  ###############################################################################

  dea_trace "Installing nodejs"
  curl -sL https://rpm.nodesource.com/setup_8.x | bash - || return $?
  yum install -y nodejs                                  || return $?

  dea_trace "Installing yarn"
  curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo || return $?
  yum install -y yarn || return $?

  dea_trace "Installing pm2 and http-server"
  # yarn global add @angular/cli@1.7.1 pm2@latest http-server@0.11.1 || return 1
  yarn global add pm2@latest http-server@0.11.1 || return $?

  ###############################################################################

  dea_trace "Installing node dependencies"
  cd "$backend_dir"                           || return $?
  yarn                                        || return $?
  chown -R maintuser:maintuser ./node_modules || return $?

  dea_trace "Initializing pm2"
  # Start the servers using pm2
  cd "$backend_dir"                           || return $?
  pm2 -f start express-start.json             || return $?
  cd "$DEEAHOME"                              || return $?
  # pm2 only handles shell scripts that end with ".sh", so do NOT use ".bash"!
  pm2 -f start angular-start.sh               || return $?

  return 0
}

###############################################################################

function dea_show_err() {
  local -r msg=${1:-""}

  echo "#############################################################"
  echo -e "ERROR: In $BASH_SOURCE: $msg"
  echo "#############################################################"

  return 0
}

###############################################################################

function dea_trace() {
  # TODO: move this to a utility script and source that script here.

  # Print a delimiting message such as:
  # ***********************************************
  # ***** About to do something *******************

  local msg=${1:-""}
  local -r len=100
  local -r stars="$(head -c $len /dev/zero | tr '\0' '*')"
  local -r prefix=${stars:0:5}

  msg="$(date +"%H:%M:%S") $msg"

  # Truncate message if it's too long
  if ((${#msg} >= (len - ${#prefix} - 2))); then
    msg="${msg:0:$((len - ${#prefix} - 6))}..."
  fi

  local -r suffix=${stars:0:$((len - ${#prefix} - ${#msg} - 2))}

  echo -e "\\n$stars"
  echo "$prefix $msg $suffix"

  return 0
}

###############################################################################

function dea_trace_parm() {
  # TODO: move this to a utility script and source that script here.

  # Display a message like "parm_name.......: parm_value" (e.g., "siteid.......: 12345")
  # If $1 is the name of an actual variable, just send $1 and this function will derive
  # the variable's value. If $1 is a label, send the variable's value in as $2.
  # For example:
  #    myvar="xyz"
  #    dea_trace_parm "myvar"
  # or
  #    dea_trace_parm "My label is" "$myvar"

  local -r __parm_name=${1:-""}
  local -r parm_value=${2:-"${!__parm_name}"}

  local dot_count
  local dot_leader=""

  if [ -z "$__parm_name" ]; then
    echo "${FUNCNAME[0]} - received empty parm_name"
    return 0
  fi

  ((dot_count = 20 - ${#__parm_name}))

  # shellcheck disable=SC2046
  [ $dot_count -gt 0 ] && dot_leader=$(printf '%0.s.' $(seq 1 $dot_count))

  echo "   ${__parm_name}${dot_leader}: ${parm_value}"

  return 0
}

###############################################################################

echo -e "\\nCurrently executing '${BASH_SOURCE[0]}' as user '$(whoami)' in '$(pwd)'.\\n"

[ "$(whoami)" == "root" ] || { echo "You must be root to execute this script." && exit 1; }

# TODO: This environment variable should be defined permanently upstream of these scripts,
# and then all subsequent variables are based off of this global variable. It's being
# defined here as a step towards that goal.
DEEAHOME="/home/maintuser"
[ -d "$DEEAHOME" ] || { dea_show_err "DEEAHOME folder '$DEEAHOME' cannot be found!" && exit 1; }

main "$@"
