# Stage 1: Build the application with its dependencies
FROM python:3.10-slim as builder

WORKDIR /app

# Install poetry for dependency management (good practice)
# Copy and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Create the final, smaller production image
FROM python:3.10-slim

WORKDIR /app

# Copy installed dependencies from the builder stage
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy the application code
COPY ./app /app/app
COPY ./render_start.sh /app/render_start.sh

# Make startup script executable
RUN chmod +x /app/render_start.sh

# Expose port (Render will use this)
EXPOSE 8000

# Command to run the application
# Uses PORT environment variable from Render (defaults to 8000)
CMD ["/bin/bash", "/app/render_start.sh"]