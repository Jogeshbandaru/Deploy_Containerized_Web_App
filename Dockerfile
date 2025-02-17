# Use an official Node.js runtime as a parent image (modify based on your application)
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy application files and install dependencies
COPY . /app
RUN pip install --no-cache-dir -r requirements.txt

# Expose application port
EXPOSE 80

# Start the application
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:80", "app:app"]
