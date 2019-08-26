#!/bin/bash -xe
##
# Installs Cloud SQL Proxy - https://cloud.google.com/sql/docs/mysql/sql-proxy
##
sudo curl -L -s --retry 5 --retry-max-time 10 -o /usr/local/bin/cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64
sudo chmod +x /usr/local/bin/cloud_sql_proxy

# Create a service
sudo mkdir -p /etc/systemd/system/cloud_sql_proxy.service.d/
sudo tee -a /etc/systemd/system/cloud_sql_proxy.service << 'EOF'
[Unit]
Description=GCP CloudSQL Proxy
Requires=network.target
After=network.target

[Service]
User=root
Group=root
Type=simple
WorkingDirectory=/usr/local/bin/
ExecStart=/usr/local/bin/cloud_sql_proxy -instances=${INSTANCE_CONNECTION_NAME}=tcp:3306
Restart=always
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

sudo tee -a /etc/systemd/system/cloud_sql_proxy.service.d/settings.conf.template << 'EOF'
[Service]
Environment=INSTANCE_CONNECTION_NAME=[YOUR CONNECTION NAME]
EOF

#sudo systemctl daemon-reload
#sudo systemctl enable cloud_sql_proxy
#sudo systemctl start cloud_sql_proxy