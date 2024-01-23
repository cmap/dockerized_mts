#!/bin/bash
MAIN_BRANCH="master"
DEVELOP_BRANCH="develop"

# Define the function to get_changes() here
get_changes() {
    local changes
    changes=$(git log --oneline --no-merges ${MAIN_BRANCH}..${DEVELOP_BRANCH} -- "$1")
    echo -n "$changes"  # Preserve newline characters
}

rm changes.txt
touch changes.txt

# Iterate through each folder in the current directory
for folder in */; do
    folder="${folder%/}"  # Remove trailing slash
    if [ -d "$folder" ]; then
        CHANGES=$(get_changes "$folder")
        if [[ ! -z "$CHANGES" ]]; then
          echo "$folder" >> changes.txt
          echo -e "$CHANGES" >> changes.txt
          echo "" >> changes.txt
          echo "" >> changes.txt
        fi
    fi
done
