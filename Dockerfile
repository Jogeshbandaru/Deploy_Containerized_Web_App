# Use an official Node.js runtime as a parent image (modify based on your application)
FROM node:18-alpine

# Set the working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json package-lock.json ./
RUN npm install

# Copy application files
COPY . .

# Expose application port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
