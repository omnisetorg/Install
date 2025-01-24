#  1: Stop and remove all running containers
docker container stop $(docker container ls -aq)
docker container rm $(docker container ls -aq)

# Step 2: Remove Docker-related directories and configuration files
sudo rm -rf /var/lib/docker /etc/docker
sudo rm -rf /var/run/docker.sock /var/run/containerd
sudo rm -rf ~/.docker  # Removes Docker settings for the current user

# Step 3: Uninstall Docker engine and standard plugins
sudo apt purge --auto-remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

# Step 4: Remove Docker group
sudo groupdel docker