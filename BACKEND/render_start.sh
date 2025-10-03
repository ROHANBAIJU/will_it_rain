#!/bin/bash
# Render startup script

# Use PORT from Render environment (defaults to 8000 for local)
export PORT=${PORT:-8000}

echo "🚀 Starting Will It Rain API on port $PORT..."

# Start Uvicorn with dynamic port
uvicorn app.main:app --host 0.0.0.0 --port $PORT
