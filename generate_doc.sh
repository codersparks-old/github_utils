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
doc_version=
root_folder=
debug=false
push=false

# The branch that the docs are going to go on.
pages_branch=gh-pages

orig_branch=$(git symbolic-ref --short -q HEAD)

# Lets check that we have a git repo and currently on a branch
if [ -z $orig_branch ]
then
	echo "ERROR: Not on a branch or project is not a git repo"
	eixt 1
fi

function usage {
	echo -e "Usage: $0 [-d] [-f OUT_FOLDER] -r ROOT_FOLDER" 1>&2
	echo -e "Where: " 1>&2
	echo -e "\td	Debug Mode" 1>&2
	echo -e "\tv	Specify the documentation version number" 1>&2
	echo -e "\tr	Root folder (absolute) for the project" 1>&2
	echo -e "\tp	Push documentation to gh-pages branch on github" 1>&2
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

while getopts "v:dpr:" arg
do
	case $arg in
	v)
		if [ -e $OPTARG ]
		then 
			doc_version=
		else
			doc_version="-Ddoc.version=$OPTARG"
		fi
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
	p)
		push=true
		;;
	esac
done

if [ -z $root_folder ]
then
	echo "ERROR: Project root must be supplied" 1>&2
	usage
fi

checkabspath $root_folder

debug "Document version: ${doc_version}"

debug "Changing to root folder: ${root_folder}"
pushd $root_folder >/dev/null

debug "Deleting previously built documentation in ${root_folder}/target"
#rm -rf ${root_folder}/target/*


mvn clean

debug "Generating javadoc using maven"
mvn ${doc_version} javadoc:aggregate

debug "checking out the github pages branch $pages_branch"
git checkout $pages_branch

if [[ ! $? == 0 ]]
then
	echo "ERROR: Could not checkout branch $pages_branch"  >&2
	exit 3
fi

debug "making api directory incase it does not exist"
mkdir -p ${root_folder}/api/

debug "Copying files from target to ${doc_version}"
cp -rf ${root_folder}/target/site/apidocs/* ${root_folder}/api/

debug "Adding all files under api directory"
git add api/* > /dev/null 2>&1

if [[ ! $? == 0 ]]
then
	echo "ERROR: Could not perform git add command" >&2
	exit 3
fi

debug "Committing files"
git commit -m "Updated $(echo $doc_version | cut -d'=' -f2) documentation - $(date)" > /dev/null 2>&1

if [[ ! $? == 0 ]]
then
	echo "ERROR: Could not perform git commit command" >&2
	exit 3
fi

if [ push = true ]
then
	debug "Pushing gh-pages to github"
	git push origin gh-pages
	
	if [[ ! $? == 0 ]]
	then
		echo "ERROR: Could not perform git push command" >&2
		exit 3
	fi
fi

debug "Returning to original directory"
popd

git checkout $orig_branch