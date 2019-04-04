#!/bin/bash

# Filename: build-deploy-mvp2.bash
# Purpose:  MAI Assist deployment script. This script executes on the local
#             deployment server and performs changes on the target AWS server.
# Notes:    This script assumes it's being executed from within the folders
#             created via GIT CLONE - specifically MVP2/utility.
# Created:  March 2019

# - Three Parts
#   -- Setup
#   -- Database
#   -- Node Server

set -o pipefail

###############################################################################

function config_UI() {

  local -r install_dir=${1:-""}

  local -r target_script="${install_dir}/build-node.bash"
  local -r ng_start_script="${install_dir}/angular-start.sh"
  local -r env_filename="${install_dir}/sca_env.bash"
  local -r db_dir="${install_dir}/db"
  local -r db_controller_file="${db_dir}/sca_install_controller.bash"
  local -r target_www_dir="/var/www/html"
  local -r home_foldername=$(grep ^"$USER": /etc/passwd | cut -d ":" -f6)
  local app_dir="${install_dir}/../apps/sca"
  local msg

  app_dir="$(cd "$app_dir" && pwd)"

  local -r ng_config_file="${app_dir}/frontend/src/assets/config.json"

  #############################################################################

  [ -f "$env_filename" ] || { dea_show_err "Cannot find environment file '$env_filename'!" && return 1; }

  # Make sure the file protection is set properly.
  cd "$install_dir" || return $?
  chmod -R 755 ./*  || return $?

  [ -d "$app_dir" ] || { dea_show_err "Cannot find app folder '$app_dir'!" && return 1; }

  [ -d "$db_dir" ]  || { dea_show_err "Cannot find db folder '$db_dir'!" && return 1; }

  if [ ! -x "$db_controller_file" ]; then
    msg="Cannot find database controller file '$db_controller_file', or the file is not executable!"
    dea_show_err "$msg"
    return 1
  fi

  [ -f "$target_script" ]   || { dea_show_err "Cannot find target script file '$target_script'!" && return 1; }

  [ -f "$ng_start_script" ] || { dea_show_err "Cannot find Angular PM2 start file '$ng_start_script'!" && return 1; }

  [ -f "$ng_config_file" ] || { dea_show_err "ng_config_file file '$ng_config_file' cannot be found!" && return 1; }

  # Verify that the config file contains the special string. If it does not, it's probably
  # because it was checked into git using the last developer's local configuration.
  grep -q "REPLACE-ME" "$ng_config_file" || \
    { dea_show_err "ng_config_file file '$ng_config_file' does not contain 'REPLACE-ME'!" && return 1; }

  #############################################################################

  # Define environment variables locally
  source "$env_filename" || return $?

  ## Check to see if environment variables are set
  [ -z "$SCA_PGSCHEMA_OWNER" ]          \
    && { dea_show_err "Environment variable 'SCA_PGSCHEMA_OWNER'          is undefined!" && return 1; }
  [ -z "$SCA_PGSCHEMA_OWNER_PASSWORD" ] \
    && { dea_show_err "Environment variable 'SCA_PGSCHEMA_OWNER_PASSWORD' is undefined!" && return 1; }
  [ -z "$SCA_PGHOST" ]                  \
    && { dea_show_err "Environment variable 'SCA_PGHOST'                  is undefined!" && return 1; }
  [ -z "$SCA_PGPORT" ]                  \
    && { dea_show_err "Environment variable 'SCA_PGPORT'                  is undefined!" && return 1; }
  [ -z "$SCA_PGDATABASE" ]              \
    && { dea_show_err "Environment variable 'SCA_PGDATABASE'              is undefined!" && return 1; }
  [ -z "$AWS_KEY_LOC" ]                 \
    && { dea_show_err "Environment variable 'AWS_KEY_LOC'                 is undefined!" && return 1; }
  [ -z "$EC2_USER" ]                    \
    && { dea_show_err "Environment variable 'EC2_USER'                    is undefined!" && return 1; }
  [ -z "$EC2_URL" ]                     \
    && { dea_show_err "Environment variable 'EC2_URL'                     is undefined!" && return 1; }

  # The '~' character does not always translate properly, so replace with hardcoded path.
  AWS_KEY_LOC="${AWS_KEY_LOC/\~/$home_foldername}"

  # Display variables (for debugging)
  dea_trace_parm "SCA_PGSCHEMA_OWNER"
  # dea_trace_parm "SCA_PGSCHEMA_OWNER_PASSWORD"
  dea_trace_parm "SCA_PGHOST"
  dea_trace_parm "SCA_PGPORT"
  dea_trace_parm "SCA_PGDATABASE"
  dea_trace_parm "AWS_KEY_LOC"
  dea_trace_parm "EC2_USER"
  dea_trace_parm "EC2_URL"
  dea_trace_parm "ng_config_file"

  [ -f "$AWS_KEY_LOC" ] || { dea_show_err "Cannot find AWS PEM file '$AWS_KEY_LOC'!" && return 1; }

  #############################################################################

  # Provision the schema and load the database. This script executes locally
  # but loads data in the target RDS server. This assumes that the local server
  # has Postgres installed?

  dea_trace "Creating Postgres RDS Database Schema (please be patient...)"
  "$db_controller_file" "$install_dir" || return $?

  #############################################################################

  dea_trace "Install the DARTS code here?"

  #############################################################################

  dea_trace "Compiling Angular source code"

  # Compile the Angular source code
  cd "${app_dir}/frontend" || return $?

  # Install yarn and npm on this server, or assume they are here already?
  yarn              || return $?
  npm run buildprod || return $?

  #############################################################################

  dea_trace "Copying compiled Angular code and static Express code"

  # shellcheck disable=SC2087
  ssh -i "$AWS_KEY_LOC" "${EC2_USER}@${EC2_URL}" /bin/bash << EOF
      echo "Making sure that temp folders exist..."
      mkdir -p ~/frontend
      mkdir -p ~/backend
      chmod 755 ~/frontend
      chmod 755 ~/backend

      echo "Making sure that $target_www_dir exists..."
      sudo su -
      mkdir -p ${target_www_dir}/sca/frontend
      mkdir -p ${target_www_dir}/sca/backend
      chmod -R 755 ${target_www_dir}/sca
EOF

  # Copy compiled Angular code to target server
  echo "$(date) Quietly copying frontend files to target server...please wait..."
  scp -qr -i "$AWS_KEY_LOC" "${app_dir}"/frontend/dist/sca/* \
        "${EC2_USER}@${EC2_URL}:~/frontend/" || return $?

  # Copy static Express code to target server
  echo "$(date) Quietly copying backend files to target server...please wait..."
  scp -qr -i "$AWS_KEY_LOC" "${app_dir}"/backend/* \
        "${EC2_USER}@${EC2_URL}:~/backend/" || return $?

  #############################################################################

  dea_trace "Copying deployment scripts to target server"

  scp -i "$AWS_KEY_LOC" "$target_script"   "${EC2_USER}@${EC2_URL}:~" || return $?
  scp -i "$AWS_KEY_LOC" "$ng_start_script" "${EC2_USER}@${EC2_URL}:~" || return $?
  scp -i "$AWS_KEY_LOC" "$env_filename"    "${EC2_USER}@${EC2_URL}:~" || return $?

  #############################################################################

  dea_trace "Executing deployment script on target server"

  # Set the environment variables in non-interactive shell
  # shellcheck disable=SC2087
  ssh -i "$AWS_KEY_LOC" "${EC2_USER}@${EC2_URL}" /bin/bash << EOF
      # These commands are executed as regular user
      cd /home/maintuser
      rm -f ./.bashrc.initial
      cp ./.bashrc ./.bashrc.initial
      cat ./$(basename "$env_filename") >> ./.bashrc
      source ./.bashrc
      env | sort | grep -v PASSWORD | grep -v ^LS_COLORS

      # These commands are executed as root
      sudo su -
      yum install -y wget
      cd /home/maintuser

      ./build-node.bash

      rm -f ./.bashrc
      mv ./.bashrc.initial ./.bashrc
EOF

  return 0
}

###############################################################################

function config_AI() {
  local -r install_dir=${1:-""}

  bash "${install_dir}/analytic.bash" "$install_dir" || return $?

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

main() {
  local -r install_dir="$(pwd)"

  echo -e "\\nCurrently executing '${BASH_SOURCE[0]}' as user '$(whoami)' in '$(pwd)'.\\n"

  {
    echo "BEGIN PROGRAM AT: $(date +"%Y-%m-%d %H:%M:%S")"
    config_UI "$install_dir" || return $?
    config_AI "$install_dir" || return $?
    echo "END PROGRAM AT: $(date +"%Y-%m-%d %H:%M:%S")"
  } | tee -a "$HOME/build-deploy-mvp2.log"

  return $?
}

###############################################################################

echo ""
echo "******** Note: Logging will be written to $HOME/build-deploy-mvp2.log ********"
echo ""

main "$@"
