#!/bin/bash

# Constant values 
readonly URL=https://hub.docker.com
readonly VERSION=v2

# default value for --include-private commandline arguement variable 
visibility="false"
# default valut for curl responsefault valut for curl response
size_of_page=1000

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
 # Loop to iterate on the number of repositories in every page
  for (( repo_page=1;;repo_page++ ));
  do
    # Fetch the repositories in a single page 	  
    res=$(curl -s "${URL}/${VERSION}/repositories/${src}/?page=${repo_page}&page_size=${size_of_page}")
    # fetch the iteration required for pages
    nxt=$(echo ${res} | jq '.next')
    # Fetch name and visibility of the source repository    
    result=$(echo ${res} | jq '.results[]|"\(.name)=\(.is_private)"')
    # Loop over the number of repositories in source organization 
    for i  in ${result}
    do
      # Fetch the name of the repository
      name=$(echo ${i} | sed -e 's/\"//g' -e 's/=.*//')
      # If condition to check whether the repository is to be skipped
      if [[ ! "${skip_repos[@]}" =~ "${name}" ]]; then
        # Fetch the repository privacy whether public/private repository    
        repo_visibility=$(echo $i | sed -e 's/\"//g' -e 's/.*=//g')
        # Fetch the image tags for the repos
	for (( tag_page=1;;tag_page++ ));
	do
          # Get the tags in a page		
	  tags=$(curl -s "${URL}/${VERSION}/repositories/${src}/${name}/tags/?page=${tag_page}&page_size=${size_of_page}")
	  # Get the name of the tags for a repositories
	  image_tags=$(echo ${tags} | jq -r '.results|.[]|.name')
	  # Check whether the response has the next parameter set
          tag_next=$(echo ${tags} | jq '.next')	
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
              docker push ${dest}/${name}:${tag}
              echo "Push successful for ${name}:${tag}"
            else
              # If repo is a private repository, skip the execution   
              continue
	    fi
          done
	   # Check if the tag_next is null or not for tags
	   if [[ ! "${tag_next}" = "null" ]]; then 
             # If the tag_next is not null continue looping
             continue
	   else
		   
	     break
	   fi
	done
      else
        # Skip current repository being added in skip_repos variable
        continue
      fi
 
    done
    # Check if the nxt is null or not for repositories
    if [[ ! "${nxt}" = "null" ]]; then
    # if variable nxt is not null continue looping  
     continue
    else
          break
    fi

done
}

# Calling main() function to start execution
main
