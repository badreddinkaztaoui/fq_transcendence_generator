#!/bin/bash

generate_docker_compose()
{    
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
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 500M

  auth:
    container_name: auth
    build:
      context: ./backend/auth
      dockerfile: Dockerfile
    volumes:
      - ./backend/auth:/app
    env_file:
      - .env
      - ./backend/auth/.env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: >
      sh -c "
        python manage.py collectstatic --noinput &&
        python manage.py makemigrations &&
        python manage.py migrate &&
        daphne -b 0.0.0.0 -p 8000 auth.asgi:application"
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '0.75'
          memory: 750M

  game:
    container_name: game
    build:
      context: ./backend/game
      dockerfile: Dockerfile
    volumes:
      - ./backend/game:/app
    env_file:
      - .env
      - ./backend/game/.env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: >
      sh -c "
        python manage.py collectstatic --noinput &&
        python manage.py makemigrations &&
        python manage.py migrate &&
        daphne -b 0.0.0.0 -p 8000 game.asgi:application"
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '1.00'
          memory: 1G

  chat:
    container_name: chat
    build:
      context: ./backend/chat
      dockerfile: Dockerfile
    volumes:
      - ./backend/chat:/app
    env_file:
      - .env
      - ./backend/chat/.env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: >
      sh -c "
        python manage.py collectstatic --noinput &&
        python manage.py makemigrations &&
        python manage.py migrate &&
        daphne -b 0.0.0.0 -p 8000 chat.asgi:application"
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '0.75'
          memory: 750M

  postgres:
    container_name: postgres
    image: postgres:17.2-alpine3.19
    env_file:
      - .env
    volumes:
      - postgres:/var/lib/postgresql/data
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${POSTGRES_USER} -d \${POSTGRES_DB}"]
      interval: 5s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          cpus: '1.00'
          memory: 1G
    environment:
      POSTGRES_HOST_AUTH_METHOD: scram-sha-256
      POSTGRES_INITDB_ARGS: --auth-host=scram-sha-256

  redis:
    container_name: redis
    image: redis:7.2-alpine
    command: redis-server --requirepass \${REDIS_PASSWORD}
    volumes:
      - redis:/data
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "\${REDIS_PASSWORD}", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 500M

  nginx:
    container_name: nginx
    build:
      context: ./nginx
      dockerfile: Dockerfile
    ports:
      - "8000:80"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      frontend:
        condition: service_healthy
      auth:
        condition: service_healthy
      game:
        condition: service_healthy
      chat:
        condition: service_healthy
    networks:
      - app-network
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 500M

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

}