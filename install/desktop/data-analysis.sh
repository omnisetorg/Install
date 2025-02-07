#!/bin/bash

arch=$(dpkg --print-architecture)

AVAILABLE_APPS=(
    "Jupyter"
    "VSCode Data Science"
    "Tableau"
    "PowerBI"
    "Apache Superset"
    "Metabase"
    "Apache Spark"
)

# Install dependencies
sudo apt update && sudo apt install -y \
    python3-pip \
    python3-venv \
    default-jdk \
    gum

# Create Python virtual environment
python3 -m venv ~/.venv/data-analysis
source ~/.venv/data-analysis/bin/activate

apps=$(gum choose "${AVAILABLE_APPS[@]}" --no-limit --height 10 --header "Select data analysis tools to install")

if [[ -n "$apps" ]]; then
    for app in $apps; do
        case $app in
        "Jupyter")
            pip install \
                jupyter \
                jupyterlab \
                notebook \
                pandas \
                numpy \
                matplotlib \
                seaborn \
                scikit-learn \
                plotly \
                dash \
                statsmodels
            
            # Install Jupyter extensions
            pip install \
                jupyter_contrib_nbextensions \
                jupyter_nbextensions_configurator
            
            jupyter contrib nbextension install --user
            jupyter nbextensions_configurator enable --user
            ;;
            
        "VSCode Data Science")
            # Install VSCode if not present
            if ! command -v code &> /dev/null; then
                case $arch in
                    amd64)
                        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
                        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg
                        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
                        sudo apt update
                        sudo apt install -y code
                        rm packages.microsoft.gpg
                        ;;
                    *)
                        echo "VSCode not available for $arch"
                        continue
                        ;;
                esac
            fi
            
            # Install Data Science extensions
            code --install-extension ms-python.python
            code --install-extension ms-toolsai.jupyter
            code --install-extension ms-toolsai.jupyter-keymap
            code --install-extension ms-toolsai.jupyter-renderers
            ;;
            
        "Tableau")
            echo "Tableau requires manual installation. Please visit Tableau's website."
            ;;
            
        "PowerBI")
            echo "PowerBI requires manual installation. Please visit Microsoft's website."
            ;;
            
        "Apache Superset")
            # Install Docker if not present
            if ! command -v docker &> /dev/null; then
                curl -fsSL https://get.docker.com -o get-docker.sh
                sudo sh get-docker.sh
                sudo usermod -aG docker $USER
                rm get-docker.sh
            fi
            
            docker pull apache/superset
            docker run -d -p 8088:8088 --name superset apache/superset
            ;;
            
        "Metabase")
            # Install Docker if not present
            if ! command -v docker &> /dev/null; then
                curl -fsSL https://get.docker.com -o get-docker.sh
                sudo sh get-docker.sh
                sudo usermod -aG docker $USER
                rm get-docker.sh
            fi
            
            docker pull metabase/metabase
            docker run -d -p 3000:3000 --name metabase metabase/metabase
            ;;
            
        "Apache Spark")
            # Install Scala
            sudo apt install -y scala
            
            # Download and install Spark
            wget -O spark.tgz "https://dlcdn.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz"
            sudo tar -xzf spark.tgz -C /opt/
            rm spark.tgz
            
            # Set up environment variables
            echo 'export SPARK_HOME=/opt/spark-3.5.0-bin-hadoop3' >> ~/.bashrc
            echo 'export PATH=$PATH:$SPARK_HOME/bin' >> ~/.bashrc
            ;;
    esac
        
        if [ $? -eq 0 ]; then
            echo "✓ Successfully installed $app"
        else
            echo "✗ Failed to install $app"
        fi
    done
fi

# Install additional Python data science packages
echo "Would you like to install additional Python data science packages? (y/N)"
read -r install_extras

if [[ "$install_extras" =~ ^[Yy]$ ]]; then
    pip install \
        tensorflow \
        torch \
        keras \
        xgboost \
        lightgbm \
        opencv-python \
        nltk \
        gensim \
        spacy
fi

# Create data analysis directory structure
mkdir -p ~/DataAnalysis/{datasets,notebooks,models,reports,visualizations}

echo "Data Analysis tools installation complete!"