#!/bin/bash -e

on_chroot << EOF
function error {
  echo -e "\\e[91m$1\\e[39m"
  exit 1
}

function check_internet() {
  printf "Checking if you are online..."
  wget -q --spider http://github.com
  if [ $? -eq 0 ]; then
    echo "Online. Continuing."
  else
    error "Offline. Go connect to the internet then run the script again."
  fi
}

check_internet

curl -sSL https://get.docker.com | sh || error "Failed to install Docker."
usermod -aG docker $FIRST_USER_NAME || error "Failed to add user to the Docker usergroup."
systemctl enable docker
EOF
