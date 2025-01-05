#!/bin/bash

generate_docker_compose() {
    echo -e "\n${BLUE}Creating Docker Compose configuration${NC}"
    
    # Generate docker-compose.yml
    cat > "docker-compose.yml" << EOL
services:
  frontend:
    container_name: frontend
    build:
      context: ./frontend
      dockerfile: Dockerfile
    volumes:
      - ./frontend:/app
      - /app/node_modules
    networks:
      - app-network

  auth:
    container_name: auth
    build:
      context: ./backend/auth
      dockerfile: Dockerfile
    volumes:
      - ./backend/auth:/app
    env_file:
      - .env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: >
      sh -c "python manage.py makemigrations &&
             python manage.py migrate &&
             daphne -b 0.0.0.0 -p 8000 auth.asgi:application"
    networks:
      - app-network

  game:
    container_name: game
    build:
      context: ./backend/game
      dockerfile: Dockerfile
    volumes:
      - ./backend/game:/app
    env_file:
      - .env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: >
      sh -c "python manage.py makemigrations &&
             python manage.py migrate &&
             daphne -b 0.0.0.0 -p 8000 game.asgi:application"
    networks:
      - app-network

  chat:
    container_name: chat
    build:
      context: ./backend/chat
      dockerfile: Dockerfile
    volumes:
      - ./backend/chat:/app
    env_file:
      - .env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: >
      sh -c "python manage.py makemigrations &&
             python manage.py migrate &&
             daphne -b 0.0.0.0 -p 8000 chat.asgi:application"
    networks:
      - app-network

  postgres:
    container_name: postgres
    restart: always
    image: postgres:17.2-alpine3.19
    env_file:
      - .env
    volumes:
      - postgres:/var/lib/postgresql/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${POSTGRES_USER} -d \${POSTGRES_DB}"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    container_name: redis
    image: redis:7.2-alpine
    restart: always
    volumes:
      - redis:/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  nginx:
    container_name: nginx
    build:
      context: ./nginx
      dockerfile: Dockerfile
    ports:
      - "8000:80"
    volumes:
      - ./nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - frontend
      - auth
      - game
      - chat
    networks:
      - app-network

volumes:
  postgres:
    driver: local
  redis:
    driver: local

networks:
  app-network:
    name: app-network
    driver: bridge
EOL

    # Generate .env file for the project root
    cat > ".env" << EOL
POSTGRES_DB="transcendence"
POSTGRES_USER="bkaztaou"
POSTGRES_PASSWORD="1337"
POSTGRES_HOST="postgres"
POSTGRES_PORT="5432"
REDIS_HOST="redis"
REDIS_PORT="6379"
EOL

    echo -e "\n${GREEN}Docker Compose configuration created.${NC}"
}