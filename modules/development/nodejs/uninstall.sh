#!/bin/bash
sudo apt-get remove -y nodejs
sudo rm -f /etc/apt/sources.list.d/nodesource.list
echo "Node.js removed"
