FROM python:3.11-slim
WORKDIR /app

ENV PYTHONUNBUFFERED=1
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app
WORKDIR /app/app

ENV PORT=8080
EXPOSE 8080
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "main:app"]
