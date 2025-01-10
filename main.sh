#!/bin/bash

source ./utils/colors.sh
source ./generators/env.sh
source ./generators/frontend.sh
source ./generators/backend.sh
source ./generators/nginx.sh
source ./generators/docker.sh

PROJECT_ROOT="ft_transcendence"
FRONTEND_DIR="frontend"
BACKEND_DIR="backend"
NGINX_DIR="nginx"

FRONTEND_SETUP="https://github.com/badreddinkaztaoui/fq_frontend_struct.git"

print_header() {
    echo -e "\n${BOLD_PURPLE}┌────────────────────────────────────────┐${NC}"
    echo -e "${BOLD_PURPLE}│       FT_TRANSCENDENCE GENERATOR       │${NC}"
    echo -e "${BOLD_PURPLE}└────────────────────────────────────────┘${NC}\n"
    
    echo -e "${CYAN}🚀 Starting project generation...${NC}\n"
}

main() {
    clear
    print_header
    
    echo -e "${YELLOW}📁 Creating project structure...${NC}"
    mkdir -p "$PROJECT_ROOT"
    cd $PROJECT_ROOT
    echo -e "${GREEN}✓ Project directory created${NC}\n"

    echo -e "${YELLOW}📝 Generating .env file...${NC}"
    generate_env_file
    echo -e "${GREEN}✓ .env configuration completed${NC}\n"
    
    echo -e "${YELLOW}🌐 Generating Frontend...${NC}"
    generate_frontend
    echo -e "${GREEN}✓ Frontend setup completed${NC}\n"
    
    echo -e "${YELLOW}⚙️  Generating Backend Services...${NC}"
    generate_backend_service "auth"
    echo -e "${GREEN}✓ Auth service generated${NC}"
    generate_backend_service "game"
    echo -e "${GREEN}✓ Game service generated${NC}"
    generate_backend_service "chat"
    echo -e "${GREEN}✓ Chat service generated${NC}\n"
    
    echo -e "${YELLOW}📝 Configuring Nginx...${NC}"
    generate_nginx_config
    echo -e "${GREEN}✓ Nginx configuration completed${NC}\n"
    
    echo -e "${YELLOW}🐳 Creating Docker configuration...${NC}"
    generate_docker_compose
    echo -e "${GREEN}✓ Docker compose configuration completed${NC}\n"
    
    echo -e "${GREEN_BG}✨ Project generated successfully! ✨${NC}\n"
    echo -e "${CYAN}📋 Next steps:${NC}"
    echo -e "${YELLOW}1.${NC} cd $PROJECT_ROOT"
    echo -e "${YELLOW}2.${NC} docker-compose up --build\n"
}

main