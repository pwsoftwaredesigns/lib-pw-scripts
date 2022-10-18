#!/bin/bash
#
# ******************************************************************************
# @file post-build.sh
# @brief Firmware versioning script to be executed after the build process
#        has successfully completed
#
# ******************************************************************************

#Include '_common.sh'
if [ ${BASH_SOURCE+set} ]; then
	source "$(dirname ${BASH_SOURCE[0]})/_common.sh"
else
	source "$(dirname $0)/_common.sh"
fi

#-------------------------------------------------------------------------------

script_begin "post-build.sh"

#-------------------------------------------------------------------------------

#Required argument 1
if [ $# -lt 1 ]; then
	script_exit_error "Usage: $0 [build config string]"
fi
arg_build_config="$1"

#Optional argument 2
arg_build_info_string=""
if [ $# -ge 2 ]; then
	arg_build_info_string="$2"
fi

#-------------------------------------------------------------------------------

#Verify that pre-build has been run
if [ ! -e "${CONFIG_BUILD_FLAG_FILEPATH}" ]; then
	script_exit_error "pre-build.sh must be run first!"
fi
rm "${CONFIG_BUILD_FLAG_FILEPATH}"

#Verify initialization
check_for_init

#-------------------------------------------------------------------------------

current_version=$(readfile "${CONFIG_VERSION_FILEPATH}" "${CONFIG_INITIAL_VERSION}")
splitversion "${current_version}" current_version_major current_version_minor current_version_patch
current_version_build=$(readfile "${CONFIG_BUILD_VERSION_FILEPATH}" "${CONFIG_INITIAL_BUILD_VERSION}")

#If the working tree is "dirty" (uncomitted changes) increment the build version
git_test_uncomitted_changes
if [ $? -ne 0 ]; then
	
	current_version_build=$((${current_version_build}+1))

	#Update the build version file
	printf "${current_version_build}" > "${CONFIG_BUILD_VERSION_FILEPATH}"
	
fi

#Get the hash of the current git commit
git_commit_hash="$(git rev-parse HEAD)"

#Get the name of the current git branch
git_local_branch="$(git_branch_name)"

build_timestamp_string="$(date)"

#-------------------------------------------------------------------------------

echo "Version: ${current_version}"
echo "Build: ${current_version_build}"
echo "Git Commit Hash: ${git_commit_hash}"
echo "Git Branch: ${git_local_branch}"
echo "Timestamp: ${build_timestamp_string}"
echo ""

#-------------------------------------------------------------------------------

#Update build information file
echo "Updating build info..."
writeconfig "${CONFIG_BUILD_INFO_FILEPATH}" "major" "${current_version_major}"
writeconfig "${CONFIG_BUILD_INFO_FILEPATH}" "minor" "${current_version_minor}"
writeconfig "${CONFIG_BUILD_INFO_FILEPATH}" "patch" "${current_version_patch}"
writeconfig "${CONFIG_BUILD_INFO_FILEPATH}" "build" "${current_version_build}"
writeconfig "${CONFIG_BUILD_INFO_FILEPATH}" "git_commit_hash" "${git_commit_hash}"
writeconfig "${CONFIG_BUILD_INFO_FILEPATH}" "git_branch" "${git_local_branch}"
writeconfig "${CONFIG_BUILD_INFO_FILEPATH}" "info" "${arg_build_info_string}"
writeconfig "${CONFIG_BUILD_INFO_FILEPATH}" "config" "${arg_build_config}"
writeconfig "${CONFIG_BUILD_INFO_FILEPATH}" "timestamp" "${build_timestamp_string}"

#-------------------------------------------------------------------------------

script_exit
