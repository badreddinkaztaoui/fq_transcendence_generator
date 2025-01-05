#!/bin/bash

generate_nginx_config()
{
    echo -e "\n${BLUE}Creating Nginx configuration${NC}"
    
    # Create nginx directory
    mkdir -p $NGINX_DIR/{scripts,conf.d}
    
    # Generate Dockerfile for nginx
    cat > "$NGINX_DIR/Dockerfile" << EOL
FROM nginx:alpine

RUN apk update && apk add curl bash

COPY ./conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY ./scripts/healthcheck.sh /healthcheck.sh

RUN chmod +x /healthcheck.sh

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s CMD /healthcheck.sh

CMD ["nginx", "-g", "daemon off;"]
EOL

    # Generate Healthcheck Script
    cat > "$NGINX_DIR/scripts/healthcheck.sh" << EOL
#!/bin/bash

services=("frontend" "auth" "game" "chat")
all_healthy=true

for service in "\${services[@]}"; do
    if [[ "\$service" == "frontend" ]]; then
        response=\$(curl -s http://localhost:80)
        if [ \$? -ne 0 ]; then
            all_healthy=false
            break
        fi
    else
        response=\$(curl -s http://localhost:80/api/\$service/health/)
        if [ \$? -ne 0 ] || ! echo "\$response" | grep -q "healthy"; then
            all_healthy=false
            break
        fi
    fi
done

if \$all_healthy; then
    exit 0
else
    exit 1
fi
EOL

    # Generate nginx.conf
    cat > "$NGINX_DIR/conf.d/default.conf" << EOL
upstream frontend_upstream {
    server frontend:3000;
    keepalive 64;
}

upstream auth_upstream {
    server auth:8000;
    keepalive 64;
}

upstream game_upstream {
    server game:8000;
    keepalive 64;
}

upstream chat_upstream {
    server chat:8000;
    keepalive 64;
}

server {
    listen 80;
    listen [::]:80;
    server_name localhost;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    add_header Content-Security-Policy "default-src 'self'; connect-src 'self' https://jsonplaceholder.typicode.com; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Proxy settings
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    # Frontend routes
    location /@vite/client {
        proxy_pass http://frontend_upstream;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /@fs {
        proxy_pass http://frontend_upstream;
    }

    location /node_modules {
        proxy_pass http://frontend_upstream;
    }

    location /_hmr {
        proxy_pass http://frontend_upstream;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Backend service routes
    location /api/auth/ {
        proxy_pass http://auth_upstream/api/;
    }

    location /api/game/ {
        proxy_pass http://game_upstream/api/;
    }

    location /api/chat/ {
        proxy_pass http://chat_upstream/api/;
    }

    # Health check endpoints
    location = /health {
        access_log off;
        add_header Content-Type application/json;
        return 200 '{"status":"healthy"}';
    }

    # Frontend root location
    location / {
        proxy_pass http://frontend_upstream;
    }

    # Gzip configuration
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
EOL

    echo -e "\n${GREEN}Nginx configuration created.${NC}"
}