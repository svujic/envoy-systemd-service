#!/bin/bash
# setup script for unprivileged envoy systemd service
# sv.svujicATgmail.com

set -e

# *** START of configuration part ***
# name of envoy binary on your system
ENVOY_BIN_NAME="envoy"
# name of user that will own the service
USER="envoy"
# a group that user belong
GROUP="$USER"
# user home directory
USER_HOME="/home/envoy-proxy"
# envoy config file destination
CONF_FILE="/etc/envoy.yaml"
# command line parameter for envoy binary named '--service-cluster'
SERVICE_CLUSTER="envoy-cluster"
# command line parameter for envoy binary named '--service-node'
SERVICE_NODE="10-24"
# *** END of configuration part ***

err_exit() {
    echo -e "$1. Stopped!" >&2
    exit 1
}

# if we can't find envoy binary finish script
ENVOY_BIN_PATH="$(which $ENVOY_BIN_NAME)" || true
[ -z "${ENVOY_BIN_PATH}" ] && {
err_exit "can't find envoy binary named: $ENVOY_BIN_NAME\n\
search for ENVOY_BIN_NAME in this script and tune it accordingly"
}

# if we can't find any of essential files below finish script
for fname in envoy.yaml hot-restarter.py; do
    [ ! -f $fname ] && err_exit "can't find $fname in current directory $PWD"
done

create_script() {
SCRIPT_NAME="$USER_HOME/start_envoy.sh"

START_EVNOY_BASH="\
#!/bin/bash

exec $ENVOY_BIN_PATH -c $CONF_FILE \\
    --restart-epoch \$RESTART_EPOCH \\
    --service-cluster $SERVICE_CLUSTER \\
    --service-node $SERVICE_NODE \\
    --log-level "info" \\
    --log-path "/dev/stdout" | /usr/bin/tee
"

cat > "$SCRIPT_NAME" <<EOF
$START_EVNOY_BASH
EOF

chown $USER:$GROUP "$SCRIPT_NAME"
chmod 744 "$SCRIPT_NAME"
}

create_service() {
SERVICE_NAME="/lib/systemd/system/envoy.service"

ENVOY_SERVICE="\
[Unit]
Description=Envoy proxy service
Requires=network-online.target
After=network-online.target

[Service]
Type=simple
User=$USER
Group=$GROUP
ExecStart=$USER_HOME/hot-restarter.py $USER_HOME/start_envoy.sh
ExecReload=/bin/kill -HUP \$MAINPID
ExecStop=/bin/kill -TERM \$MAINPID
Restart=always
LimitNOFILE=102400
Capabilities=CAP_NET_BIND_SERVICE+ep
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
SecureBits=keep-caps

[Install]
WantedBy = multi-user.target
"

cat > "$SERVICE_NAME" <<EOF
$ENVOY_SERVICE
EOF

chmod 644 "$SERVICE_NAME"
}

case "$1" in
    install)
        adduser --system --disabled-password --disabled-login \
                --home "$USER_HOME" --force-badname \
                --quiet --group $USER || true
        
        cp envoy.yaml "$CONF_FILE"

        cp hot-restarter.py "$USER_HOME/hot-restarter.py"
        chown $USER:$GROUP "$USER_HOME/hot-restarter.py"
        chmod 744 "$USER_HOME/hot-restarter.py"
        
        create_script
        create_service
    ;;

    *)
        err_exit "unknown argument: $1"
    ;;
esac
