from flask import Flask, jsonify, render_template_string, request

app = Flask(__name__)

HTML_FORM = """
<!DOCTYPE html>
<html>
<head><title>Greeter App</title></head>
<body>
  <h1>Welcome to the Greeter App</h1>
  <form action="/greet" method="post">
    <label for="name">Enter your name:</label>
    <input type="text" id="name" name="name" required>
    <button type="submit">Greet me</button>
  </form>
</body>
</html>
"""


@app.route("/")
def index():
    return render_template_string(HTML_FORM)


@app.route("/greet", methods=["POST"])
def greet():
    name = request.form.get("name", "").strip()
    if not name:
        return jsonify({"error": "Name is required"}), 400
    msg = f"Hello, {name}! Welcome to the DevOps Midterm App."
    return jsonify({"message": msg})


@app.route("/health")
def health():
    return jsonify({"status": "ok", "version": "1.0"})


if __name__ == "__main__":
    import os

    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
