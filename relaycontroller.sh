#!/bin/bash

#title          :Relaycontroller.sh
#description    :This Script allows to controll a relay by a RPI GPIO pin.
#author         :Fabian Hartmann
#date           :2018-11-29
#version        :0.1
#usage          :./Relaycontroller.sh
#notes          :
#bash_version   :
#============================================================================



#============================================================================
### Revision History:
##
##	Date	      Version			Personnel			    Notes
##	----	      -------			----------------	-----
##	2018-11-29	  0.1			  Fabian Hartmann   Script created
##
#============================================================================
#
SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

# Name of the Log File
logfilename="$SCRIPT_NAME.log"
# Log to a File if true
logtofile="false"

function mylogger() {
  logtext="${@}"
  if [[ -w /var/log/ ]]; then
    logpath="/var/log/"
  else
    logpath="/Users/$loggedInUser/Library/Logs/"
  fi
  logfile=$logpath$logfilename
  echo $logtext
  if [[ $logtofile == "true" ]]; then
    echo $(date "+%b %e %H:%M:%S") $SCRIPT_NAME[]: $logtext >> $logfile
    logger -is -t $SCRIPT_NAME "$logtext"
  fi
}
# specifies the pin.
gpiopin=$2
# specifies what should be done
function=$1

function init() {
  for i in `seq 1 3`; do
    if [[ ! -d /sys/class/gpio/gpio$1 ]]; then
      echo "$1" > /sys/class/gpio/export
      echo "GPIO PIN: $1 - initialized."
    else
      echo "GPIO PIN: $1 - is already initialized."
    fi
    sleep 0.25
    if [[ -f /sys/class/gpio/gpio$1/direction ]]; then
      if [[ $( cat /sys/class/gpio/gpio$1/direction ) == "out" ]]; then
        echo "GPIO PIN: $1 - is already configured as output."
      else
        echo "out" > /sys/class/gpio/gpio$1/direction
        echo "GPIO PIN: $1 - is configured as output."
      fi
    fi
    ret_value=$?
    [ $ret_value -eq 0 ] && return 2
    sleep 0.5
  done
}

function disable() {
  if [[ -d /sys/class/gpio/gpio$1 ]]; then
    echo "$1" > /sys/class/gpio/unexport
    echo "GPIO PIN: $1 - disabled."
  else
    echo "GPIO PIN: $1 - is not enabled."
    exit 1
  fi
}
function on() {
  for i in `seq 1 3`; do
    if [[ -d /sys/class/gpio/gpio$1 ]]; then
      echo "0" > /sys/class/gpio/gpio$1/value
      status $1
      break
    else
      init $1
    fi
  done
}

function off() {
  for i in `seq 1 3`; do
    if [[ -d /sys/class/gpio/gpio$1 ]]; then
      echo "1" > /sys/class/gpio/gpio$1/value
      status $1
      break
    else
      init $1
    fi
  done

}

function status() {
  for i in `seq 1 3`; do
    if [[ -d /sys/class/gpio/gpio$1 ]]; then
      statusvalue=$(cat /sys/class/gpio/gpio$1/value)
      if [[ $statusvalue = 1 ]]; then
        # Because I use the homebridge-script2 plugin, I have to return a simple value back.
        #echo "GPIO PIN: $1 - Value is set to: OFF"
        echo "OFF"
      else
        #echo "GPIO PIN: $1 - Value is set to: ON"
        echo "ON"
      fi
      break
    else
      init $1
    fi
    sleep 0.5
  done

}


case $function in
  on )
    on $gpiopin
    ;;
  off )
    off $gpiopin
    ;;
  status )
    status $gpiopin
    ;;
  disable )
    disable $gpiopin
    ;;
  * )
    init $gpiopin
    ;;
esac
