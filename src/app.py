from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello from my-app running in Docker + Jenkins + ArgoCD!"

@app.route("/echo", methods=["GET"])
def echo():
    msg = request.args.get("msg", "no message")
    return jsonify({"echo": msg})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
