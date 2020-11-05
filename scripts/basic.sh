#!/usr/bin/env bash

# Tips
NORM="\033[0m"
BOLD="\033[1m"

INFO="$BOLD Info:$NORM"
INPUT="$BOLD =>$NORM"
WARNING="$BOLD\033[33m Warning:$NORM"

SUCCESS="$BOLD\033[32m SUCCESS:$NORM"
ERROR="$BOLD\033[31m Error:$NORM"

info () {
  echo -e "$INFO $1"
}

warning () {
  echo -e "$WARNING $1"
}

success () {
  echo -e "$SUCCESS $1"
}

error () {
  echo -e "$ERROR $1"
  echo ''
  exit
}