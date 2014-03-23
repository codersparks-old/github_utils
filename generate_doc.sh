#!/bin/bash

######################################################
#                                                    #
# Generate Documentation                             #
#                                                    #
# Script that will generate the JAVADOCS for the     #
# project and commit to the gh-pages branch for      #
# display using github pages                         #
#                                                    #
# Exit codes:                                        #
#	1 - Usage error                              #
#	2 - No folder specified and cannot determine #
#		branch name                          #
#	3 - Error checking out branch                #
#                                                    #
######################################################
folder_name=
root_folder=
debug=false

# The branch that the docs are going to go on.
pages_branch=gh-pages

orig_branch=$(git symbolic-ref --short -q HEAD)

# Lets check that we have a git repo and currently on a branch
if [ -z $orig_branch ]
then
	echo "ERROR: Not on a branch or project is not a git repo"
fi

function usage {
	echo -e "Usage: $0 [-d] [-f OUT_FOLDER] -r ROOT_FOLDER" 1>&2
	echo -e "Where: " 1>&2
	echo -e "\td	Debug Mode" 1>&2
	echo -e "\tf	Specify the folder that the documentation will be built to" 1>&2
	echo -e "\tr	Root folder (absolute) for the project" 1>&2
	exit 1
}

function checkabspath { 
	case "$1" in 
		/*)
			
			;; 
		*)
			echo "Root folder must be supplied as absolute path" 1>&2
			usage
			;; 
	esac
}

function debug {
	if [ $debug = true ]
	then
		echo "$1"
	fi
}

while getopts "f:dr:" arg
do
	case $arg in
	f)
		folder_name=$OPTARG
		;;
	d)
		debug=true
		;;
	r)
		root_folder=$OPTARG
		;;
	h)	
		usage
		;;
	esac
done

if [ -z $root_folder ]
then
	echo "ERROR: Project root must be supplied" 1>&2
	usage
fi
checkabspath $root_folder

# We check to see if folder name is still empty
# if it is then we try to get the branch name
if [[ -z $folder_name ]]
then
	folder_name=$orig_branch
fi

# If it is still empty then we error and exit
if [[ -z $folder_name ]] 
then
	echo "ERROR: No folder supplied and cannot determine branch)"
	exit 2
fi

debug "Document Folder name: ${folder_name}"

debug "Changing to root folder: ${root_folder}"
pushd $root_folder >/dev/null

debug "Deleting previously built documentation in ${root_folder}/target"
rm -rf ${root_folder}/target/*

debug "Generating javadoc using maven"
mvn javadoc:aggregate

debug "checking out the github pages branch $pages_branch"
git checkout $pages_branch

if [[ ! $? == 0 ]]
then
	echo "ERROR: Could not checkout branch $pages_branch"
	exit 3
fi

debug "making directory ${root_folder}/api/${folder_name}"
mkdir -p ${root_folder}/api/${folder_name}

debug "Copying files from target to ${folder_name}"
cp -rf ${root_folder}/target/site/apidocs/* ${root_folder}/api/${folder_name}/

debug "Adding all files under api directory"
git add api/*

debug "Committing files"
git commit -m "Updated ${folder_name} documentation"

debug "Pushing gh-pages to github"
git push origin gh-pages

debug "Returning to original directory"
popd