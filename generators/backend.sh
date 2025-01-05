#!/bin/bash

generate_requirements()
{
    local service_name=$1
    local requirements_file=$2

    cat > "$requirements_file" << EOL
Django==5.0.1
djangorestframework==3.14.0
psycopg2-binary==2.9.9
redis==5.0.1
gunicorn==21.2.0
django-cors-headers==4.3.1
python-dotenv==1.0.0
EOL

    case "$service_name" in
        "game"|"chat")
            cat >> "$requirements_file" << EOL
channels==4.0.0
channels-redis==4.1.0
daphne==4.0.0
EOL
            ;;
        "auth")
            cat >> "$requirements_file" << EOL
django-oauth-toolkit==2.3.0
djangorestframework-simplejwt==5.3.1
EOL
            ;;
    esac
}

generate_backend_service()
{
    local service_name=$1
    local service_dir="$BACKEND_DIR/$service_name"

    echo -e "\n${BLUE}Creating ${service_name} service...${NC}"

    mkdir -p "$service_dir"

    echo -e "\n${BLUE}Generating ${service_name} Dockerfile...${NC}"

    cat > "$service_dir/Dockerfile" << EOL
FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV SERVICE_NAME=${service_name}

RUN apt-get update && apt-get install -y \\
    gcc \\
    postgresql-client \\
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

EOL

    # Add service-specific Docker configurations
    case "$service_name" in
        "game"|"chat")
            cat >> "${service_dir}/Dockerfile" << EOL
CMD ["daphne", "-b", "0.0.0.0", "-p", "8000", "${service_name}.asgi:application"]
EOL
            ;;
        *)
            cat >> "${service_dir}/Dockerfile" << EOL
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "${service_name}.wsgi:application"]
EOL
            ;;
    esac

    generate_requirements "$service_name" "${service_dir}/requirements.txt"
}