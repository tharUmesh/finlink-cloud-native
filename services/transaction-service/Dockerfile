FROM python:3.13-slim

WORKDIR /app

# Install deps first (Docker caches this layer — rebuilds are faster)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]