#!/bin/bash -xe

if [ -f /etc/grafana/grafana.ini.bak ]; then
    echo "Grafana: Custom configuration already presented."
    exit 0
fi

# TODO: Add smtp
sudo mv /etc/grafana/grafana.ini /etc/grafana/grafana.ini.bak
sudo tee /etc/grafana/grafana.ini <<EOF
[database]
type=${DB_TYPE}
host=${DB_HOST}
name=${DB_NAME}
user=${DB_USER}
password="""${DB_PASS}"""
# For Postgres, use either disable, require or verify-full.
# For MySQL, use either true, false, or skip-verify.
ssl_mode=${DB_SSL_MODE}

[security]
admin_user=${GRAFANA_ADMIN}
admin_password=${GRAFANA_ADMIN_PASS}

[users]
allow_sign_up=false
allow_org_create=false

[analytics]
# This is a benchmark environment, there should be minimal additional connections.
reporting_enabled=false
check_for_updates=false
EOF

sudo systemctl restart grafana-server
