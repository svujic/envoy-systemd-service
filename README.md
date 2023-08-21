## About

Install unprivileged (non root) envoy systemd service with hot reload capability

## Requirements

1. Linux system (tested on Ubuntu 22.04.1 LTS)
1. Envoy binary
1. Python3
1. root privileges

## How to setup and run

After cloning this project you should check setup.sh and change config variables (if any) to your likings.

than you can run:

```
cd envoy-systemd-service
setup.sh install
systemctl daemon-reload
systemctl start envoy.service
```

to start the service.

for reload run:

```
systemctl reload envoy.service
```

for status run:

```
systemctl status envoy.service
```

for logging journal run:

```
journalctl -xeu envoy.service
```

## License

This project is released under the MIT license.

You are free to use, modify and distribute this software, as long as the copyright header is left intact
