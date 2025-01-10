#!/bin/bash

generate_frontend()
{
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Error: Git is not installed${NC}"
        echo -e "${YELLOW}ℹ️  Please install git before proceeding${NC}"
        return 1
    fi

    echo -e "${YELLOW}📥 Cloning frontend template...${NC}"
    
    if git clone "$FRONTEND_SETUP" "$FRONTEND_DIR"; then     
        echo -e "${YELLOW}🧹 Cleaning up git repository...${NC}"
        rm -rf $FRONTEND_DIR/.git
    else
        echo -e "${RED}❌ Failed to clone frontend template${NC}"
        echo -e "${YELLOW}ℹ️  Please check your internet connection and repository URL${NC}"
        return 1
    fi
}