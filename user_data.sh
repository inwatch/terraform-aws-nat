#!/bin/sh

# fck-nat setup
: > /etc/fck-nat.conf
echo "eni_id=${eni_id}" >> /etc/fck-nat.conf
echo "eip_id=${eip_id}" >> /etc/fck-nat.conf
echo "cwagent_enabled=" >> /etc/fck-nat.conf
echo "cwagent_cfg_param_name=" >> /etc/fck-nat.conf
service fck-nat restart

# GateWatch agent — installation versionnée avec symlink
mkdir -p /usr/local/bin /var/lib/gatewatch

aws s3 cp "s3://${releases_bucket}/agent-linux-arm64-${agent_version}" \
  "/usr/local/bin/gatewatch-agent-${agent_version}"
chmod +x "/usr/local/bin/gatewatch-agent-${agent_version}"
ln -sf "/usr/local/bin/gatewatch-agent-${agent_version}" /usr/local/bin/gatewatch-agent

mkdir -p /etc/gatewatch
cat > /etc/gatewatch/environment << ENVEOF
API_URL=${api_url}
API_TOKEN=${api_token}
HEARTBEAT_INTERVAL=60
RELEASES_BUCKET=${releases_bucket}
ENVEOF
chmod 600 /etc/gatewatch/environment

# Script de rollback — restaure la version précédente si le service entre en état failed
cat > /usr/local/bin/gatewatch-rollback.sh << 'ROLLBACKEOF'
#!/bin/sh
PREV=$(cat /var/lib/gatewatch/previous_version 2>/dev/null)
if [ -n "$PREV" ] && [ -f "$PREV" ]; then
  ln -sf "$PREV" /usr/local/bin/gatewatch-agent
  logger "gatewatch-agent: rollback vers $PREV"
  systemctl reset-failed gatewatch-agent
  systemctl start gatewatch-agent
else
  logger "gatewatch-agent: rollback impossible — aucune version précédente trouvée"
fi
ROLLBACKEOF
chmod +x /usr/local/bin/gatewatch-rollback.sh

# Service systemd principal
cat > /etc/systemd/system/gatewatch-agent.service << 'SVCEOF'
[Unit]
Description=GateWatch Agent
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
EnvironmentFile=/etc/gatewatch/environment
ExecStart=/usr/local/bin/gatewatch-agent
Restart=on-failure
RestartSec=5
StartLimitIntervalSec=60
StartLimitBurst=3
OnFailure=gatewatch-agent-rollback.service
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVCEOF

# Service de rollback (one-shot déclenché par OnFailure)
cat > /etc/systemd/system/gatewatch-agent-rollback.service << 'ROLLBACKSVCEOF'
[Unit]
Description=GateWatch Agent Rollback
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/gatewatch-rollback.sh
ROLLBACKSVCEOF

systemctl daemon-reload
systemctl enable gatewatch-agent
systemctl start gatewatch-agent
