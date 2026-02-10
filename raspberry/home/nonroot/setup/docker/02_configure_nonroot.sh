# as nonroot
/usr/bin/dockerd-rootless-setuptool.sh install

echo "export DOCKER_HOST=/run/user/1002/docker.sock" > ~/.bashrc
echo "export PATH=/usr/bin:\$PATH" > ~/.bashrc

# Start docker after restart, also for non-root user
systemctl --user enable docker
loginctl enable-linger $(whoami)
