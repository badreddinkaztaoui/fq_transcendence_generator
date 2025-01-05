#!/bin/bash

generate_frontend()
{
    echo -e "\n${BLUE}Checking prerequisites...${NC}"

    if ! command -v git &> /dev/null; then
        echo -e "\n${RED}Git is not installed. Please install git first.${NC}"
        return 1
    fi

    echo -e "\n${BLUE}Cloning repository from $FRONTEND_REPO${NC}"

    if git clone "$FRONTEND_SETUP" "$FRONTEND_DIR"; then
        echo -e "\n${GREEN}Repository cloned successfully to $PROJECT_ROOT/$FRONTEND_DIR${NC}"
    else
        echo -e "\n${RED}Failed to clone repository${NC}"
        return 1
    fi

    rm -rf $FRONTEND_DIR/.git

    echo -e "\n${GREEN}Frontend Created Successfuly.${NC}"
}
