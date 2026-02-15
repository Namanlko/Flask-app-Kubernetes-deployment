# Flask App Deployment on Kind Kubernetes Cluster

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)](https://flask.palletsprojects.com/)
[![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)](https://www.nginx.com/)

A simple yet comprehensive demonstration of **Kubernetes Ingress** with **Nginx Ingress Controller** using a Flask application. Perfect for learning path-based routing, service mesh, and Kubernetes networking concepts.

## 🎯 What You'll Learn

- ✅ Kubernetes Ingress fundamentals
- ✅ Nginx Ingress Controller setup
- ✅ Path-based routing (`/flask-app/*`)
- ✅ URL rewrite rules
- ✅ Multi-replica deployments
- ✅ Service discovery and load balancing
- ✅ kind (Kubernetes in Docker) cluster management

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Ubuntu/Linux** (tested on Ubuntu 20.04+)
- **Docker** (v20.10+)
- **kubectl** (v1.25+)
- **kind** (v0.20.0+)
- **curl** (for testing)

### Installing Prerequisites

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Verify installations
docker --version
kubectl version --client
kind --version
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Namanlko/Flask-app-Kubernetes-deployment.git
cd Flask-app-Kubernetes-deployment
```

### 2. Run the Setup Script

```bash
chmod +x setup.sh
./setup.sh
```

The script will automatically:
- Build the Flask Docker image
- Create a kind cluster with port mapping
- Install Nginx Ingress Controller
- Deploy the Flask application
- Configure Ingress rules

### 3. Access the Application

Once deployment is complete (2-3 minutes), access your app:

```bash
# Home page
curl http://localhost/flask-app/

# API endpoint
curl http://localhost/flask-app/api/users

# Health check
curl http://localhost/flask-app/api/health
```

**Browser Access:**
- Local: `http://localhost/flask-app/`
- EC2/Remote: `http://<YOUR-PUBLIC-IP>/flask-app/`

> **Note:** For EC2, ensure port 80 is open in Security Group

## 📁 Project Structure

```
Flask-app-Kubernetes-deployment/
├── app/
│   ├── app.py              # Flask application
│   ├── requirements.txt    # Python dependencies
│   └── Dockerfile          # Container image definition
├── k8s/
│   ├── namespace.yaml      # Kubernetes namespace
│   ├── deployment.yaml     # Flask deployment (3 replicas)
│   ├── service.yaml        # ClusterIP service
│   └── ingress.yaml        # Ingress routing rules
├── cluster-config.yaml     # kind cluster configuration
├── setup.sh                # Automated setup script
└── README.md              # This file
```

## 🔧 Manual Setup (Step by Step)

If you prefer manual setup over the automated script:

### Step 1: Build Docker Image

```bash
cd app
docker build -t simple-flask:latest .
cd ..
```

### Step 2: Create kind Cluster

```bash
kind create cluster --config cluster-config.yaml --name flask-cluster
```

### Step 3: Load Image into Cluster

```bash
kind load docker-image simple-flask:latest --name flask-cluster
```

### Step 4: Install Nginx Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### Step 5: Deploy Application

```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy application
kubectl apply -f k8s/deployment.yaml

# Create service
kubectl apply -f k8s/service.yaml

# Configure ingress
kubectl apply -f k8s/ingress.yaml

# Wait for pods to be ready
kubectl wait --namespace flask-app \
  --for=condition=ready pod \
  --selector=app=flask \
  --timeout=120s
```

### Step 6: Verify Deployment

```bash
# Check all resources
kubectl get all -n flask-app

# Check ingress
kubectl get ingress -n flask-app

# View pod logs
kubectl logs -n flask-app -l app=flask --tail=50
```

## 🎓 Understanding the Components

### 1. **Namespace** (`k8s/namespace.yaml`)
Isolates the application resources from other workloads.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: flask-app
```

### 2. **Deployment** (`k8s/deployment.yaml`)
Manages 3 replicas of the Flask application for high availability and load balancing.

```yaml
spec:
  replicas: 3
  selector:
    matchLabels:
      app: flask
```

### 3. **Service** (`k8s/service.yaml`)
Provides internal cluster networking with a stable ClusterIP.

```yaml
spec:
  type: ClusterIP
  ports:
  - port: 5000
    targetPort: 5000
```

### 4. **Ingress** (`k8s/ingress.yaml`)
Routes external traffic to the Flask service with path-based routing.

```yaml
annotations:
  nginx.ingress.kubernetes.io/rewrite-target: /$2

path: /flask-app(/|$)(.*)
```

**How it works:**
- Request: `http://localhost/flask-app/api/users`
- Ingress captures: `/flask-app/` + `/api/users`
- Rewrites to: `/api/users`
- Flask receives: `/api/users` ✅

## 📊 Useful Commands

### Cluster Management

```bash
# View cluster info
kubectl cluster-info --context kind-flask-cluster

# List all clusters
kind get clusters

# Delete cluster
kind delete cluster --name flask-cluster
```

### Application Management

```bash
# Get all resources in namespace
kubectl get all -n flask-app

# Describe deployment
kubectl describe deployment flask-app -n flask-app

# View pod logs (real-time)
kubectl logs -n flask-app -l app=flask -f

# Scale deployment
kubectl scale deployment flask-app --replicas=5 -n flask-app

# Restart deployment
kubectl rollout restart deployment flask-app -n flask-app
```

### Debugging

```bash
# Check pod status
kubectl get pods -n flask-app -o wide

# Describe ingress
kubectl describe ingress flask-ingress -n flask-app

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=100

# Execute command in pod
kubectl exec -it <pod-name> -n flask-app -- /bin/sh

# Port forward for direct testing (bypass ingress)
kubectl port-forward -n flask-app service/flask-service 5000:5000
```

### Testing

```bash
# Test home page
curl http://localhost/flask-app/

# Test API endpoint
curl http://localhost/flask-app/api/users

# Test health check
curl http://localhost/flask-app/api/health

# Check ingress endpoints
kubectl get endpoints -n flask-app

# Test with verbose output
curl -v http://localhost/flask-app/
```

## 🔀 Path-Based Routing Examples

### Current Setup
```
http://localhost/flask-app/          → Flask Home Page
http://localhost/flask-app/api/users → User API
http://localhost/flask-app/api/health → Health Check
```

### Adding More Services

You can extend the ingress to route to multiple services:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      # Flask app
      - path: /flask-app(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: flask-service
            port:
              number: 5000
      
      # Admin panel
      - path: /admin(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: admin-service
            port:
              number: 3000
      
      # Frontend
      - path: /(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

## 🌐 Host-Based Routing (Alternative)

Instead of path-based routing, you can use host-based routing:

```yaml
spec:
  rules:
  - host: flask-app.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: flask-service
            port:
              number: 5000
```

Add to `/etc/hosts`:
```bash
echo "127.0.0.1 flask-app.local" | sudo tee -a /etc/hosts
```

Access: `http://flask-app.local/`

## 🔒 Adding SSL/TLS (Advanced)

```bash
# Create self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=flask-app.local"

# Create TLS secret
kubectl create secret tls flask-tls \
  --cert=tls.crt --key=tls.key -n flask-app

# Update ingress with TLS
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: flask-ingress
  namespace: flask-app
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - flask-app.local
    secretName: flask-tls
  rules:
  - host: flask-app.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: flask-service
            port:
              number: 5000
EOF
```

## 🐛 Troubleshooting

### Issue: Pods not starting

```bash
# Check pod status
kubectl get pods -n flask-app

# Describe pod for events
kubectl describe pod <pod-name> -n flask-app

# Check logs
kubectl logs <pod-name> -n flask-app
```

### Issue: Ingress not working

```bash
# Verify ingress controller is running
kubectl get pods -n ingress-nginx

# Check ingress configuration
kubectl describe ingress flask-ingress -n flask-app

# View ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### Issue: Connection refused

```bash
# Check if port 80 is mapped
docker ps | grep kindest

# Expected output should show: 0.0.0.0:80->80/tcp

# If not, recreate cluster with proper config
kind delete cluster --name flask-cluster
kind create cluster --config cluster-config.yaml
```

### Issue: Image pull errors

```bash
# Verify image exists
docker images | grep simple-flask

# Reload image into cluster
kind load docker-image simple-flask:latest --name flask-cluster

# Check if imagePullPolicy is set to Never in deployment
kubectl get deployment flask-app -n flask-app -o yaml | grep imagePullPolicy
```

## 📚 Learning Resources

- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [kind Documentation](https://kind.sigs.k8s.io/)
- [Flask Documentation](https://flask.palletsprojects.com/)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


## 🙏 Acknowledgments

- Kubernetes community for excellent documentation
- Nginx Ingress Controller maintainers
- kind project for making local Kubernetes clusters simple

## 📞 Contact

**Naman Pandey**

Project Link: [https://github.com/Namanlko/Flask-app-Kubernetes-deployment](https://github.com/Namanlko/Flask-app-Kubernetes-deployment)

⭐ **If this project helped you learn Kubernetes Ingress, please give it a star!** ⭐


## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└───────────────────────────┬─────────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │   Port 80      │
                    │  (kind cluster) │
                    └───────┬────────┘
                            │
                ┌───────────▼───────────┐
                │  Nginx Ingress        │
                │  Controller           │
                │  (ingress-nginx ns)   │
                └───────────┬───────────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
    /flask-app/*      /admin/*     / (default)
              │             │             │
              ▼             ▼             ▼
        ┌─────────┐   ┌─────────┐  ┌──────────┐
        │ Flask   │   │ Admin   │  │ Frontend │
        │ Service │   │ Service │  │ Service  │
        └────┬────┘   └────┬────┘  └────┬─────┘
             │             │            │
        ┌────▼────┐   ┌────▼────┐  ┌───▼──────┐
        │ Pod 1   │   │ Pod 1   │  │ Pod 1    │
        │ Pod 2   │   │ Pod 2   │  │ Pod 2    │
        │ Pod 3   │   └─────────┘  │ Pod 3    │
        └─────────┘                └──────────┘
```


**Happy Learning! 🚀**
