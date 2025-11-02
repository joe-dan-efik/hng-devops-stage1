#!/bin/bash
set -e
LOG_FILE="deploy_$(date +%Y%m%d_%H%M%S).log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

trap 'log "❌ ERROR on line $LINENO"; exit 1' ERR

read -p "Enter GitHub repo URL: " GIT_URL
read -sp "Enter your Personal Access Token: " PAT
echo
read -p "Enter branch name (default: main): " BRANCH
read -p "Enter Remote Server Username: " SSH_USER
read -p "Enter Remote Server IP Address: " SERVER_IP
read -p "Enter path to SSH Key: " SSH_KEY
read -p "Enter Application internal port (default: 80): " APP_PORT

BRANCH=${BRANCH:-main}
APP_PORT=${APP_PORT:-80}
REPO_NAME=$(basename "$GIT_URL" .git)

log "Cloning repository..."
if [ -d "repo" ]; then
  cd repo && git pull origin "$BRANCH"
else
  git clone -b "$BRANCH" https://${PAT}@${GIT_URL#https://} repo
  cd repo
fi

if [ -f "Dockerfile" ]; then
  log "✅ Docker setup files found"
else
  log "❌ No Dockerfile found!"
  exit 1
fi

log "Testing SSH connection..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$SERVER_IP" "echo '✅ SSH connected successfully'"

log "Preparing remote environment..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" <<'EOF'
sudo apt update -y
sudo apt install -y docker.io docker-compose nginx
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker
docker --version
EOF

log "Deploying Docker container..."
REMOTE_DIR="/home/$SSH_USER/app"

ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" "mkdir -p $REMOTE_DIR"
scp -i "$SSH_KEY" -r Dockerfile index.html "$SSH_USER@$SERVER_IP:$REMOTE_DIR/"

ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" bash <<EOF
cd $REMOTE_DIR

sudo systemctl stop nginx || true
docker stop \$(docker ps -aq) 2>/dev/null || true
docker rm \$(docker ps -aq) 2>/dev/null || true

docker build -t $REPO_NAME:latest .
docker run -d -p 80:80 --name $REPO_NAME --restart unless-stopped $REPO_NAME:latest

sleep 3
docker ps | grep $REPO_NAME
EOF

log "Configuring Nginx..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" bash <<'EOF'
sudo tee /etc/nginx/sites-available/hng_app > /dev/null <<'NGINX'
server {
    listen 8080;
    server_name _;
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINX

sudo ln -sf /etc/nginx/sites-available/hng_app /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl enable nginx
sudo systemctl start nginx
sudo nginx -t
EOF

log "Validating deployment..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" bash <<EOF
docker ps
curl -f http://localhost:80 || echo "App starting..."
EOF

log "✅ Deployment completed successfully!"
log "🌐 Access: http://$SERVER_IP"