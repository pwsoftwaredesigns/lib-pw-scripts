#!/bin/bash
#
# ******************************************************************************
# @file export.sh
# @brief Script which "exports" a build binary by copying and renaming it
#        based upon the version
#
# The file is renamed to the following format:
# [file basename]-[major].[minor].[patch]-[build]-[branch name].[file extension]
#
# ******************************************************************************

#Include '_common.sh'
if [ ${BASH_SOURCE+set} ]; then
	source "$(dirname ${BASH_SOURCE[0]})/_common.sh"
	script_dir="$(dirname ${BASH_SOURCE[0]})"
else
	source "$(dirname $0)/_common.sh"
	script_dir="$(dirname $0)"
fi

#-------------------------------------------------------------------------------

#-----[ FUNCTION: filepath_name( [file path] ) ]--------------------------------
filepath_basename() {
	local _filepath="$1"
	local _version="$2"
	
	filepath_basename=`basename "${_filepath}"`

	filepath_name="${filepath_basename%.*}"
	filepath_name=`echo "${filepath_name}" | sed "s/[\/ ]/_/g"`
	
	echo "${filepath_name}_${_version}"
}

#-----[ FUNCTION: script_begin( [file path] [version string] ) ]----------------
rename_file() {
	local _filepath="$1"
	local _version="$2"
	
	
	filepath_basename=`basename "${_filepath}"`

	filepath_name="${filepath_basename%.*}"
	filepath_name=`echo "${filepath_name}" | sed "s/[\/ ]/_/g"`
	filepath_extension="${filepath_basename##*.}"

	output_filename="${filepath_name}_${_version}.${filepath_extension}"
	
	echo "${output_filename}"
}

#-------------------------------------------------------------------------------

script_begin "export.sh"

#-------------------------------------------------------------------------------

#Verify that the correct number of command-line arguments were provided
if [ "$#" -ne 2 ]; then
	script_exit_error "Usage: $0 [binary filepath] [output directory]"
fi

arg_binary_filepath="$1"
arg_output_directory="$2"

#-------------------------------------------------------------------------------

#Ensure that this is a "clean" branch
git_test_uncomitted_changes
test_return "You must commit all changes before exporting a build"

echo "Binary Filepath: '${arg_binary_filepath}'"
echo "Output Directory: '${arg_output_directory}'"

#Check for required files
testfile_or_exit "${arg_binary_filepath}"
testfile_or_exit "${arg_output_directory}"

#Read project configuration
testconfig_or_exit "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "production_branch"
config_production_branch=$(readconfig "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "production_branch")

#Test build info fields
testconfig_or_exit "${CONFIG_BUILD_INFO_FILEPATH}" "major"
testconfig_or_exit "${CONFIG_BUILD_INFO_FILEPATH}" "minor"
testconfig_or_exit "${CONFIG_BUILD_INFO_FILEPATH}" "patch"
testconfig_or_exit "${CONFIG_BUILD_INFO_FILEPATH}" "build"
testconfig_or_exit "${CONFIG_BUILD_INFO_FILEPATH}" "git_branch"
testconfig_or_exit "${CONFIG_BUILD_INFO_FILEPATH}" "git_commit_hash"
testconfig_or_exit "${CONFIG_BUILD_INFO_FILEPATH}" "release_notes_filepath"

#Read build info
build_version_major=$(readconfig "${CONFIG_BUILD_INFO_FILEPATH}" "major")
build_version_minor=$(readconfig "${CONFIG_BUILD_INFO_FILEPATH}" "minor")
build_version_patch=$(readconfig "${CONFIG_BUILD_INFO_FILEPATH}" "patch")
build_git_branch=$(readconfig "${CONFIG_BUILD_INFO_FILEPATH}" "git_branch")
build_git_commit_hash=$(readconfig "${CONFIG_BUILD_INFO_FILEPATH}" "git_commit_hash")
release_notes_filepath=$(readconfig "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "release_notes_filepath")
build_config=$(readconfig "${CONFIG_BUILD_INFO_FILEPATH}" "config")

#Parse/format info
release_notes_filepath="${CONFIG_GIT_PROJECT_ROOT_PATH}/${release_notes_filepath}"
build_git_commit_hash_short=$(echo "${build_git_commit_hash}" | cut -c-8)
build_config_fixed=$(echo ${build_config} | sed 's/[^0-9A-Za-z_\-]/_/g')

#-------------------------------------------------------------------------------

full_version_string="${build_version_major}.${build_version_minor}.${build_version_patch}-${build_git_commit_hash_short}"

#Was this build within the production branch?
#See https://stackoverflow.com/questions/15806448/git-how-to-find-out-on-which-branch-a-tag-is
git branch "${config_production_branch}" --contains "${build_git_branch}" | grep "${config_production_branch}" > /dev/null 2>&1
in_production_branch=$?

if [ ${in_production_branch} -ne 0 ]; then
	#This release is not from the production branch, so tag its name
	full_version_string="${full_version_string}-UNRELEASED"
fi

#-------------------------------------------------------------------------------

output_basename=`filepath_basename "${arg_binary_filepath}" "${full_version_string}"`
output_path="${arg_output_directory}/${output_basename}"

#Create sub-folder for output (if it does not exist)
mkdir -p "${output_path}"

#-------------------------------------------------------------------------------

binary_output_filename=`rename_file "${arg_binary_filepath}" "${full_version_string}-${build_config_fixed}"`
binary_output_filepath="${output_path}/${binary_output_filename}"

#Export the file
cp "${arg_binary_filepath}" "${binary_output_filepath}"

echo "Exported Binary: ${binary_output_filename}"

#-------------------------------------------------------------------------------

notes_output_filename=`rename_file "${release_notes_filepath}" "${full_version_string}"`
notes_output_filepath="${output_path}/${notes_output_filename}"

#If in production branch, export release notes
if [ ${in_production_branch} -eq 0 ]; then
	
	#Copy release notes (if applicable)
	if [ -f "${release_notes_filepath}" ]; then
		if [ ! -f "${notes_output_filename}" ]; then
			#Export the file
			cp "${release_notes_filepath}" "${notes_output_filepath}"
		
			echo "Exported Release Notes: ${notes_output_filename}"
		fi
	fi
	
else
	
	#Only create notes if they don't already exist
	if [ ! -f "${notes_output_filepath}" ]; then
		#Otherwise export git commit history
		${script_dir}/git-log-markdown.sh ${config_production_branch} ${build_git_branch} "${notes_output_filepath}"
		
		echo "Exported Git Log: ${notes_output_filename}"
	fi
	
fi


#-------------------------------------------------------------------------------

script_exit