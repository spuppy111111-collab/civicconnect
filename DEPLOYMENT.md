# 🚀 CivicConnect Deployment Guide

Complete guide for deploying CivicConnect to production environments.

## 📋 Table of Contents

1. [Local Development](#local-development)
2. [Docker Deployment](#docker-deployment)
3. [Cloud Deployment](#cloud-deployment)
4. [Production Checklist](#production-checklist)
5. [Monitoring & Maintenance](#monitoring--maintenance)

---

## 🖥️ Local Development

### Quick Start
```bash
# Run setup script
./setup.sh          # macOS/Linux
setup.bat           # Windows

# Start frontend
npm run dev         # http://localhost:3000

# Start backend (in new terminal)
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate     # Windows
python -m uvicorn backend_api:app --reload
```

### Database Setup
```bash
# Create PostgreSQL database
createdb civicconnect

# Set environment
export DATABASE_URL="postgresql://user:password@localhost:5432/civicconnect"

# Run migrations (when available)
alembic upgrade head
```

---

## 🐳 Docker Deployment

### Prerequisites
- Docker installed
- Docker Compose installed

### One-Command Deployment
```bash
docker-compose up -d
```

This will start:
- PostgreSQL database
- Redis cache
- FastAPI backend (http://localhost:8000)
- Next.js frontend (http://localhost:3000)

### Individual Services
```bash
# Start only database
docker-compose up -d postgres redis

# Start only backend
docker-compose up -d backend

# View logs
docker-compose logs -f backend

# Stop all services
docker-compose down

# Rebuild images
docker-compose build --no-cache
```

### Environment Variables for Docker
Edit `docker-compose.yml` or create `.env` file:
```
DATABASE_URL=postgresql://civicconnect:password@postgres:5432/civicconnect
REDIS_URL=redis://redis:6379
JWT_SECRET=your-secure-secret-key-here
ENVIRONMENT=production
```

---

## ☁️ Cloud Deployment

### Option 1: Vercel (Frontend Only)

**Deployment:**
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel deploy --prod

# Set environment variables in Vercel dashboard
# NEXT_PUBLIC_API_URL=https://api.civicconnect.com/api
```

**Key Settings:**
- Framework: Next.js
- Build Command: `npm run build`
- Output Directory: `.next`
- Install Command: `npm install`

### Option 2: Railway.app (Full Stack)

**Step 1: Create Project**
```bash
npm i -g @railway/cli
railway login
```

**Step 2: Configure railway.json**
```json
{
  "build": {
    "builder": "dockerfile"
  }
}
```

**Step 3: Deploy**
```bash
railway up
```

### Option 3: AWS (Production Grade)

#### Frontend on S3 + CloudFront
```bash
# Build
npm run build

# Deploy to S3
aws s3 sync out s3://civicconnect-web

# Create CloudFront distribution
aws cloudfront create-distribution \
  --origin-domain-name civicconnect-web.s3.amazonaws.com
```

#### Backend on ECS
```bash
# Build and push image
docker build -f Dockerfile.backend -t civicconnect-api:latest .
docker tag civicconnect-api:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/civicconnect-api:latest
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/civicconnect-api:latest
```

#### Database on RDS
```bash
# Create RDS instance via AWS Console
# Update environment variables:
DATABASE_URL=postgresql://admin:password@civicconnect-db.xxx.us-east-1.rds.amazonaws.com:5432/civicconnect
```

### Option 4: Google Cloud (GCP)

#### Frontend on Cloud Run
```bash
# Build Docker image
docker build -f Dockerfile.frontend -t civicconnect-web:latest .

# Push to Container Registry
docker tag civicconnect-web:latest gcr.io/PROJECT_ID/civicconnect-web:latest
docker push gcr.io/PROJECT_ID/civicconnect-web:latest

# Deploy to Cloud Run
gcloud run deploy civicconnect-web \
  --image gcr.io/PROJECT_ID/civicconnect-web:latest \
  --platform managed \
  --region us-central1
```

#### Backend on Cloud Run
```bash
# Build and push
docker build -f Dockerfile.backend -t gcr.io/PROJECT_ID/civicconnect-api:latest .
docker push gcr.io/PROJECT_ID/civicconnect-api:latest

# Deploy
gcloud run deploy civicconnect-api \
  --image gcr.io/PROJECT_ID/civicconnect-api:latest \
  --platform managed \
  --region us-central1 \
  --set-env-vars DATABASE_URL=postgresql://...
```

#### Database on Cloud SQL
```bash
# Create instance
gcloud sql instances create civicconnect-db \
  --database-version POSTGRES_14 \
  --region us-central1

# Create database
gcloud sql databases create civicconnect \
  --instance civicconnect-db
```

### Option 5: Azure

#### Frontend on Static Web Apps
```bash
# Create Static Web App
az staticwebapp create \
  --name civicconnect-web \
  --source ./src \
  --location eastus \
  --branch main \
  --resource-group myResourceGroup
```

#### Backend on App Service
```bash
# Create App Service
az appservice plan create \
  --name civicconnect-plan \
  --resource-group myResourceGroup \
  --sku B1

az webapp create \
  --resource-group myResourceGroup \
  --plan civicconnect-plan \
  --name civicconnect-api \
  --runtime "PYTHON|3.11"
```

---

## ✅ Production Checklist

Before deploying to production, verify:

### Code Quality
- [ ] All tests passing
- [ ] No console errors or warnings
- [ ] ESLint and TypeScript errors resolved
- [ ] Code reviewed
- [ ] Security vulnerabilities fixed

### Environment
- [ ] Environment variables configured
- [ ] Database backups enabled
- [ ] HTTPS/SSL certificates configured
- [ ] CORS properly configured
- [ ] API rate limiting enabled

### Performance
- [ ] Compression enabled (gzip/brotli)
- [ ] Caching headers configured
- [ ] Database indexes created
- [ ] Images optimized
- [ ] Bundle size optimized

### Security
- [ ] HTTPS enforced
- [ ] JWT secrets strong and secure
- [ ] Database credentials encrypted
- [ ] API keys rotated
- [ ] CORS whitelisted
- [ ] SQL injection prevention
- [ ] XSS protection enabled

### Monitoring
- [ ] Logging configured
- [ ] Error tracking (Sentry/DataDog)
- [ ] Performance monitoring (APM)
- [ ] Uptime monitoring
- [ ] Alerts configured

### Backup & Recovery
- [ ] Database backups scheduled
- [ ] Backup restoration tested
- [ ] Disaster recovery plan documented
- [ ] Data retention policy defined

---

## 📊 Monitoring & Maintenance

### Health Checks
```bash
# Check backend health
curl http://localhost:8000/health

# Check frontend health
curl http://localhost:3000

# Check database
psql -U civicconnect -d civicconnect -c "SELECT 1"
```

### Logs
```bash
# Docker logs
docker-compose logs -f backend

# Application logs (if using cloud logging)
# CloudWatch, Stackdriver, etc.
```

### Database Maintenance
```sql
-- Check database size
SELECT pg_size_pretty(pg_database_size('civicconnect'));

-- Vacuum and analyze
VACUUM ANALYZE;

-- Monitor connections
SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;
```

### Performance Monitoring
```bash
# Monitor CPU and memory
docker stats civicconnect-api

# Monitor database performance
# Use PostgreSQL's EXPLAIN ANALYZE for query optimization
```

### Updates & Patches
```bash
# Update dependencies
npm update
pip list --outdated

# Security updates
npm audit fix
pip install --upgrade pip

# Docker image updates
docker pull postgres:16-alpine
docker-compose pull
docker-compose up -d
```

### Scaling

#### Horizontal Scaling (Multiple Instances)
```bash
# Docker Swarm
docker swarm init
docker service create --replicas 3 civicconnect-api

# Kubernetes
kubectl scale deployment civicconnect-api --replicas 3
```

#### Vertical Scaling (Larger Instances)
```bash
# Increase resource limits in docker-compose.yml
resources:
  limits:
    cpus: '1.0'
    memory: 2G
```

---

## 🆘 Troubleshooting

### Database Connection Issues
```bash
# Test connection
psql -h localhost -U civicconnect -d civicconnect -c "SELECT 1"

# Check connection string format
# postgresql://username:password@host:port/database
```

### API Not Responding
```bash
# Check if service is running
docker-compose ps

# Check logs
docker-compose logs backend

# Restart service
docker-compose restart backend
```

### High Memory Usage
```bash
# Analyze memory leaks
# Use memory profiler for Python

# Clear Docker cache
docker system prune -a

# Restart containers
docker-compose restart
```

### SSL Certificate Issues
```bash
# Generate self-signed certificate (development)
openssl req -x509 -newkey rsa:4096 -nodes -out cert.pem -keyout key.pem -days 365

# Let's Encrypt (production)
certbot certonly --standalone -d yourdomain.com
```

---

## 📞 Support

For deployment issues:
1. Check logs
2. Review this guide
3. Check GitHub Issues
4. Contact support@civicconnect.com

---

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com)
- [Next.js Deployment](https://nextjs.org/docs/deployment/introduction)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment)
- [PostgreSQL Documentation](https://www.postgresql.org/docs)
- [Vercel Deployment](https://vercel.com/docs)
- [AWS Deployment](https://aws.amazon.com/getting-started)
- [GCP Deployment](https://cloud.google.com/getting-started)

---

**Last Updated:** September 2026
**Version:** 1.0.0
