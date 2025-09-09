#!/bin/bash

# Rocket.Chat 一键部署脚本
# 域名: im.lc2023.com
# 服务器: 206.238.115.75

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
DOMAIN="im.lc2023.com"
EMAIL="admin@lc2023.com"
SERVER_IP="206.238.115.75"

echo -e "${BLUE}=== Rocket.Chat 生产环境部署脚本 ===${NC}"
echo -e "域名: ${GREEN}$DOMAIN${NC}"
echo -e "服务器: ${GREEN}$SERVER_IP${NC}"
echo -e "邮箱: ${GREEN}$EMAIL${NC}"
echo ""

# 函数：打印步骤
print_step() {
    echo -e "${YELLOW}[步骤 $1] $2${NC}"
}

# 函数：检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}错误: $1 未安装${NC}"
        return 1
    fi
}

# 步骤1: 系统检查
print_step "1" "系统环境检查"
echo "检查操作系统..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "${GREEN}✓ Linux 系统${NC}"
else
    echo -e "${RED}✗ 不支持的操作系统${NC}"
    exit 1
fi

# 步骤2: 安装依赖
print_step "2" "安装系统依赖"
echo "更新系统包..."
sudo apt update

echo "安装基础工具..."
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# 安装 Docker
if ! check_command docker; then
    echo "安装 Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✓ Docker 安装完成${NC}"
else
    echo -e "${GREEN}✓ Docker 已安装${NC}"
fi

# 安装 Docker Compose
if ! check_command docker-compose; then
    echo "安装 Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✓ Docker Compose 安装完成${NC}"
else
    echo -e "${GREEN}✓ Docker Compose 已安装${NC}"
fi

# 步骤3: 防火墙配置
print_step "3" "配置防火墙"
echo "配置 UFW 防火墙..."
if check_command ufw; then
    sudo ufw --force enable
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    echo -e "${GREEN}✓ 防火墙配置完成${NC}"
else
    echo -e "${YELLOW}⚠ UFW 未安装，跳过防火墙配置${NC}"
    echo "请手动配置防火墙开放端口: 22, 80, 443"
fi

# 步骤4: 创建部署目录
print_step "4" "准备部署环境"
DEPLOY_DIR="/opt/rocketchat"
echo "创建部署目录: $DEPLOY_DIR"
sudo mkdir -p $DEPLOY_DIR
sudo chown $USER:$USER $DEPLOY_DIR
cd $DEPLOY_DIR

# 复制配置文件
echo "复制配置文件..."
cp /home/admin888/code/Rocket.Chat/docker-compose.prod.yml .
cp /home/admin888/code/Rocket.Chat/mongo-init.js .
cp -r /home/admin888/code/Rocket.Chat/nginx .
cp /home/admin888/code/Rocket.Chat/setup-ssl.sh .
chmod +x setup-ssl.sh

echo -e "${GREEN}✓ 部署环境准备完成${NC}"

# 步骤5: 域名检查
print_step "5" "域名 DNS 检查"
echo "检查域名 $DOMAIN 是否指向服务器 $SERVER_IP..."
DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)
if [ "$DOMAIN_IP" = "$SERVER_IP" ]; then
    echo -e "${GREEN}✓ 域名 DNS 配置正确${NC}"
else
    echo -e "${YELLOW}⚠ 域名 DNS 配置可能有问题${NC}"
    echo "域名解析到: $DOMAIN_IP"
    echo "服务器 IP: $SERVER_IP"
    echo "请确保域名正确指向服务器 IP"
    read -p "是否继续部署？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 步骤6: 启动基础服务
print_step "6" "启动基础服务"
echo "启动 MongoDB 和 Rocket.Chat..."
docker-compose -f docker-compose.prod.yml up -d mongo mongo-init-replica rocketchat

echo "等待服务启动..."
sleep 30

# 检查服务状态
echo "检查服务状态..."
if docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    echo -e "${GREEN}✓ 基础服务启动成功${NC}"
else
    echo -e "${RED}✗ 服务启动失败${NC}"
    docker-compose -f docker-compose.prod.yml logs
    exit 1
fi

# 步骤7: SSL 证书配置
print_step "7" "配置 SSL 证书"
echo "运行 SSL 配置脚本..."
./setup-ssl.sh

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SSL 证书配置成功${NC}"
else
    echo -e "${RED}✗ SSL 证书配置失败${NC}"
    exit 1
fi

# 步骤8: 启动完整服务
print_step "8" "启动完整服务"
echo "启动所有服务..."
docker-compose -f docker-compose.prod.yml up -d

echo "等待服务完全启动..."
sleep 60

# 步骤9: 健康检查
print_step "9" "服务健康检查"
echo "检查 Rocket.Chat 服务..."
if curl -f -s https://$DOMAIN/api/info > /dev/null; then
    echo -e "${GREEN}✓ Rocket.Chat 服务正常${NC}"
else
    echo -e "${YELLOW}⚠ Rocket.Chat 服务可能还在启动中${NC}"
fi

echo "检查 Nginx 服务..."
if docker-compose -f docker-compose.prod.yml exec nginx nginx -t; then
    echo -e "${GREEN}✓ Nginx 配置正确${NC}"
else
    echo -e "${RED}✗ Nginx 配置有误${NC}"
fi

# 步骤10: 显示部署信息
print_step "10" "部署完成"
echo ""
echo -e "${GREEN}=== 部署成功！ ===${NC}"
echo ""
echo -e "${BLUE}访问信息:${NC}"
echo -e "网站地址: ${GREEN}https://$DOMAIN${NC}"
echo -e "管理员账号: ${GREEN}admin${NC}"
echo -e "管理员密码: ${GREEN}ChangeThisPassword123!${NC}"
echo -e "管理员邮箱: ${GREEN}admin@lc2023.com${NC}"
echo ""
echo -e "${BLUE}重要提醒:${NC}"
echo -e "${YELLOW}1. 请立即登录并修改管理员密码${NC}"
echo -e "${YELLOW}2. 请修改 MongoDB 密码（在 docker-compose.prod.yml 中）${NC}"
echo -e "${YELLOW}3. 请配置邮件服务器设置${NC}"
echo -e "${YELLOW}4. 请定期备份数据${NC}"
echo ""
echo -e "${BLUE}常用命令:${NC}"
echo "查看服务状态: docker-compose -f docker-compose.prod.yml ps"
echo "查看日志: docker-compose -f docker-compose.prod.yml logs -f"
echo "重启服务: docker-compose -f docker-compose.prod.yml restart"
echo "停止服务: docker-compose -f docker-compose.prod.yml down"
echo "SSL 证书续期: ./renew-ssl.sh"
echo ""
echo -e "${GREEN}部署完成！请访问 https://$DOMAIN 开始使用 Rocket.Chat${NC}"