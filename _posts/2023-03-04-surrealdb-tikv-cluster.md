---
layout: post
title: SurrealDB TiKV Cluster with LXC
date: 2023-03-04 17:37:29+0100
comments: true
---

In this post, I will show you how to set up a distributed SurrealDB cluster that shares a distributed TiKV cluster.
This architecture allows you to scale your operations to improve writes and reads and seamlessly continue operations during failures.

# Introduction and architecture overview

Users of SurrealDB can pick which Key-Value storage engines they want to use.
That means that for single deployment, you can use RocksDB or in-memory storage; for distributed storage, you can use TiKV and FoundationDB.

We will deploy a cluster of TiKV that includes 3 TiKV instances (the KV engine) and 3 PD instances (placement driver, a resource tracking service).
In addition to the above configuration, we will deploy three nodes of SurrealDB that will point to their respective KV engines.
Typically you would want the SurrealDB instances not tied to individual TiKV instances, but that would require a load balancer - something beyond the scope of this article.

# Setting up the environment

Because we need access to 6 machines, we will simplify this setup using LXC - a lightweight Linux container system that makes nodes seem like fully-fledged computers.

**An important note**: LXC does not play nice with docker.
There are ways around that, but I removed docker from my host machine for this example.
It's a VM; usually, you wouldn't host this environment this way anyway.

Let's start by running and configuring our first LXC container for usage.

```bash
hugh@hugh-VirtualBox:~$ lxc launch ubuntu: lxc-node-tikv-1
Creating lxc-node-tikv-1
Starting lxc-node-tikv-1
hugh@hugh-VirtualBox:~$ lxc exec lxc-node-tikv-1 bash
root@lxc-node-tikv-1:~# apt install openssh-server
...
root@lxc-node-tikv-1:~# curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 7088k  100 7088k    0     0  2571k      0  0:00:02  0:00:02 --:--:-- 2570k
WARN: adding root certificate via internet: https://tiup-mirrors.pingcap.com/root.json
You can revoke this by remove /root/.tiup/bin/7b8e153f2e2d0928.root.json
Successfully set mirror to https://tiup-mirrors.pingcap.com
Detected shell:
Shell profile:  /root/.profile
/root/.profile has been modified to add tiup to PATH
open a new terminal or source /root/.profile to use it
Installed path: /root/.tiup/bin/tiup
===============================================
Have a try:     tiup playground
===============================================
root@lxc-node-tikv-1:~# sudo useradd -m hugh
root@lxc-node-tikv-1:~# sudo adduser hugh sudo
Adding user `hugh' to group `sudo' ...
Adding user hugh to group sudo
Done.
root@lxc-node-tikv-1:~# sudo passwd hugh
New password:
Retype new password:
passwd: password updated successfully
root@lxc-node-tikv-1:~# sudo visudo # Over here I replaced the sudo entry line with "%sudo ALL=(ALL) NOPASSWD:ALL", so added NOPASSWD
root@lxc-node-tikv-1:~# vim /etc/ssh/sshd_config
# Change the following lines
# PasswordAuthentication yes
root@lxc-node-tikv-1:~# source .profile
root@lxc-node-tikv-1:~# tiup cluster
tiup is checking updates for component cluster ...timeout(2s)!
The component `cluster` version  is not installed; downloading from repository.
download https://tiup-mirrors.pingcap.com/cluster-v1.11.3-linux-amd64.tar.gz 8.44 MiB / 8.44 MiB 100.00% 396.61 MiB/s
Starting component `cluster`: /root/.tiup/components/cluster/v1.11.3/tiup-cluster
Deploy a TiDB cluster for production
...
root@lxc-node-tikv-1:~# tiup update --self && tiup update cluster
download https://tiup-mirrors.pingcap.com/tiup-v1.11.3-linux-amd64.tar.gz 6.92 MiB / 6.92 MiB 100.00% 171.31 MiB/s
Updated successfully!
component cluster version v1.11.3 is already installed
Updated successfully!
root@lxc-node-tikv-1:~# tiup cluster template > topology.yaml
tiup is checking updates for component cluster ...
Starting component `cluster`: /root/.tiup/components/cluster/v1.11.3/tiup-cluster template
```

Great!
We now have our initial node ready.
We need to modify our topology file to reflect the actual topology we will have.
Here is the sample I have from editing the `topology.yaml` we just exported.

```yaml
# # Global variables are applied to all deployments and used as the default value of
# # the deployments if a specific deployment value is missing.
global:
  # # The user who runs the tidb cluster.
  user: "hugh"
  # # group is used to specify the group name the user belong to if it's not the same as user.
  # group: "tidb"
  # # SSH port of servers in the managed cluster.
  ssh_port: 22
  # # Storage directory for cluster deployment files, startup scripts, and configuration files.
  deploy_dir: "/tidb-deploy"
  # # TiDB Cluster data storage directory
  data_dir: "/tidb-data"
  arch: "amd64"

# # Monitored variables are applied to all the machines.
monitored:
  # # The communication port for reporting system information of each node in the TiDB cluster.
  node_exporter_port: 9100
  # # Blackbox_exporter communication port, used for TiDB cluster port monitoring.
  blackbox_exporter_port: 9115

# # Server configs are used to specify the configuration of PD Servers.
pd_servers:
  # # The ip address of the PD Server.
  - host: lxc-node-pd-1
  - host: lxc-node-pd-2
  - host: lxc-node-pd-3

# # Server configs are used to specify the configuration of TiKV Servers.
tikv_servers:
  # # The ip address of the TiKV Server.
  - host: lxc-node-tikv-1
  - host: lxc-node-tikv-2
  - host: lxc-node-tikv-3
```

That is actually my entire topology.yaml file.
I removed TiDB and all the monitoring - we aren't using that for this example.

We will create a snapshot from the image to simplify our setup and start the installation.
We will then create instances that automatically have SSH, the hugh account with a known password, and a sudo group permission without password authentication.
Don't do this in production - this is a highly insecure setup for many reasons.

```
root@lxc-node-tikv-1:~# shutdown -r 0
hugh@hugh-VirtualBox:~$ lxc snapshot lxc-node-tikv-1 base-installation-tikv
hugh@hugh-VirtualBox:~$ lxc publish lxc-node-tikv-1/base-installation-tikv --alias base-installation-tikv
Instance published with fingerprint: b8841a679a59f98f3c23ba6c8795c84942f19170b4a8c41eb102130467c4cca6
hugh@hugh-VirtualBox:~$ printf "lxc-node-tikv-2\n lxc-node-tikv-3\n lxc-node-pd-1\n lxc-node-pd-2\n lxc-node-pd-3" | xargs -I % lxc launch base-installation-tikv %
Creating lxc-node-tikv-2
Starting lxc-node-tikv-2
Creating lxc-node-tikv-3
Starting lxc-node-tikv-3
Creating lxc-node-pd-1
Starting lxc-node-pd-1
Creating lxc-node-pd-2
Starting lxc-node-pd-2
Creating lxc-node-pd-3
Starting lxc-node-pd-3
```

We can now start our cluster from the first node we configured.
TiUp will connect to all the other nodes via SSH and password authentication and install the services that way.

```
hugh@hugh-VirtualBox:~$ lxc exec lxc-node-tikv-1 bash
root@lxc-node-tikv-1:~# source .profile
root@lxc-node-tikv-1:~# tiup cluster deploy tikv-test v6.6.0 ./topology.yaml --user hugh -p
tiup is checking updates for component cluster ...
Starting component `cluster`: /root/.tiup/components/cluster/v1.11.3/tiup-cluster deploy tikv-test v6.6.0 ./topology.yaml --user hugh -p
Input SSH password:





+ Detect CPU Arch Name
+ Detect CPU Arch Name
  - Detecting node lxc-node-pd-1 Arch info ... Done
  - Detecting node lxc-node-pd-2 Arch info ... Done
  - Detecting node lxc-node-pd-3 Arch info ... Done
  - Detecting node lxc-node-tikv-1 Arch info ... Done
  - Detecting node lxc-node-tikv-2 Arch info ... Done
  - Detecting node lxc-node-tikv-3 Arch info ... Done





+ Detect CPU OS Name
+ Detect CPU OS Name
  - Detecting node lxc-node-pd-1 OS info ... Done
  - Detecting node lxc-node-pd-2 OS info ... Done
  - Detecting node lxc-node-pd-3 OS info ... Done
  - Detecting node lxc-node-tikv-1 OS info ... Done
  - Detecting node lxc-node-tikv-2 OS info ... Done
  - Detecting node lxc-node-tikv-3 OS info ... Done
Please confirm your topology:
Cluster type:    tidb
Cluster name:    tikv-test
Cluster version: v6.6.0
Role  Host             Ports        OS/Arch       Directories
----  ----             -----        -------       -----------
pd    lxc-node-pd-1    2379/2380    linux/x86_64  /tidb-deploy/pd-2379,/tidb-data/pd-2379
pd    lxc-node-pd-2    2379/2380    linux/x86_64  /tidb-deploy/pd-2379,/tidb-data/pd-2379
pd    lxc-node-pd-3    2379/2380    linux/x86_64  /tidb-deploy/pd-2379,/tidb-data/pd-2379
tikv  lxc-node-tikv-1  20160/20180  linux/x86_64  /tidb-deploy/tikv-20160,/tidb-data/tikv-20160
tikv  lxc-node-tikv-2  20160/20180  linux/x86_64  /tidb-deploy/tikv-20160,/tidb-data/tikv-20160
tikv  lxc-node-tikv-3  20160/20180  linux/x86_64  /tidb-deploy/tikv-20160,/tidb-data/tikv-20160
Attention:
    1. If the topology is not what you expected, check your yaml file.
    2. Please confirm there is no port/directory conflicts in same host.
Do you want to continue? [y/N]: (default=N) y
...
Cluster `tikv-test` deployed successfully, you can start it with command: `tiup cluster start tikv-test --init`
root@lxc-node-tikv-1:~# tiup cluster start tikv-test --init
tiup is checking updates for component cluster ...
Starting component `cluster`: /root/.tiup/components/cluster/v1.11.3/tiup-cluster start tikv-test --init
Starting cluster tikv-test...
+ [ Serial ] - SSHKeySet: privateKey=/root/.tiup/storage/cluster/clusters/tikv-test/ssh/id_rsa, publicKey=/root/.tiup/storage/cluster/clusters/tikv-test/ssh/id_rsa.pub
+ [Parallel] - UserSSH: user=hugh, host=lxc-node-tikv-2
+ [Parallel] - UserSSH: user=hugh, host=lxc-node-pd-3
+ [Parallel] - UserSSH: user=hugh, host=lxc-node-pd-2
+ [Parallel] - UserSSH: user=hugh, host=lxc-node-tikv-3
+ [Parallel] - UserSSH: user=hugh, host=lxc-node-tikv-1
+ [Parallel] - UserSSH: user=hugh, host=lxc-node-pd-1
+ [ Serial ] - StartCluster
...
Started cluster `tikv-test` successfully
The root password of TiDB database has been changed.
The new password is: 'JuEzYp59+8@$20T_3K'.
Copy and record it to somewhere safe, it is only displayed once, and will not be stored.
The generated password can NOT be get and shown again.
```

At this point, you should have a running TiKV cluster.
All that remains is to put SurrealDB instances on the PD nodes.
I will demonstrate this only for a single PD node, as the rest are identical.

```
root@lxc-node-pd-1:~# curl --proto '=https' --tlsv1.2 -sSf https://install.surrealdb.com | sh -s -- --nightly

 .d8888b.                                             888 8888888b.  888888b.
d88P  Y88b                                            888 888  'Y88b 888  '88b
Y88b.                                                 888 888    888 888  .88P
 'Y888b.   888  888 888d888 888d888  .d88b.   8888b.  888 888    888 8888888K.
    'Y88b. 888  888 888P'   888P'   d8P  Y8b     '88b 888 888    888 888  'Y88b
      '888 888  888 888     888     88888888 .d888888 888 888    888 888    888
Y88b  d88P Y88b 888 888     888     Y8b.     888  888 888 888  .d88P 888   d88P
 'Y8888P'   'Y88888 888     888      'Y8888  'Y888888 888 8888888P'  8888888P'

Fetching the latest database version...
Fetching the host system architecture...
Installing surreal-nightly for linux-amd64...


SurrealDB successfully installed in:
  /root/.surrealdb/surreal

To ensure that surreal is in your $PATH run:
  PATH=/root/.surrealdb:$PATH
Or to move the binary to --nightly run:
  sudo mv /root/.surrealdb/surreal --nightly

To see the command-line options run:
  surreal help
To start an in-memory database server run:
  surreal start --log debug --user root --pass root memory
For help with getting started visit:
  https://surrealdb.com/docs

root@lxc-node-pd-1:~# PATH=/root/.surrealdb:$PATH
root@lxc-node-pd-1:~# surreal sql --ns testns --db testdb -u root -p root --conn tikv://lxc-node-pd-1:2379
testns/testdb> create person:hugh content {name:'test'}
[{"id":"person:hugh","name":"test"}]
testns/testdb> select * from person
[{"id":"person:hugh","name":"test"}]
```

Under a real scenario, you would have the SurrealDB nodes separate from the PD nodes, and the connections would be load balanced across the entire PD node pool.

# Takeaways

As you can see, it is possible to set up SurrealDB in a cluster so that writes and reads can scale.
Failure of a single node would have minimal disruption to the rest of the work while keeping your data intact.
Backups can be performed against the TiKV cluster to ensure you can recover in the event of serious failures.

Hopefully, you found this guide helpful, and I look forward to hearing what you get up to with it!
