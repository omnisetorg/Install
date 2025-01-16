# Step 1: Stop the MariaDB service
sudo systemctl stop mariadb

# Step 2: Uninstalling the MariaDB service
sudo apt-get remove --purge mariadb-server mariadb-client mariadb-common -y