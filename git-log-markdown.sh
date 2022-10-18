#!/bin/bash
#
# ******************************************************************************
# @file git-log-markdown.sh
# @brief Script which generates a markdown file for git history between two
#        ids including the hitsory of submodules
# ******************************************************************************

#Include '_common.sh'
if [ ${BASH_SOURCE+set} ]; then
	source "$(dirname ${BASH_SOURCE[0]})/_common.sh"
else
	source "$(dirname $0)/_common.sh"
fi

#-------------------------------------------------------------------------------

script_begin "git-log-markdown.sh"

#-------------------------------------------------------------------------------

if [ $# -ne 3 ]; then
	echo "Usage: $0 [from] [to] [output]"
	exit 1
fi

arg_from="$1"
arg_to="$2"
arg_output=$(realpath "$3")

#-------------------------------------------------------------------------------

cd ${CONFIG_GIT_PROJECT_ROOT_PATH}

git_project_name=$(basename ${CONFIG_GIT_PROJECT_ROOT_PATH})
echo "Project ${git_project_name}: ${arg_from} -> ${arg_to}"

echo "# ${git_project_name}" > ${arg_output}

#Log of master
#See https://git-scm.com/docs/pretty-formats
git log ${arg_from}..${arg_to} --pretty=format:"## %h%n%B" >> ${arg_output}
echo "" >> ${arg_output}

#Get list of submodule names
#See https://stackoverflow.com/questions/12641469/list-submodules-in-a-git-repository
submodule_paths=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')
for name in ${submodule_paths}; do
	from_hash=$(git rev-parse ${arg_from}:${name})
	to_hash=$(git rev-parse ${arg_to}:${name})
	
	if [ ${from_hash} == ${to_hash} ]; then
		continue
	fi
	
	echo "Submodule ${name}: ${from_hash} -> ${to_hash}"
	
	#Enter the submodule's directory
	cd ${name}
	
	echo "" >> ${arg_output}
	echo "---" >> ${arg_output}
	echo "# ${name}" >> ${arg_output}
	
	#Get the submodules log
	git log ${from_hash}..${to_hash} --pretty=format:"## %h%n%B" >> ${arg_output}
	
	#Return to project root
	cd ${CONFIG_GIT_PROJECT_ROOT_PATH}
done

#-------------------------------------------------------------------------------

script_exit