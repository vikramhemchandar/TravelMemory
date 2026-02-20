FROM node:22

# Create app directory
WORKDIR /app

# Copy package files first (better caching)
COPY . .

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Expose app port (change if your app uses a different port)
EXPOSE 3000

# Start the app
CMD ["npm", "start"]