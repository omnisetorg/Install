# The way of doing was inspired by OmaKub. - https://github.com/basecamp/omakub/blob/master/install/terminal/select-dev-language.sh

# Install default programming languages
if AVAILABLE_LANGUAGES=("Node.js" "Go" "PHP" "Python" "Ruby on Rails" "Elixir" "Rust" "Java")
	languages=$(gum choose "${AVAILABLE_LANGUAGES[@]}" --no-limit --height 10 --header "Select programming languages")
fi

if [[ -n "$languages" ]]; then
	for language in $languages; do
		case $language in
		Node.js)
			mise use --global node@lts
			;;
		Go)
			mise use --global go@latest
			;;
		PHP)
			sudo add-apt-repository -y ppa:ondrej/php
			sudo apt -y install php8.4 php8.4-{curl,apcu,intl,mbstring,opcache,pgsql,mysql,sqlite3,redis,xml,zip}
			php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
			php composer-setup.php --quiet && sudo mv composer.phar /usr/local/bin/composer
			rm composer-setup.php
			;;
		Python)
			mise use --global python@latest
			;;
		Elixir)
			mise use --global erlang@latest
			mise use --global elixir@latest
			mise x elixir -- mix local.hex --force
			;;
 		Ruby)
			mise use --global ruby@3.3
			mise x ruby -- gem install rails --no-document
			;;
		Rust)
			bash -c "$(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs)" -- -y
			;;
		Java)
			mise use --global java@latest
			;;
		esac
	done
fi