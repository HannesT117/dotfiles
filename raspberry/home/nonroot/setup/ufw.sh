# conf
# DEFAULT_FORWARD_POLICY="ACCEPT"
ufw status
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.0.0/24 to any port 22
sudo ufw allow from 192.168.0.0/24 to any port 53
sudo ufw allow                     to any port 5678 proto tcp # n8n Webhooks
sudo ufw allow from 192.168.0.0/24 to any port 8000 proto tcp # Paperless
sudo ufw allow from 192.168.0.0/24 to any port 8080 proto tcp # n8n
sudo ufw allow                     to any port 8443 proto tcp # n8n Webhooks
sudo ufw allow from 192.168.0.0/24 to any port 8384 proto tcp # Syncthing
sudo ufw allow from 192.168.0.0/24 to any port 9000 proto tcp # ddns
sudo ufw allow from 192.168.0.0/24 to any port 9080 proto tcp # cooklang

# Allow syncthing discovery, see https://github.com/syncthing/syncthing/tree/main/etc/firewall-ufw
sudo ufw app update syncthing
sudo ufw allow syncthing

sudo ufw show added
sudo ufw enable
sudo ufw status
