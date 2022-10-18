#!/bin/bash
#
# ******************************************************************************
# @file release.sh
# @brief Script which creates release notes for a build
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

script_begin "begin-release.sh"

#-------------------------------------------------------------------------------

#Verify that a release is NOT already in progress
if [ -e "${CONFIG_RELEASE_FLAG_FILEPATH}" ]; then
	script_exit_error "Release already in progress"
fi

git_local_branch="$(git_branch_name)"

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

#Verify prerequisates
if [[ "${git_local_branch}" != "${config_develop_branch}" ]]; then
	script_exit_error "Release must occur from the '${config_develop_branch}' branch"
fi

git_test_uncomitted_changes
test_return "Please commit all changes before releasing"

#-------------------------------------------------------------------------------

#Create a record of commits between the last release and now
${script_dir}/git-log-markdown.sh ${config_production_branch} ${config_develop_branch} "${CONFIG_RELEASE_CHANGES_FILEPATH}"
echo "See '${CONFIG_RELEASE_CHANGES_FILEPATH}' for a list of commits since the last release"

#-------------------------------------------------------------------------------

current_version=$(readfile "${CONFIG_VERSION_FILEPATH}" "${CONFIG_INITIAL_VERSION}")
splitversion "${current_version}" current_version_major current_version_minor current_version_patch

echo "Current Version: ${current_version}"

next_version_major=${current_version_major}
next_version_minor=${current_version_minor}
next_version_patch=${current_version_patch}

_ok=0
while [ $_ok -ne 1 ]; do
	read -p "Major [${next_version_major}]: " tmp_version_major
	if [ -z ${tmp_version_major} ]; then
		tmp_version_major=${next_version_major}
	fi
	
	if [ ${tmp_version_major} -eq ${next_version_major} ]; then
		next_version_major=${tmp_version_major}
		_ok=1
	elif [ ${tmp_version_major} -gt ${next_version_major} ]; then
		next_version_major=${tmp_version_major}
		next_version_minor=0
		next_version_patch=0
		_ok=1
	else
		echo "Version must be greater or equal to current"
	fi
done

#If the major version hasn't changed, we need the minor version
if [ ${next_version_major} -eq ${current_version_major} ]; then
	_ok=0
	while [ $_ok -ne 1 ]; do
		read -p "Minor [${next_version_minor}]: " tmp_version_minor
		if [ -z ${tmp_version_minor} ]; then
			tmp_version_minor=${next_version_minor}
		fi
		
		if [ ${tmp_version_minor} -eq ${next_version_minor} ]; then
			next_version_minor=${tmp_version_minor}
			_ok=1
		elif [ ${tmp_version_minor} -gt ${next_version_minor} ]; then
			next_version_minor=${tmp_version_minor}
			next_version_patch=0
			_ok=1
		else
			echo "Version must be greater or equal to current"
		fi
	done
	
	#If the minor version hasn't changed, we need the patch version
	if [ ${next_version_minor} -eq ${current_version_minor} ]; then
		_ok=0
		while [ $_ok -ne 1 ]; do
			read -p "Patch [${next_version_patch}]: " tmp_version_patch
			if [ -z ${tmp_version_patch} ]; then
				tmp_version_patch=${next_version_patch}
			fi
			
			if [ ${tmp_version_patch} -gt ${next_version_patch} ]; then
				next_version_patch=${tmp_version_patch}
				_ok=1
			else
				echo "Version must be greater than ${current_version}"
			fi
		done
	fi
	
fi

joinversion next_version ${next_version_major} ${next_version_minor} ${next_version_patch}

echo "You are releasing version: ${next_version}"
read -p "Is this correct? [yes/no]: " confirm

if [[ ${confirm} != "yes" ]]; then
	script_exit_error "Release cancelled"
fi

#-------------------------------------------------------------------------------

#Create a new release branch
release_branch_name="${config_release_branch_prefix}/${next_version}"
git checkout -b "${release_branch_name}"
test_return "Git checkout failed"

#Update version file
echo "${next_version}" > "${CONFIG_VERSION_FILEPATH}"

#Add placeholder in RELEASE file
release_notes_basename=$(basename "${config_release_notes_filepath}")
tmp_release_notes_filepath="${TMP}/${release_notes_basename}"

printf "%s\n" "# [${next_version}]" > "${tmp_release_notes_filepath}"
printf "%s\n" "${CONFIG_RELEASE_NOTES_MARKER}" >> "${tmp_release_notes_filepath}"
printf "\n%s\n" "## Added" >> "${tmp_release_notes_filepath}"
printf "%s\n" "- [Item 1]" >> "${tmp_release_notes_filepath}"
printf "%s\n" "- [Item ...]" >> "${tmp_release_notes_filepath}"
printf "\n%s\n" "## Removed" >> "${tmp_release_notes_filepath}"
printf "%s\n" "- [Item 1]" >> "${tmp_release_notes_filepath}"
printf "%s\n" "- [Item ...]" >> "${tmp_release_notes_filepath}"
printf "\n%s\n" "## Fixed/Changed" >> "${tmp_release_notes_filepath}"
printf "%s\n" "- [Item 1]" >> "${tmp_release_notes_filepath}"
printf "%s\n" "- [Item ...]" >> "${tmp_release_notes_filepath}"

#Add the previous release notes
if [ -f "${config_release_notes_filepath}" ]; then
	printf "\n%s\n" "---" >> "${tmp_release_notes_filepath}"
	cat "${config_release_notes_filepath}" >> "${tmp_release_notes_filepath}"
fi

#Overwrite release notes
cp "${tmp_release_notes_filepath}" "${config_release_notes_filepath}"

#Commit changes
git add "${CONFIG_VERSION_FILEPATH}"
git add "${config_release_notes_filepath}"
git commit -m "Automatically updated version file and release notes"
test_return "Git commit failed"

#Set release flag
touch "${CONFIG_RELEASE_FLAG_FILEPATH}"

#-------------------------------------------------------------------------------

script_exit