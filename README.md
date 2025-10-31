# HNG DevOps Stage 1 - Automated Deployment Script

## Overview
Automated Bash script for deploying Dockerized applications to remote servers with full environment setup, Docker deployment, and Nginx reverse proxy configuration.

## Author
**Joe-Dan Effiong**

## Features
- ✅ Interactive parameter collection with validation
- ✅ Git repository cloning with PAT authentication
- ✅ Automated Docker, Docker Compose, and Nginx installation
- ✅ Container deployment with health checks
- ✅ Nginx reverse proxy configuration
- ✅ Comprehensive logging and error handling
- ✅ Idempotent execution (safe to re-run)
- ✅ Automatic cleanup of old containers

## Requirements
- Bash 4.0+
- SSH access to remote Ubuntu/Debian server
- GitHub Personal Access Token
- SSH private key (.pem file)

## Usage

### Deploy Application
```bash
chmod +x deploy.sh
./deploy.sh
```

### Required Inputs
When running the script, you'll be prompted for:
- GitHub Repository URL
- Personal Access Token
- Branch name (default: main)
- Remote server username
- Server IP address
- SSH key path
- Application port (default: 80)

## Deployment Flow
1. Clones/updates repository
2. Verifies Dockerfile exists
3. Tests SSH connectivity
4. Installs Docker, Docker Compose, Nginx
5. Transfers application files
6. Builds and runs Docker container
7. Configures Nginx reverse proxy
8. Validates deployment

## Logs
All deployment logs are saved as `deploy_YYYYMMDD_HHMMSS.log`

## Application Access
- **Direct**: http://YOUR_SERVER_IP
- **Via Nginx**: http://YOUR_SERVER_IP:8080

## Technical Details
- Container runs on port 80
- Nginx proxy on port 8080
- Docker image: nginx:alpine
- Automatic container restart enabled

## Troubleshooting
- Check logs: `docker logs hng-devops-stage1`
- View running containers: `docker ps`
- Restart container: `docker restart hng-devops-stage1`

## Project Structure
```
.
├── deploy.sh          # Main deployment script
├── Dockerfile         # Docker configuration
├── index.html         # Application HTML
└── README.md          # Documentation
```

## Security Notes
- Never commit SSH keys or tokens to the repository
- Use `.gitignore` to exclude sensitive files
- Rotate tokens regularly

## License
MIT License - HNG DevOps Internship Stage 1
