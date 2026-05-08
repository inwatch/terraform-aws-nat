#!/bin/sh

# fck-nat setup
: > /etc/fck-nat.conf
echo "eni_id=${eni_id}" >> /etc/fck-nat.conf
echo "eip_id=${eip_id}" >> /etc/fck-nat.conf
echo "cwagent_enabled=" >> /etc/fck-nat.conf
echo "cwagent_cfg_param_name=" >> /etc/fck-nat.conf
service fck-nat restart

# GateWatch agent
aws s3 cp "s3://${releases_bucket}/agent-linux-arm64" /usr/local/bin/gatewatch-agent
chmod +x /usr/local/bin/gatewatch-agent

mkdir -p /etc/gatewatch
cat > /etc/gatewatch/environment << ENVEOF
API_URL=${api_url}
API_TOKEN=${api_token}
HEARTBEAT_INTERVAL=60
RELEASES_BUCKET=${releases_bucket}
ENVEOF
chmod 600 /etc/gatewatch/environment

cat > /etc/systemd/system/gatewatch-agent.service << 'SVCEOF'
[Unit]
Description=GateWatch Agent
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
EnvironmentFile=/etc/gatewatch/environment
ExecStart=/usr/local/bin/gatewatch-agent
Restart=always
RestartSec=30
StartLimitIntervalSec=0

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable gatewatch-agent
systemctl start gatewatch-agent
