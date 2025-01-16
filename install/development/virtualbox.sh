# Step 1: Install VirtualBox
sudo apt install -y virtualbox virtualbox-ext-pack

# Step 2: Add user to vboxusers group
sudo usermod -aG vboxusers ${USER}