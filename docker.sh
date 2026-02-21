#!/bin/bash
######################################################################################
# Docker setup script for TravelMemory application
# This script creates a Docker network, sets up a MongoDB container,
# and builds/runs the backend and frontend containers.  
# Author - Vikram Hem Chandar
# Date - 22-Feb-2026
######################################################################################

echo "Creating Docker network"
docker network create --driver bridge travelmemory

echo "Creating MongoDB volume"
docker volume create mongo_data

echo "Running MongoDB container"
docker run -d -p 27017:27017 --name mongo --network travelmemory -v mongo_data:/data/db mongo

echo "List of all containers in travelmemory network-1"
docker ps --filter "network=travelmemory"

cd ~/code/TravelMemory/backend

echo "Building backend container"
docker build -t travelmemory_backend .

echo "Running backend container"
docker run -d -p 3001:3001 --network travelmemory travelmemory_backend:latest

echo "List of all containers in travelmemory network-2"
docker ps --filter "network=travelmemory"

cd ~/code/TravelMemory/frontend

echo "Building frontend container"
docker build -t travelmemory_frontend .

echo "Running frontend container"
docker run -d -p 3000:3000 --network travelmemory travelmemory_frontend:latest

echo "List of all containers in travelmemory network-3"
docker ps --filter "network=travelmemory"

echo "End of Docker setup script"