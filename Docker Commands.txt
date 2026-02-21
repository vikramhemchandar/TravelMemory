Backend env 
MONGO_URI="mongodb://mongo:27017/"
PORT=3001

Frontend env
REACT_APP_BACKEND_URL=https://3001-port-rqjpcay5khml3qoq.labs.kodekloud.com/


--Network create
docker network ls
docker network create --driver bridge travelmemory

-- Volume create
docker volume ls

docker volume create sample_data
docker run -d -p 27017:27017 --name mongo --network travelmemory -v sample_data:/data/db mongo

docker ps --filter "network=travelmemory"

docker inspect <container_ID>
docker logs <container_ID>

-- build frontend and backend
docker build -t travelmemory_backend .
docker build -t travelmemory_frontend .


docker network create mongo_travelmemory --driver bridge mongo
docker run -d -p 3001:3001 --network travelmemory travelmemory_backend:latest 
docker run -d -p 3000:3000 --network travelmemory travelmemory_frontend:latest 

docker ps -a

To get the list of all docker container IDs
docker ps -aq

To Delete :
To remove the max amount of unsed data - stopped conainers, networks, images and cache
>docker system prune -a

To stop all docker running containers
>docker stop $(docker ps -aq)

To delete all docker running containers
>docker rm $(docker ps -aq)

To delete all images
>docker rm $(docker images -aq)

To build with a tag which helps to push to docker hub
>docker build-t vikramhemchandar/travelmemory:frontendv1.0 .
>docker build-t vikramhemchandar/travelmemory:backendv1.0 .

To push the image to docker hub
>docker push vikramhemchandar/travelmemory:frontendv1.0 .
>docker push vikramhemchandar/travelmemory:backendv1.0 .
