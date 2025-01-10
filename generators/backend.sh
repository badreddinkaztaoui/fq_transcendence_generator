#!/bin/bash

declare -A VERSIONS=(
    ["django"]="5.0.1"
    ["djangorestframework"]="3.14.0"
    ["psycopg2-binary"]="2.9.9"
    ["redis"]="5.0.1"
    ["gunicorn"]="21.2.0"
    ["django-cors-headers"]="4.3.1"
    ["python-dotenv"]="1.0.0"
    ["channels"]="4.0.0"
    ["channels-redis"]="4.1.0"
    ["daphne"]="4.0.0"
    ["django-oauth-toolkit"]="2.3.0"
    ["djangorestframework-simplejwt"]="5.3.1"
)

declare -A SERVICE_PACKAGES=(
    ["game"]="channels channels-redis daphne"
    ["chat"]="channels channels-redis daphne"
    ["auth"]="django-oauth-toolkit djangorestframework-simplejwt"
)

BASE_PACKAGES="django djangorestframework psycopg2-binary redis gunicorn django-cors-headers python-dotenv"

write_package() {
    local package=$1
    local requirements_file=$2

    echo -e "${package}==${VERSIONS[$package]}" >> "$requirements_file"
}

generate_requirements() {
    local service_name=$1
    local requirements_file=$2

    if [[ -z "$service_name" || -z "$requirements_file" ]]; then
        echo "Error: Missing required parameters"
        echo "Usage: generate_requirements <service_name> <requirements_file>"
        return 1
    fi

    if [[ "$service_name" != "game" && "$service_name" != "chat" && "$service_name" != "auth" ]]; then
        echo "Error: Invalid service name. Must be one of: game, chat, auth"
        return 1
    fi

    local dir_name=$(dirname "$requirements_file")
    if [[ ! -w "$dir_name" ]]; then
        echo "Error: Directory '$dir_name' is not writable"
        return 1
    fi

    > "$requirements_file"

    echo "# Base packages" >> "$requirements_file"
    for package in $BASE_PACKAGES; do
        write_package "$package" "$requirements_file"
    done

    if [[ -n "${SERVICE_PACKAGES[$service_name]}" ]]; then
        echo -e "\n# Service-specific packages" >> "$requirements_file"
        for package in ${SERVICE_PACKAGES[$service_name]}; do
            write_package "$package" "$requirements_file"
        done
    fi

    sort -u -o "$requirements_file" "$requirements_file"

    return 0
}

generate_backend_service()
{
    local service_name=$1
    local service_dir="$BACKEND_DIR/$service_name"

    mkdir -p "$service_dir"
    
    generate_requirements "$service_name" "${service_dir}/requirements.txt"
}