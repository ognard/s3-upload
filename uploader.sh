#!/usr/bin/env bash

if [ "${BASH_VERSION%%.*}" -lt 4 ]; then
    echo "This script requires Bash version 4.0 or higher."
        exit 1
fi

source .env

# Set AWS credentials
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

# Bucket and file name argument
bucket_name=$BUCKET_NAME
script_dir=$(dirname "$0")

echo -e "\033[32m
                                                                               
              ████████                       ████                         █████
             ███░░░░███                     ░░███                        ░░███ 
      █████ ░░░    ░███ █████ ████ ████████  ░███   ██████   ██████    ███████ 
     ███░░     ██████░ ░░███ ░███ ░░███░░███ ░███  ███░░███ ░░░░░███  ███░░███ 
    ░░█████   ░░░░░░███ ░███ ░███  ░███ ░███ ░███ ░███ ░███  ███████ ░███ ░███ 
     ░░░░███ ███   ░███ ░███ ░███  ░███ ░███ ░███ ░███ ░███ ███░░███ ░███ ░███ 
     ██████ ░░████████  ░░████████ ░███████  █████░░██████ ░░████████░░████████
    ░░░░░░   ░░░░░░░░    ░░░░░░░░  ░███░░░  ░░░░░  ░░░░░░   ░░░░░░░░  ░░░░░░░░ 
                                   ░███                                     
           https://ognard.com      █████   AWS S3 Multi-File Uploader v1.0           
                                  ░░░░░                                        
            
\033[0m"

print_help() {
    echo -e "\033[32m
    * ------------------------------------------------------------------------ *

         Options:
                            
            -f     Provide files to upload. Multiple files must be placed
                   in double quotes.

            -d     (Optional) Provide directory name that will be created. 
                   Files will be uploaded in the created directory.

            -h     This screen.

    * ------------------------------------------------------------------------ *

         Example: 

                  ./uploader.sh -f \"file1.txt file2.jpg\" -d \"folder_name\"

\033[0m"

}

upload_file() {
    local file_name="$1"
    local directory="$2"

     if [[ -f "$script_dir/$file_name" ]]; then
         if [[ -n "$directory" ]]; then
             s3_path="s3://$bucket_name/$directory/$(basename $file_name)"
         else
             s3_path="s3://$bucket_name/$(basename $file_name)"
         fi

         error_message=$(aws s3 cp "$script_dir/$file_name" "$s3_path" --quiet 2>&1)

         if [[ $? -eq 0 ]]; then
             echo -e ">>> \033[32m[SUCCESS]\033[0m $file_name was uploaded successfully to $s3_path"
         else
             echo -e ">>> \033[31m[ERROR]\033[0m File upload failed!\n\t\t$error_message"
         fi
     else
         echo -e ">>> \033[31m[ERROR]\033[0m File $file_name was not found!"
    fi
}

create_folder() {
    local directory="$1"
    aws s3api put-object --bucket "$bucket_name" --key "$directory/" > /dev/null 2>&1

    if [[ $? -eq 0 ]]; then
        echo -e ">>> \033[32m[SUCCESS]\033[0m Folder '$directory' was created successfully."
    else
        echo -e ">>> \033[31m[ERROR]\033[0m Folder creation failed."
    fi
}

while getopts 'f:d:h' flag; do
    case "${flag}" in
        h)
            print_help
            exit 0
            ;;
        d)  
            directory="${OPTARG}"
            create_folder "$directory"
            ;;
        f)
            files="${OPTARG}"
            ;;
        *)
echo "
    * ------------------------------------------------------------------------ *

        Unknown flag. Use -h to see the available options.

"
            exit 1
            ;;
    esac
done

if [[ -n "$files" ]]; then
    for file_name in $files; do
        upload_file "$file_name" "$directory"
    done
else
    print_help
fi

shift $((OPTIND - 1))

