#!/bin/bash

generate_env_file()
{
    cat > ".env" << EOL
# PostgreSQL Configuration
POSTGRES_HOST="postgres"
POSTGRES_PORT=5432
POSTGRES_DB="game_platform_db"
POSTGRES_USER="game_platform_admin"
POSTGRES_PASSWORD="kj2H9x#mP\$5vN8qL"
POSTGRES_SSL_MODE="require"

# Redis Configuration
REDIS_HOST="redis"
REDIS_PORT=6379
REDIS_PASSWORD="Rd7\$mK9pL#vX4nQ2"
REDIS_DB=0

# Auth Service Configuration
AUTH_SERVICE_SECRET_KEY="django-insecure-k9m4n7q2x8p5v3w6t9y2b4n7m1l9k4j7h2g5f8d3s6a9"
AUTH_SERVICE_DEBUG=False
AUTH_SERVICE_ALLOWED_HOSTS="localhost,127.0.0.1"
AUTH_SERVICE_CORS_ORIGINS="http://localhost:3000,http://127.0.0.1:3000"
AUTH_SERVICE_DB_NAME="auth_service_db"
AUTH_SERVICE_DB_USER="auth_service_user"
AUTH_SERVICE_DB_PASSWORD="aS8\$kP2mN9x#vL5q"

# Game Service Configuration
GAME_SERVICE_SECRET_KEY="django-insecure-h2g5f8d3s6a9x4c7v0b3n6m9k2l5p8t1y4r7w0q3e6"
GAME_SERVICE_DEBUG=False
GAME_SERVICE_ALLOWED_HOSTS="localhost,127.0.0.1"
GAME_SERVICE_CORS_ORIGINS="http://localhost:3000,http://127.0.0.1:3000"
GAME_SERVICE_DB_NAME="game_service_db"
GAME_SERVICE_DB_USER="game_service_user"
GAME_SERVICE_DB_PASSWORD="gM5#nB8kL2\$xP9qW"

# Chat Service Configuration
CHAT_SERVICE_SECRET_KEY="django-insecure-t1y4r7w0q3e6h9x2c5v8b1n4m7k0l3p6s9f2d5g8"
CHAT_SERVICE_DEBUG=False
CHAT_SERVICE_ALLOWED_HOSTS="localhost,127.0.0.1"
CHAT_SERVICE_CORS_ORIGINS="http://localhost:3000,http://127.0.0.1:3000"
CHAT_SERVICE_DB_NAME="chat_service_db"
CHAT_SERVICE_DB_USER="chat_service_user"
CHAT_SERVICE_DB_PASSWORD="cH4\$jM7nK2#xL5pQ"

# JWT Configuration
JWT_SECRET_KEY="m9k2l5p8t1y4r7w0q3e6h9x2c5v8b1n4m7k0l3p6s9f2d5g8"
JWT_ACCESS_TOKEN_LIFETIME=15
JWT_REFRESH_TOKEN_LIFETIME=1440

EOL
}