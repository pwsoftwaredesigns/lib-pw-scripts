#!/bin/bash
#
# ******************************************************************************
# @file clean.sh
# @brief Firmware versioning script to clean the project
#
# ******************************************************************************

#Include '_common.sh'
if [ ${BASH_SOURCE+set} ]; then
	source "$(dirname ${BASH_SOURCE[0]})/_common.sh"
else
	source "$(dirname $0)/_common.sh"
fi

#-------------------------------------------------------------------------------

script_begin "clean.sh"

#-------------------------------------------------------------------------------

#Verify initialization
check_for_init

#Path to the C++ header file within the project containing the version
#This file should typically not be tracked by git
config_version_header_filepath=$(readconfig "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "version_header_filepath")

#-------------------------------------------------------------------------------

echo "Deleting files..."

#Delete version header
rm -f "${config_version_header_filepath}"

#Delete build information file
rm -f "${CONFIG_BUILD_INFO_FILEPATH}"
	
#-------------------------------------------------------------------------------

script_exit
