#!/bin/bash
#
# ******************************************************************************
# @file end-release.sh
# @brief Script which creates release notes for a build
# ******************************************************************************

#Include '_common.sh'
if [ ${BASH_SOURCE+set} ]; then
	source "$(dirname ${BASH_SOURCE[0]})/_common.sh"
else
	source "$(dirname $0)/_common.sh"
fi

#-------------------------------------------------------------------------------

script_begin "end-release.sh"

#-------------------------------------------------------------------------------

if [ ! -e "${CONFIG_RELEASE_FLAG_FILEPATH}" ]; then
	script_exit_error "Please run begin-release.sh first!"
fi

#-------------------------------------------------------------------------------

#Parse command line flags
arg_skip_release_notes=0
for arg in "$@"; do
	if [ "${arg}" == "--skip-release-notes" ]; then
		arg_skip_release_notes=1
	fi
done

if [ ${arg_skip_release_notes} -eq 1 ]; then
	echo "NOTE: Skipping release notes"
fi

#-------------------------------------------------------------------------------

git_local_branch="$(git_branch_name)"

git_test_uncomitted_changes
test_return "Please commit all changes before completing this release"

#Verify required configuration values
testconfig_or_exit "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "production_branch"
testconfig_or_exit "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "release_branch_prefix"
testconfig_or_exit "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "develop_branch"
testconfig_or_exit "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "release_notes_filepath"

#Read configuration values
config_production_branch=$(readconfig "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "production_branch")
config_release_branch_prefix=$(readconfig "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "release_branch_prefix")
config_develop_branch=$(readconfig "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "develop_branch")
config_release_notes_filepath=$(readconfig "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "release_notes_filepath")
config_release_notes_filepath="${CONFIG_GIT_PROJECT_ROOT_PATH}/${release_notes_filepath}"

release_version=$(readfile "${CONFIG_VERSION_FILEPATH}" "${CONFIG_INITIAL_VERSION}")
release_branch_name="${config_release_branch_prefix}/${release_version}"

#Verify git
git rev-parse --verify "${config_production_branch}" > /dev/null 2>&1
test_return "Production branch '${config_production_branch}' must exist"

#-------------------------------------------------------------------------------

#Verify
echo "You are about to commit a release for version: ${release_version}"
read -p "Are you sure you wish to proceed? [yes/no]: " confirm

if [[ ${confirm} != "yes" ]]; then
	script_exit_error "Release cancelled"
fi

#-------------------------------------------------------------------------------


#Verify prerequisates
echo "${git_local_branch}" | grep "${config_release_branch_prefix}/" > /dev/null 2>&1
if [ $? -ne 0 ]; then
	script_exit_error "Not in '${config_release_branch_prefix}/*' branch"
fi

#---------------------------------------------------------------------------

#Verify that release notes have been edited
grep "${CONFIG_RELEASE_NOTES_MARKER}" "${config_release_notes_filepath}" > /dev/null 2>&1
if [ $? -eq 0 ]; then 
	script_exit_error "Release notes must be edited before ending this release"
fi
	
if [ ! -f "${CONFIG_END_RELEASE_FLAG_FILEPATH}" ]; then
	touch "${CONFIG_END_RELEASE_FLAG_FILEPATH}"
	
	#Checkout production branch
	git checkout "${config_production_branch}"
	test_return "Git checkout failed"

	#Merge with release branch
	git merge --no-edit "${release_branch_name}"
	test_return "Git merge failed"

	#Add tag to release commit
	git tag "v${release_version}"

	#Checkout development branch
	git checkout "${config_develop_branch}"
	test_return "Git checkout failed"

	#Merge with release branch
	git merge --no-edit "${release_branch_name}"
	test_return "Git merge failed. Check for merge conflicts. Resolve them manually. Re-run this script"
	
	git checkout --recurse-submodules "v${release_version}"
	
fi

#Delete release branch if it exists
git branch -d "${release_branch_name}"
test_return "Unable to delete release branch. Did you fully merge changes back to the development branch?"

#Delete the build version file (because the project version was updated)
rm -f "${CONFIG_BUILD_VERSION_FILEPATH}"

#-------------------------------------------------------------------------------

#Clear the end release flag
rm "${CONFIG_END_RELEASE_FLAG_FILEPATH}"

#Clear release flag
rm "${CONFIG_RELEASE_FLAG_FILEPATH}"

rm -f "${CONFIG_RELEASE_CHANGES_FILEPATH}"

script_exit
