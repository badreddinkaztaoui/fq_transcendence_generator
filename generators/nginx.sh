#!/bin/bash

generate_nginx_config()
{    
    mkdir -p $NGINX_DIR/{scripts,conf.d}
    
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

    cat > "$NGINX_DIR/conf.d/default.conf" << EOL
limit_req_zone \$binary_remote_addr zone=api_limit:10m rate=10r/s;
limit_conn_zone \$binary_remote_addr zone=addr_limit:10m;

upstream frontend_upstream {
    server frontend:3000;
    keepalive 32;
}

upstream auth_upstream {
    server auth:8000;
    keepalive 32;
}

upstream game_upstream {
    server game:8000;
    keepalive 32;
}

upstream chat_upstream {
    server chat:8000;
    keepalive 32;
}

server {
    listen 80;
    listen [::]:80;
    server_name localhost;
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; connect-src 'self' wss: https://jsonplaceholder.typicode.com; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:;" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()";

    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Request-ID \$request_id;
    proxy_buffering on;
    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;

    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    location /@vite/client {
        proxy_pass http://frontend_upstream;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /@fs/ {
        proxy_pass http://frontend_upstream;
        limit_req zone=api_limit burst=20 nodelay;
        limit_conn addr_limit 10;
    }

    location /node_modules/ {
        proxy_pass http://frontend_upstream;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    location /_hmr/ {
        proxy_pass http://frontend_upstream;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /api/auth/ {
        proxy_pass http://auth_upstream/api/;
        limit_req zone=api_limit burst=10 nodelay;
        limit_conn addr_limit 5;
        
        proxy_intercept_errors on;
        error_page 404 = @404_json;
        error_page 500 502 503 504 = @5xx_json;
    }

    location /api/game/ {
        proxy_pass http://game_upstream/api/;
        limit_req zone=api_limit burst=20 nodelay;
        limit_conn addr_limit 10;
        
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_intercept_errors on;
        error_page 404 = @404_json;
        error_page 500 502 503 504 = @5xx_json;
    }

    location /api/chat/ {
        proxy_pass http://chat_upstream/api/;
        limit_req zone=api_limit burst=20 nodelay;
        limit_conn addr_limit 10;
        
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_intercept_errors on;
        error_page 404 = @404_json;
        error_page 500 502 503 504 = @5xx_json;
    }

    location = /health {
        access_log off;
        add_header Content-Type application/json;
        return 200 '{"status":"healthy"}';
    }

    location / {
        proxy_pass http://frontend_upstream;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    location @404_json {
        default_type application/json;
        return 404 '{"error": "Not Found"}';
    }

    location @5xx_json {
        default_type application/json;
        return 500 '{"error": "Internal Server Error"}';
    }

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1000;
    gzip_types
        application/javascript
        application/json
        application/x-javascript
        application/xml
        text/css
        text/javascript
        text/plain
        text/xml;
}
EOL

}