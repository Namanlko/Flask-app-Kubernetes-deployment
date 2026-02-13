#!/bin/bash

echo "🚀 Starting Simple Flask Kubernetes Setup..."

# Create Flask app
mkdir -p app

cat > app/app.py << 'PYEOF'
from flask import Flask, jsonify
import socket

app = Flask(__name__)

@app.route('/')
def home():
    return f"""
    <html>
    <head>
        <title>Simple Flask App</title>
        <style>
            body {{
                font-family: Arial;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
                margin: 0;
            }}
            .container {{
                background: white;
                padding: 50px;
                border-radius: 20px;
                box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                text-align: center;
            }}
            h1 {{ color: #667eea; }}
            .pod {{ color: #764ba2; margin: 20px 0; }}
            a {{
                display: inline-block;
                margin: 10px;
                padding: 15px 30px;
                background: #667eea;
                color: white;
                text-decoration: none;
                border-radius: 50px;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🎉 Flask App Running!</h1>
            <div class="pod">Pod: {socket.gethostname()}</div>
            <a href="/api/users">View Users</a>
            <a href="/api/health">Health Check</a>
        </div>
    </body>
    </html>
    """

@app.route('/api/users')
def users():
    return jsonify({
        'message': 'Path-based routing working!',
        'pod': socket.gethostname(),
        'users': [
            {'id': 1, 'name': 'Naman', 'role': 'DevOps Engineer'},
            {'id': 2, 'name': 'Rahul', 'role': 'Backend Developer'},
            {'id': 3, 'name': 'Priya', 'role': 'Frontend Developer'}
        ]
    })

@app.route('/api/health')
def health():
    return jsonify({
        'status': 'healthy',
        'pod': socket.gethostname()
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PYEOF

cat > app/requirements.txt << 'REQEOF'
Flask==2.3.0
REQEOF

cat > app/Dockerfile << 'DOCKEREOF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
DOCKEREOF

# Create Kubernetes files
mkdir -p k8s

cat > k8s/namespace.yaml << 'YAMLEOF'
apiVersion: v1
kind: Namespace
metadata:
  name: flask-app
YAMLEOF

cat > k8s/deployment.yaml << 'YAMLEOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
  namespace: flask-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: flask
  template:
    metadata:
      labels:
        app: flask
    spec:
      containers:
      - name: flask
        image: simple-flask:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 5000
YAMLEOF

cat > k8s/service.yaml << 'YAMLEOF'
apiVersion: v1
kind: Service
metadata:
  name: flask-service
  namespace: flask-app
spec:
  selector:
    app: flask
  ports:
  - port: 5000
    targetPort: 5000
  type: ClusterIP
YAMLEOF

cat > k8s/ingress.yaml << 'YAMLEOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: flask-ingress
  namespace: flask-app
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: flask-service
            port:
              number: 5000
YAMLEOF

# Build image
echo "📦 Building Docker image..."
docker build -t simple-flask:latest ./app

# Delete old cluster if exists
kind delete cluster --name flask-cluster 2>/dev/null || true

# Create cluster
echo "🎯 Creating kind cluster..."
cat > cluster-config.yaml << 'YAMLEOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: flask-cluster
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
YAMLEOF

kind create cluster --config cluster-config.yaml

# Load image
echo "📥 Loading image into cluster..."
kind load docker-image simple-flask:latest --name flask-cluster

# Install Ingress Controller
echo "🔧 Installing Nginx Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "⏳ Waiting for ingress controller..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Deploy app
echo "🚀 Deploying Flask app..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

echo "⏳ Waiting for pods..."
kubectl wait --namespace flask-app \
  --for=condition=ready pod \
  --selector=app=flask \
  --timeout=120s

echo ""
echo "✅ Setup Complete!"
echo ""
echo "🌐 Access your app:"
echo "   http://localhost/"
echo "   http://localhost/api/users"
echo "   http://localhost/api/health"
echo ""
echo "📊 Check status:"
echo "   kubectl get all -n flask-app"
echo "   kubectl get ingress -n flask-app"
echo ""
echo "🔍 View logs:"
echo "   kubectl logs -n flask-app -l app=flask"
echo ""
echo "🗑️  Delete cluster:"
echo "   kind delete cluster --name flask-cluster"
echo ""

