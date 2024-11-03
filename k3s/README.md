# k3s

Lightweight Kubernetes, perfect for a handful of small nodes on a single NUC.

## SSH to nodes

Another device on the home network can reach the control plane through the public IP address. Nodes are on a private subnet, so the external device (macbook) needs to setup a SSH tunnel and then SSH through this tunnel into a node.

In `/etc/ssh/sshd_config` set `GatewayPorts yes`.

Setup the tunnel to a node:

`ssh -L 2222:private-ip:ssh-port daniel@cluster.fuck`

Connect to a node:

`ssh -p 2222 daniel@localhost`
