# Local n8n with Caddy, Porkbun, ddns-updater, and Tailscale

This configuration sets up an instance of [n8n](https://n8n.io) which is accessible from the current network. Expects to be named pi5.local on a local network. It exposes webhook endpoints publicly assuming that the domain used is managed by [Porkbun](https://porkbun.com). Dynamic DNS entries updated by ddns-updater. Over internet accessible using Tailscale. Deployment with docker compose. Inteded for usage on a raspi5.
