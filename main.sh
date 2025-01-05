#!/bin/bash

source ./utils/colors.sh
source ./generators/frontend.sh
source ./generators/backend.sh
source ./generators/nginx.sh
source ./generators/docker.sh

PROJECT_ROOT="ft_transcendence"
FRONTEND_DIR="frontend"
BACKEND_DIR="backend"
NGINX_DIR="nginx"

FRONTEND_SETUP="https://github.com/badreddinkaztaoui/fq_frontend_struct.git"

SERVICES=(auth game chat)

print_header() {
    echo -e "${BOLD_PURPLE}================================${NC}"
    echo -e "${BOLD_PURPLE}Ft_transcendence Project Generator${NC}"
    echo -e "${BOLD_PURPLE}================================${NC}"
}

main() {
    print_header
    
    mkdir -p "$PROJECT_ROOT"
    cd $PROJECT_ROOT

    echo -e "\n${CYAN}Creating project structure...${NC}"
    
    echo -e "${YELLOW}Generating frontend...${NC}"
    generate_frontend
    
    for service in "${SERVICES[@]}"; do
        echo -e "${YELLOW}Generating ${service} service...${NC}"
        generate_backend_service "$service"
    done
    
    echo -e "${YELLOW}Generating nginx configuration...${NC}"
    generate_nginx_config
    
    echo -e "${YELLOW}Generating docker-compose...${NC}"
    generate_docker_compose
    
    echo -e "\n${GREEN_BG}✅ Project generated successfully! ✅${NC}"
    echo -e "\n${CYAN}Next steps:${NC}"
    echo -e "${YELLOW}1.${NC} cd $PROJECT_ROOT"
    echo -e "${YELLOW}2.${NC} docker-compose up --build"
}

main