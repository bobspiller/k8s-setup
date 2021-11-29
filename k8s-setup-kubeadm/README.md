# Kubernetes cluster setup with Vagrant and Ansible

Based on [Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).

[comment]: <> (Based on this blog post [Kubernetes Setup Using Ansible and Vagrant]&#40;https://kubernetes.io/blog/2019/03/15/kubernetes-setup-using-ansible-and-vagrant/&#41;.)

## Add indented line to text after line matching a pattern

Using `sed` from https://stackoverflow.com/questions/15559359/insert-line-after-match-using-sed

Note escaping the leading spaces!

```
sudo sed -i '/plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options/a \ \ \ \ \ \ \ \ \ \ \ \ SystemdCgroup = true"' /etc/containerd/config.toml
```

## Issues

### Default sysctl configuration has value the kernel doesn't like

This error is logged when running `provision-all.sh`.

```
    k8s-control-1: * Applying /usr/lib/sysctl.d/50-default.conf ...
    k8s-control-1: net.ipv4.conf.default.promote_secondaries = 1
    k8s-control-1: sysctl: setting key "net.ipv4.conf.all.promote_secondaries": Invalid argument
```

Probably the `net.ipv4.conf.*.promote_secondaries = 1` line:
```
# Promote secondary addresses when the primary address is removed
net.ipv4.conf.default.promote_secondaries = 1
net.ipv4.conf.*.promote_secondaries = 1
-net.ipv4.conf.all.promote_secondaries
```

I think this is a red herring the following lines say set `promote_secondaries = 1` on all interface configurations 
*except* the `all` configuration:
```
net.ipv4.conf.*.promote_secondaries = 1
-net.ipv4.conf.all.promote_secondaries
```
The end result is (I think) what we want:
```
vagrant@k8s-control-1:~$ cat /proc/sys/net/ipv4/conf/all/promote_secondaries
0
```

Ref: [sysctl.d (8)](https://manpages.ubuntu.com/manpages/focal/man5/sysctl.d.5.html)

### Weird Vagrant issue

```
==> k8s-master: Waiting for machine to boot. This may take a few minutes...
    k8s-master: SSH address: 127.0.0.1:2222
    k8s-master: SSH username: vagrant
    k8s-master: SSH auth method: private key
    k8s-master: Warning: Authentication failure. Retrying...
    k8s-master: Warning: Authentication failure. Retrying...
    k8s-master: Warning: Authentication failure. Retrying...
    k8s-master: Warning: Authentication failure. Retrying...
```

`vagrnt destroy` and removing the `.vagrant` directory doesn't help.

Tried configuring `vagrant.ssh.username` and `vagrant.ssh.password`.  Nope!
```
==> k8s-master: Waiting for machine to boot. This may take a few minutes...
    k8s-master: SSH address: 127.0.0.1:2222
    k8s-master: SSH username: vagrant
    k8s-master: SSH auth method: password
    k8s-master: Warning: Authentication failure. Retrying...
    k8s-master: Warning: Authentication failure. Retrying...
```

Tried reverting `master.vm.hostname` to match the VM name (used in `config.vm.define`).
No joy!

Tried a new hostname and VM name - k8s-master-1 - nope!

Tried remiving my local Vagrant state (`~/.vagrant.d/), didn't make a difference.

Odd thing.  `vagrant ssh` still authenticates!

```
➜  k8s-setup-kubeadm git:(master) ✗ vagrant up
Bringing machine 'k8s-master-1' up with 'virtualbox' provider...
Bringing machine 'k8s-node-1' up with 'virtualbox' provider...
Bringing machine 'k8s-node-2' up with 'virtualbox' provider...
==> k8s-master-1: Importing base box 'ubuntu/focal64'...
==> k8s-master-1: Matching MAC address for NAT networking...
==> k8s-master-1: Checking if box 'ubuntu/focal64' version '20211026.0.0' is up to date...
==> k8s-master-1: Setting the name of the VM: k8s-setup-kubeadm_k8s-master-1_1638116050722_35426
==> k8s-master-1: Clearing any previously set network interfaces...
==> k8s-master-1: Preparing network interfaces based on configuration...
    k8s-master-1: Adapter 1: nat
    k8s-master-1: Adapter 2: hostonly
==> k8s-master-1: Forwarding ports...
    k8s-master-1: 22 (guest) => 2222 (host) (adapter 1)
==> k8s-master-1: Running 'pre-boot' VM customizations...
==> k8s-master-1: Booting VM...
==> k8s-master-1: Waiting for machine to boot. This may take a few minutes...
    k8s-master-1: SSH address: 127.0.0.1:2222
    k8s-master-1: SSH username: vagrant
    k8s-master-1: SSH auth method: private key
    k8s-master-1: Warning: Connection reset. Retrying...
    k8s-master-1: Warning: Authentication failure. Retrying...
    k8s-master-1: Warning: Authentication failure. Retrying...
    k8s-master-1: Warning: Authentication failure. Retrying...
    k8s-master-1: Warning: Authentication failure. Retrying...
    k8s-master-1: Warning: Authentication failure. Retrying...
^C==> k8s-master-1: Waiting for cleanup before exiting...
Vagrant exited after cleanup due to external interrupt.
Connection to 127.0.0.1 closed.
➜  k8s-setup-kubeadm git:(master) ✗ vagrant ssh k8s-master-1 -- cat ./.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
```

Running `vagrant up --debug` shows:

```
D, [2021-11-28T11:24:51.974569 #62583] DEBUG -- net.ssh.authentication.methods.publickey[3fd13f670804]: public key has been marked for deprecated ssh-rsa SHA1 behavior
```

This issue https://github.com/hashicorp/vagrant/issues/12344

Upgraded to Vagrant 2.2.19 from 2.2.16.  Removed the insecure key.
This appears to have made a difference!

```
➜  k8s-setup-kubeadm git:(master) ✗ vagrant version
\Installed Version: 2.2.19
Latest Version: 2.2.19

You're running an up-to-date version of Vagrant!
➜  k8s-setup-kubeadm git:(master) ✗ rm $HOME/.vagrant.d/insecure_private_key
➜  k8s-setup-kubeadm git:(master) ✗ vagrant up k8s-master-1
Bringing machine 'k8s-master-1' up with 'virtualbox' provider...
==> k8s-master-1: Importing base box 'ubuntu/focal64'...
==> k8s-master-1: Matching MAC address for NAT networking...
==> k8s-master-1: Checking if box 'ubuntu/focal64' version '20211026.0.0' is up to date...
==> k8s-master-1: Setting the name of the VM: k8s-setup-kubeadm_k8s-master-1_1638119817710_31320
==> k8s-master-1: Fixed port collision for 22 => 2222. Now on port 2200.
==> k8s-master-1: Clearing any previously set network interfaces...
==> k8s-master-1: Preparing network interfaces based on configuration...
    k8s-master-1: Adapter 1: nat
    k8s-master-1: Adapter 2: hostonly
==> k8s-master-1: Forwarding ports...
    k8s-master-1: 22 (guest) => 2200 (host) (adapter 1)
==> k8s-master-1: Running 'pre-boot' VM customizations...
==> k8s-master-1: Booting VM...
==> k8s-master-1: Waiting for machine to boot. This may take a few minutes...
    k8s-master-1: SSH address: 127.0.0.1:2200
    k8s-master-1: SSH username: vagrant
    k8s-master-1: SSH auth method: private key
    k8s-master-1: Warning: Connection reset. Retrying...
    k8s-master-1: Warning: Remote connection disconnect. Retrying...
    k8s-master-1:
    k8s-master-1: Vagrant insecure key detected. Vagrant will automatically replace
    k8s-master-1: this with a newly generated keypair for better security.
    k8s-master-1:
    k8s-master-1: Inserting generated public key within guest...
    k8s-master-1: Removing insecure key from the guest if it's present...
    k8s-master-1: Key inserted! Disconnecting and reconnecting using new SSH key...
==> k8s-master-1: Machine booted and ready!
==> k8s-master-1: Checking for guest additions in VM...
==> k8s-master-1: Setting hostname...
==> k8s-master-1: Configuring and enabling network interfaces...
==> k8s-master-1: Mounting shared folders...
    k8s-master-1: /vagrant => /Users/bspiller/devel/k8s/k8s-setup/k8s-setup-kubeadm
➜  k8s-setup-kubeadm git:(master) ✗ vagrant ssh k8s-master-1 -- cat .ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC60lZy/Z72B+XHmsKAXWqvQenpYIwFRjcZHlt3nb7Zmg0Ryt3JL1oI+uBBFQSZ5nNgVZkofMmHPimu7WehNZu2Hg5WidVwSgJH9BSufxCT6UH15Kpoy+TwIQFUnY9VW4E1BQ+Q2UO4DkMDV1TMHYfggME0B0HOUOFG+Pd9jtz92poJNg2UFwXOCCEryexRb8vZyokoDwfdFyXooIoIYN0iIvbUqt+mz+h13iYCAm8q+XTzCL+MNoLROp5CNdAi6w8NnDWAx05D7QlJchv+v6x6KPEkwQU3OQBSZ+/6zrDcoXoSbLffxFl3Aj9NZmGvw9uDlBmW7J7OletQJ3APIuBZ vagrant
```

#### Related

* [OpenSSH 8.3 released (and ssh-rsa deprecation notice)
  ](https://lwn.net/Articles/821544/)