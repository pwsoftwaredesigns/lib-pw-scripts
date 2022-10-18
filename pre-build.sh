#!/bin/bash
#
# ******************************************************************************
# @file pre-build.sh
# @brief Firmware versioning script to be executed before the build process
#
# Usage: pre-build.sh ([additional build info string])
#
# ******************************************************************************

#Include '_common.sh'
if [ ${BASH_SOURCE+set} ]; then
	source "$(dirname ${BASH_SOURCE[0]})/_common.sh"
else
	source "$(dirname $0)/_common.sh"
fi

#-------------------------------------------------------------------------------

#-----[ FUNCTION: update_version_header( [path] [major] [minor] [patch] [build] [git commit hash] [git branch name] [build info string] ) ]-----
update_version_header() {
	local _version_header_filepath="$1"
	local _version_major="$2"
	local _version_minor="$3"
	local _version_patch="$4"
	local _version_build="$5"
	local _commit_hash="$6"
	local _git_branch="$7"
	local _build_info="$8"
	local _build_timestamp="$9"
	
    check_and_init_file ${_version_header_filepath} ""
    
	local _version_header_filepath_basename=$(basename "${_version_header_filepath}")
		
	printf "/**${EOL}* @file ${_version_header_filepath_basename}${EOL}" > "${_version_header_filepath}"
	printf "* @note THIS FILE IS AUTO-GENERATED AT BUILD TIME. DO NOT EDIT MANUALLY!${EOL}*/${EOL}${EOL}" >> "${_version_header_filepath}"
	
	printf "#include <array>${EOL}" >> "${_version_header_filepath}"
	printf "#include <cstdint>${EOL}" >> "${_version_header_filepath}"
	printf "${EOL}" >> "${_version_header_filepath}"
	
	printf "namespace version{${EOL}${EOL}" >> "${_version_header_filepath}"
	
		printf "constexpr unsigned int MAJOR = ${_version_major};${EOL}" >> "${_version_header_filepath}"
		printf "constexpr unsigned int MINOR = ${_version_minor};${EOL}" >> "${_version_header_filepath}"
		printf "constexpr unsigned int PATCH = ${_version_patch};${EOL}" >> "${_version_header_filepath}"
		printf "constexpr unsigned int BUILD = ${_version_build};${EOL}" >> "${_version_header_filepath}"
		
		local _commit_hash_array=$(printf %040s "${_commit_hash}" | sed "s/.\{2\}/0x&, /g")
		printf "constexpr std::array<uint8_t, 20> GIT_COMMIT_HASH = {${_commit_hash_array}};${EOL}" >> "${_version_header_filepath}"
		
		printf "constexpr char GIT_COMMIT_HASH_STRING[] = \"${_commit_hash}\";${EOL}" >> "${_version_header_filepath}"
		printf "constexpr char GIT_BRANCH_STRING[] = \"${_git_branch}\";${EOL}" >> "${_version_header_filepath}"
		
		printf "constexpr char BUILD_INFO_STRING[] = \"${_build_info}\";${EOL}" >> "${_version_header_filepath}"
		
		printf "constexpr char BUILD_TIMESTAMP_STRING[] = \"${_build_timestamp}\";${EOL}" >> "${_version_header_filepath}"
		
	printf "${EOL}} //namespace version" >> "${_version_header_filepath}"
}

#-------------------------------------------------------------------------------

script_begin "pre-build.sh"

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

#Verify initialization
check_for_init

#Verify required configuration
testconfig_or_exit "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "version_header_filepath"

#Path to the C++ header file within the project containing the version
#This file should typically not be tracked by git
config_version_header_filepath=$(readconfig "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "version_header_filepath")
config_version_header_filepath="${CONFIG_GIT_PROJECT_ROOT_PATH}/${config_version_header_filepath}"

#-------------------------------------------------------------------------------

current_version=$(readfile "${CONFIG_VERSION_FILEPATH}" "${CONFIG_INITIAL_VERSION}")
splitversion "${current_version}" current_version_major current_version_minor current_version_patch
current_version_build=$(readfile "${CONFIG_BUILD_VERSION_FILEPATH}" "${CONFIG_INITIAL_BUILD_VERSION}")

#If the working tree is "dirty" (uncomitted changes) increment the build version
git_test_uncomitted_changes
if [ $? -ne 0 ]; then

	#Increment build version
	echo "Uncomitted changes, incrementing build version..."
	current_version_build=$((${current_version_build}+1))
	
fi

#Get the hash of the current git commit
git_commit_hash="$(git rev-parse HEAD)"

#Get the name of the current git branch
git_local_branch="$(git rev-parse --abbrev-ref HEAD)"

build_timestamp_string="$(date)"

#-------------------------------------------------------------------------------

echo "Version: ${current_version}"
echo "Build: ${current_version_build}"
echo "Git Commit Hash: ${git_commit_hash}"
echo "Git Branch: ${git_local_branch}"
echo "Timestamp: ${build_timestamp_string}"
echo ""

#-------------------------------------------------------------------------------
	
echo "Updating version header..."
update_version_header "${config_version_header_filepath}" ${current_version_major} ${current_version_minor} ${current_version_patch} ${current_version_build} "${git_commit_hash}" "${git_local_branch}" "${arg_build_info_string}" "${build_timestamp_string}"

#Delete build info file
#The build info file should only exist if a built is successful (i.e., post-build was executed)
rm -f "${CONFIG_BUILD_INFO_FILEPATH}"

#Set build flag
touch "${CONFIG_BUILD_FLAG_FILEPATH}"

#-------------------------------------------------------------------------------

script_exit
