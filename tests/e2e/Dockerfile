FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    bash curl wget git sudo lsb-release ca-certificates \
    software-properties-common gpg && \
    rm -rf /var/lib/apt/lists/*

# Non-root user with passwordless sudo (matches real-world usage)
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY . /home/testuser/omniset
RUN chown -R testuser:testuser /home/testuser/omniset

USER testuser
WORKDIR /home/testuser/omniset

ENV OMNISET_ROOT=/home/testuser/omniset
ENV OMNISET_LIB=/home/testuser/omniset/lib
ENV OMNISET_MODULES=/home/testuser/omniset/modules
