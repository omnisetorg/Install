#!/bin/bash

arch=$(dpkg --print-architecture)

AVAILABLE_APPS=(
    "Zotero"
    "Mendeley"
    "LaTeX"
    "R-Studio"
    "SPSS"
    "SciDAVis"
    "Anki"
    "Mathpix"
    "JASP"
)

# Dependency installation
sudo apt update && sudo apt install -y \
    gum \
    wget \
    curl \
    python3-pip \
    default-jre

apps=$(gum choose "${AVAILABLE_APPS[@]}" --no-limit --height 10 --header "Select academic/research tools to install")

if [[ -n "$apps" ]]; then
    for app in $apps; do
        case $app in
        "Zotero")
            wget -qO- https://raw.githubusercontent.com/retorquere/zotero-deb/master/install.sh | sudo bash
            sudo apt update && sudo apt install -y zotero
            ;;
            
        "Mendeley")
            case $arch in
                amd64)
                    wget -O mendeley.deb "https://www.mendeley.com/repositories/ubuntu/stable/amd64/mendeleydesktop-latest"
                    ;;
                *)
                    echo "Mendeley not available for $arch"
                    continue
                    ;;
            esac
            sudo dpkg -i mendeley.deb
            sudo apt-get install -f -y
            rm mendeley.deb
            ;;
            
        "LaTeX")
            sudo apt install -y \
                texlive-full \
                texmaker \
                texstudio \
                latexmk \
                biber \
                chktex
            ;;
            
        "R-Studio")
            # Install R first
            sudo apt install -y r-base r-base-dev

            case $arch in
                amd64)
                    wget -O rstudio.deb "https://download1.rstudio.org/desktop/bionic/amd64/rstudio-latest-amd64.deb"
                    ;;
                *)
                    echo "RStudio not available for $arch"
                    continue
                    ;;
            esac
            sudo dpkg -i rstudio.deb
            sudo apt-get install -f -y
            rm rstudio.deb
            
            # Install common R packages
            Rscript -e 'install.packages(c("tidyverse", "rmarkdown", "knitr", "shiny"), repos="https://cran.rstudio.com/")'
            ;;
            
        "SPSS")
            echo "SPSS requires manual installation. Please visit IBM's website."
            echo "Consider using PSPP as an open-source alternative? (y/N)"
            read -r install_pspp
            if [[ "$install_pspp" =~ ^[Yy]$ ]]; then
                sudo apt install -y pspp
            fi
            ;;
            
        "SciDAVis")
            sudo apt install -y scidavis
            ;;
            
        "Anki")
            sudo apt install -y anki
            ;;
            
        "Mathpix")
            case $arch in
                amd64)
                    wget -O mathpix.deb "https://mathpix.com/download/linux/latest"
                    sudo dpkg -i mathpix.deb
                    sudo apt-get install -f -y
                    rm mathpix.deb
                    ;;
                *)
                    echo "Mathpix not available for $arch"
                    continue
                    ;;
            esac
            ;;
            
        "JASP")
            sudo add-apt-repository -y ppa:jasp-stats/jasp
            sudo apt update && sudo apt install -y jasp
            ;;
    esac
        
        if [ $? -eq 0 ]; then
            echo "✓ Successfully installed $app"
        else
            echo "✗ Failed to install $app"
        fi
    done
fi

# Install citation management tools
echo "Would you like to install additional citation management tools? (y/N)"
read -r install_citation

if [[ "$install_citation" =~ ^[Yy]$ ]]; then
    sudo apt install -y \
        pandoc \
        pandoc-citeproc \
        bibutils \
        jabref
fi

# Create research directory structure
mkdir -p ~/Research/{papers,data,analysis,manuscripts,bibliography}

echo "Academic/Research tools installation complete!"