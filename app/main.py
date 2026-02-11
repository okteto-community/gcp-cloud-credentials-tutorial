from flask import Flask, request, render_template
from google.cloud import storage
import os
import time
import uuid

app = Flask(__name__)

BUCKET = os.environ.get("GCS_BUCKET", "")

def upload_string(name: str, content: str) -> str:
    client = storage.Client()
    bucket = client.bucket(BUCKET)
    blob = bucket.blob(name)
    blob.upload_from_string(content)
    return f"https://console.cloud.google.com/storage/browser/_details/{BUCKET}/{name}"


@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        text = request.form.get('text', '')
        fname = f"demo-{int(time.time())}-{uuid.uuid4().hex[:6]}.txt"
        try:
            url = upload_string(fname, text)
            return render_template('index.html', uploaded=True, url=url, name=fname)
        except Exception as e:
            return render_template('index.html', uploaded=True, url=None, error=str(e), name=fname)
    return render_template('index.html', uploaded=False)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
