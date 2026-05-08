#!/bin/bash
set -euo pipefail

# Fetch instance ID via IMDSv2
IMDS_TOKEN=$(curl -sf -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -sf -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

# Download GateWatch agent from S3
aws s3 cp "s3://${releases_bucket}/agent-linux-arm64" /usr/local/bin/gatewatch-agent
chmod +x /usr/local/bin/gatewatch-agent

# Environment file
mkdir -p /etc/gatewatch
cat > /etc/gatewatch/environment << EOF
API_URL=${api_url}
API_TOKEN=${api_token}
INSTANCE_ID=$INSTANCE_ID
HEARTBEAT_INTERVAL=60
RELEASES_BUCKET=${releases_bucket}
EOF
chmod 600 /etc/gatewatch/environment

# Systemd service
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
