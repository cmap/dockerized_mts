#!/bin/bash

# Loop through arguments and assign them to environment variables
# Arguments are expected to be in the form of '--key value'
# For example, '--data-dir /data'
for ((i = 1; i <= $#; i++)); do
    # Get the key and value
    key=${!i}
    if [[ $key == --* ]]; then
        # Remove leading '--' and replace '-' with '_' for the environment variable name
        env_var=${key/--/}
        env_var=$(echo $env_var | tr '-' '_' | tr '[:lower:]' '[:upper:]')

        # Get the value which is the next argument
        let "i++"
        value=${!i}

        # Assign the value to the environment variable
        export $env_var="$value"
    fi
done



source activate prism
# Rest of the script
args=("$@")
echo python /clue/bin/remove_data.py  "${args[@]}"
python /clue/bin/remove_data.py  "${args[@]}"

exit_code=$?
echo "$exit_code"
exit $exit_code
