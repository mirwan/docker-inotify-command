#!/bin/bash

#-----------------------------------------------------------------------------------------------------------------------

function ts {
  echo [`date '+%b %d %X'`]
}

#-----------------------------------------------------------------------------------------------------------------------

function process_args {
  # These are intended to be global
  USER_ID=$1
  GROUP_ID=$2
  UMASK=$3

  if [[ ! "$USER_ID" =~ ^[0-9]{1,}$ ]]
  then
    echo "User ID value $USER_ID is not valid. It must be a whole number"
    exit 1
  fi

  if [[ ! "$GROUP_ID" =~ ^[0-9]{1,}$ ]]
  then
    echo "Group ID value $GROUP_ID is not valid. It must be a whole number"
    exit 1
  fi

  if [[ ! "$UMASK" =~ ^0[0-7][0-7][0-7]$ ]]
  then
    echo "The umask value $UMASK is not valid. It must be an octal number such as 0022"
    exit 1
  fi
}

#-----------------------------------------------------------------------------------------------------------------------

function create_user {
  local USER_ID=$1
  local GROUP_ID=$2

  USER="user_${USER_ID}_${GROUP_ID}"
  GROUP="group_${USER_ID}_${GROUP_ID}"

  EXISTANT_USER=$(getent passwd ${USER_ID} | cut -d: -f1)
  if [ -n "${EXISTANT_USER}" ];
  then
    if [ "${EXISTANT_USER}" != "${USER}" ];
    then
      echo "$(ts) A user other than ${USER} already exists with the same UID. Skipping creation of user and group..."
      
    else
      echo "$(ts) User \"$USER\" already exists. Skipping creation of user and group..."
    fi
    USER=${EXISTANT_USER}
    unset GROUP
    return
  fi

  echo "$(ts) Creating user \"$USER\" (ID $USER_ID) and group \"$GROUP\" (ID $GROUP_ID) to run the command..."

  # We could be aliasing this new user to some existing user. I assume that's harmless.
  groupadd -o -g $GROUP_ID $GROUP
  useradd -o -u $USER_ID -r -g $GROUP -d /home/$USER -s /sbin/nologin -c "Docker image user" $USER

  mkdir -p /home/$USER
  chown -R $USER:$GROUP /home/$USER
}

#-----------------------------------------------------------------------------------------------------------------------

process_args "$@"

# Shift off the args so that we can exec $@ below
shift; shift; shift

create_user $USER_ID $GROUP_ID

echo "$(ts) Running command as user \"$USER\"..."
umask $UMASK
exec /usr/bin/setuidgid $USER "$@"
