#!/bin/bash

# Constant values 
readonly URL=https://hub.docker.com
readonly VERSION=v2

#default value for --include-private commandline arguement variable 
visibility="false"


# Provide help to know the usage of script for execution
help_func()
{
  echo "
  ./org-repo-migrator.sh [OPTIONS] VALUE

  example (using short-args): 
  ./org-repo-migrator.sh -s=\",source-organization\" -d=\"destination-organization\" -sr=\"repo 1 repo 2 ..repo n\" -ip=\"true/false\"

  example (using long-args):
  ./org-repo-migrator.sh -src=\",source-organization\" -dest=\"destination-organization\" --skip-repos=\"repo 1 repo 2 ..repo n\" --include-private=\"true/false\"


  Options:
  -s, --src               Name of the source organization from where the repository needs to be pulled for migration
  -d, --dest              Name of the destination organization where the repository needs to be migrated
  -sr, --skip-repos       List of repos to include for migration, if none is provided results in inclusion of all the repos
  -ip, --include-private  Include private repos ( DEFAULT false )
  "
  exit 0
}

# Get the commandline arguements for source, destination, repositories to skip, include public/private repos
for i in "$@"
do 
  case $i in
  -s=*|--src=*)
  src="${i#*=}"
  ;;
  -d=*|--dest=*)
  dest="${i#*=}"
  ;;
  -sr=*|--skip-repos=*)
  skip_repos="${i#*=}"
  ;;
  -ip=*|--include-private=*)
  visibility="${i#*=}"
  ;;
  esac
  # take an argument and call help_func()
  option="${1}"
  case ${option} in 
  -h|--help)
  help_func
  esac
done

# Function to check whether the src and dest variables are null or either src or dest variable is null
checkEmpty()
{
  # Check whether src and dest are empty	
  if [[ "${src}" = "" ]] && [[ "${dest}" = "" ]]; then
  echo "
  -s/--src and -d/--dest cannot be left blank. Please follow below conditions:
  
  Use -h/--help to know more
  "
  # Check if src is empty
  elif [[ "${src}" = ""  ]]; then
  echo "-s/--src cannot be left blank, please provide a valid source organization name."
  # Check if dest is empty 
  elif [[ "${dest}" = "" ]]; then
  echo "-d/--dest cannot be left blank, please provide a valid destination organization name."
  
  fi
}

# Function to check value for the variables are alphanumeric
checkValue()
{
  # Check if src and dest are not as per alphanumeric pattern
  if [[ ! "${src}" =~ ^[[:alnum:]]+$ ]] && [[ ! "${dest}" =~ ^[[:alnum:]]+$  ]]; then
  echo "
  -s/--source and -d/--destination must be set to alphanumberic value
  example:
  -s/--src=\"example123\" -d/dest=\"example123\" "
  # Check whether source follows alphanumeric pattern
  elif [[ ! "${src}" =~ ^[[:alnum:]]+$  ]]; then
  echo "-s/--source must be alphanumeric"
  # Check whether dest follows alphanumeric pattern 
  elif [[ ! "${dest}" =~ ^[[:alnum:]]+$ ]]; then
  echo "-d/--dest must be alphanumeric"
  
  fi
}

# Initializing function when script execution starts
main()
{
  # Check if src or dest variable is empty and call checkEmpty() function for further checks
  if [[ "${src}" = ""  ]] || [[ "${dest}" = "" ]]; then
  checkEmpty
  exit 1
  # Check src or dest variable is alphanumeric and call checkValue() function for further checks
  elif [[ ! "${src}" =~ ^[[:alnum:]]+$ ]] || [[ ! "${dest}" =~ ^[[:alnum:]]+$ ]]; then
  checkValue
  exit 1
  fi
	
  # Fetch the name  and privacy of the repository in the source organization
  check=$(curl -s ${URL}/${VERSION}/repositories/${src}/?page_size=100 | jq  '.results[]|"\(.name)=\(.is_private)"') > /dev/null
	
  # Loop over the number of repositories in source organization 
  for i  in ${check}
  do
  # Fetch the name of the repository
  name=$(echo ${i} | sed -e 's/\"//g' -e 's/=.*//')

  # If condition to check whether the repository is to be skipped
  if [[ ! "${skip_repos[@]}" =~ "${name}" ]]; then
         
  # Fetch the repository privacy whether public/private repository    
  repo_visibility=$(echo $i | sed -e 's/\"//g' -e 's/.*=//g')
         
  # Fetch the image tags for the repos
  image_tags=$(curl -s ${URL}/${VERSION}/repositories/${src}/${name}/tags/?page_size=100 | jq -r '.results|.[]|.name') > /dev/null 
   
  # Loop to fetch a tag from source org repos and apply to the destination org repos 	   
  for tag in ${image_tags}
  do	
  # Check whether the repo is public/private repository	    
  if [[ "${repo_visibility}" = "${visibility}" ]]; then
  echo "Pulling ${name} with tag ${tag} from source ${src}"
  # Pulling repository from the source organzation    
  docker pull ${src}/${name}:${tag} > /dev/null

  echo "Pulling repository ${name}:${tag} successful" 
  echo "Tagging the repository from ${src}/${name}:${tag} to ${dest}/${name}:${tag}"
  # Tagging a repository with tag to to destination org with tag
  docker tag ${src}/${name}:${tag} ${dest}/${name}:${tag} > /dev/null

  echo "Repository ${name}:${tag} tagged successfully"
  echo "Pushing to ${dest} organization the ${name}:${tag} repository"
  # Pushing the repository to destination org with specific tag
  docker push ${dest}/${name}:${tag} > /dev/null

  echo "Push successful for ${name}:${tag}"
  else
  # If repo is a private repository, skip the execution   
  continue
  fi
  done
  else
  # Skip current repository being added in skip_repos variable
  continue

  fi
  done
}

# Calling main() function to start execution
main
