#!/bin/bash
set -o nounset
set -o errexit

# Constant values 
readonly URL=https://hub.docker.com
readonly VERSION=v2


# Get the commandline arguements for source, destination, repositories to skip, include public/private repos
for i in "$@"
do
   case $i in
      -s=*|--src=*)
       src="${i#*=}"
       shift
       ;;
      -d=*|--dest=*)
       dest="${i#*=}"
       ;;
      -r=*|--skip-repos=*)
       skip_repos="${i#*=}"
       ;;
      -i=*|--include-private=*)
       visibility="${i#*=}"
       ;;
     esac
 done


## Fetch the name  and privacy of the repository in the source organization
check=$(curl -s ${URL}/${VERSION}/repositories/${src}/?page_size=100 | jq  '.results[]|"\(.name)=\(.is_private)"') > /dev/null

## Loop over the number of repositories in source organization 
for i  in ${check}
do
	## Fetch the name of the repository
	name=$(echo ${i} | sed -e 's/\"//g' -e 's/=.*//')

	## If condition to check whether the repository should be pushed to destination organization
       if [[ ! "${skip_repos[@]}" =~ "${name}" ]]; then
         
	   ## Fetch the repository privacy whether public/private repository    
	   repo_visibility=$(echo $i | sed -e 's/\"//g' -e 's/.*=//g')
         
	   ## Fetch the image tags for the repos
	   image_tags=$(curl -s ${URL}/${VERSION}/repositories/${src}/${name}/tags/?page_size=100 | jq -r '.results|.[]|.name') > /dev/null 
   
   ## Loop to fetch a tag from source org repos and apply to the destination org repos 	   
   for tag in ${image_tags}
   do	
      ## Check whether the repo is public/private repository	    
      if [ "${repo_visibility}" == "${visibility}" ]; then

           echo "Pulling ${name} with tag ${tag} from source ${src}"
 	   ## Pulling repository from the source organzation    
           docker pull ${src}/${name}:${tag} > /dev/null

           echo "Pulling repository ${name}:${tag} successful" 
           echo "Tagging the repository from ${src}/${name}:${tag} to ${dest}/${name}:${tag}"
           ## Tagging a repository with tag to to destination org with tag
           docker tag ${src}/${name}:${tag} ${dest}/${name}:${tag} > /dev/null

           echo "Repository ${name}:${tag} tagged successfully"
           echo "Pushing to ${dest} organization the ${name}:${tag} repository"
           ## Pushing the repository to destination org with specific tag
           docker push ${dest}/${name}:${tag} > /dev/null

           echo "Push successful for ${name}:${tag}"
      else
	   ## If repo is a private repository, skip the execution   
	   continue
      fi
done
  
      else

	  ## Skip current repository being added in skip_repos variable
          continue

      fi
done


