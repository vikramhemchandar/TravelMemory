#!/bin/bash
######################################################################################
# Docker cleanup script for TravelMemory application
# This script stops and removes all containers, networks, and volumes related to the application.
# Author - Vikram Hem Chandar
# Date - 22-Feb-2026
######################################################################################

echo "Stopping and removing all containers in travelmemory network"
docker ps -a --filter "network=travelmemory"
docker stop $(docker ps -aq)
docker system prune -f