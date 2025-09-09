#!/bin/bash

# SSL 证书申请和配置脚本
# 适用于域名: im.lc2023.com

set -e

DOMAIN="im.lc2023.com"
EMAIL="admin@lc2023.com"
SSL_DIR="./ssl"
NGINX_DIR="./nginx"

echo "=== Rocket.Chat SSL 证书配置脚本 ==="
echo "域名: $DOMAIN"
echo "邮箱: $EMAIL"
echo ""

# 检查 Docker 和 Docker Compose
if ! command -v docker &> /dev/null; then
    echo "错误: Docker 未安装"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "错误: Docker Compose 未安装"
    exit 1
fi

# 创建必要的目录
echo "创建必要的目录..."
mkdir -p $SSL_DIR
mkdir -p ./certbot-webroot
mkdir -p ./logs/nginx

# 生成临时自签名证书（用于首次启动）
echo "生成临时自签名证书..."
if [ ! -f "$SSL_DIR/live/$DOMAIN/fullchain.pem" ]; then
    mkdir -p "$SSL_DIR/live/$DOMAIN"
    
    # 生成私钥
    openssl genrsa -out "$SSL_DIR/live/$DOMAIN/privkey.pem" 2048
    
    # 生成自签名证书
    openssl req -new -x509 -key "$SSL_DIR/live/$DOMAIN/privkey.pem" \
        -out "$SSL_DIR/live/$DOMAIN/fullchain.pem" \
        -days 1 \
        -subj "/C=CN/ST=State/L=City/O=Organization/CN=$DOMAIN"
    
    echo "临时证书已生成"
fi

# 启动服务（仅 HTTP 模式用于证书申请）
echo "启动服务进行证书申请..."
docker-compose -f docker-compose.prod.yml up -d nginx

# 等待 Nginx 启动
echo "等待 Nginx 启动..."
sleep 10

# 申请 Let's Encrypt 证书
echo "申请 Let's Encrypt 证书..."
docker-compose -f docker-compose.prod.yml run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d $DOMAIN

if [ $? -eq 0 ]; then
    echo "SSL 证书申请成功！"
    
    # 重启 Nginx 以加载新证书
    echo "重启 Nginx..."
    docker-compose -f docker-compose.prod.yml restart nginx
    
    echo "SSL 配置完成！"
else
    echo "SSL 证书申请失败，请检查域名 DNS 配置"
    exit 1
fi

# 创建证书续期脚本
echo "创建证书续期脚本..."
cat > renew-ssl.sh << 'EOF'
#!/bin/bash

# SSL 证书续期脚本
set -e

echo "开始续期 SSL 证书..."

# 续期证书
docker-compose -f docker-compose.prod.yml run --rm certbot renew --quiet

# 重新加载 Nginx
docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload

echo "SSL 证书续期完成"
EOF

chmod +x renew-ssl.sh

# 添加到 crontab（每月1号凌晨2点执行）
echo "设置自动续期任务..."
(crontab -l 2>/dev/null; echo "0 2 1 * * /bin/bash $(pwd)/renew-ssl.sh >> $(pwd)/logs/ssl-renew.log 2>&1") | crontab -

echo ""
echo "=== SSL 配置完成 ==="
echo "证书位置: $SSL_DIR/live/$DOMAIN/"
echo "续期脚本: ./renew-ssl.sh"
echo "自动续期已设置（每月1号凌晨2点）"
echo ""
echo "现在可以启动完整的 Rocket.Chat 服务："
echo "docker-compose -f docker-compose.prod.yml up -d"
echo ""