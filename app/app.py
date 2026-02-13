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
