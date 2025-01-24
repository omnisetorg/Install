# The way of doing was inspired by OmaKub. - https://github.com/basecamp/omakub/blob/master/install/terminal/select-dev-storage.sh

# Install default databases

AVAILABLE_DBS=("MySQL" "Redis" "PostgreSQL" "MongoDB" "MariaDB")
dbs=$(gum choose "${AVAILABLE_DBS[@]}" --no-limit --height 5 --header "Select databases (runs in Docker)")

if [[ -n "$dbs" ]]; then
	for db in $dbs; do
		case $db in
		MySQL)
			read -p "Enter MySQL root password (leave empty for no password): " MYSQL_ROOT_PASSWORD
			sudo docker run -d --restart unless-stopped -p "127.0.0.1:3306:3306" \
				--name=mysql8 \
				-e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-} \
				-e MYSQL_ALLOW_EMPTY_PASSWORD=${MYSQL_ROOT_PASSWORD:+false} \
				mysql:8.4
			;;
		Redis)
			sudo docker run -d --restart unless-stopped -p "127.0.0.1:6379:6379" \
				--name=redis \
				redis:7
			;;
		PostgreSQL)
			sudo docker run -d --restart unless-stopped -p "127.0.0.1:5432:5432" \
				--name=postgres16 \
				-e POSTGRES_HOST_AUTH_METHOD=trust \
				postgres:16
			;;
		MongoDB)
			sudo docker run -d --restart unless-stopped -p "127.0.0.1:27017:27017" \
				--name=mongo \
				mongo:6
			;;
		MariaDB)
			read -p "Enter MariaDB root password (leave empty for no password): " MARIADB_ROOT_PASSWORD
			sudo docker run -d --restart unless-stopped -p "127.0.0.1:3307:3306" \
				--name=mariadb \
				-e MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-} \
				mariadb:10.6
			;;
		*)
			echo "Unknown database: $db"
			;;
		esac
	done
fi