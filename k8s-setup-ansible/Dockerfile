FROM ubuntu:22.04

ENV container docker

# Don't start any optional services except for the few we need.
RUN find /etc/systemd/system \
    /lib/systemd/system \
    -path '*.wants/*' \
    -not -name '*journald*' \
    -not -name '*systemd-tmpfiles*' \
    -not -name '*systemd-user-sessions*' \
    -exec rm \{} \;

# w/o /var/run/sshd sshd fails to start with:
# Missing privilege separation directory: /var/run/sshd
RUN apt-get update && \
    apt-get install -y \
    dbus systemd openssh-server net-tools iproute2 iputils-ping curl wget vim-tiny sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /var/run/sshd


RUN >/etc/machine-id
RUN >/var/lib/dbus/machine-id

EXPOSE 22

RUN systemctl set-default multi-user.target
RUN systemctl mask \
      dev-hugepages.mount \
      sys-fs-fuse-connections.mount \
      systemd-update-utmp.service \
      systemd-tmpfiles-setup.service \
      console-getty.service
RUN systemctl disable \
      networkd-dispatcher.service

# This container image doesn't have locales installed. Disable forwarding the
# user locale env variables or we get warnings such as:
#  bash: warning: setlocale: LC_ALL: cannot change locale
RUN sed -i -e 's/^AcceptEnv LANG LC_\*$/#AcceptEnv LANG LC_*/' /etc/ssh/sshd_config

# https://www.freedesktop.org/wiki/Software/systemd/ContainerInterface/
STOPSIGNAL SIGRTMIN+3

# Create the vagrant user
RUN useradd --create-home -s /bin/bash -p vagrant vagrant 
WORKDIR /home/vagrant

# Initial SSH access setup
RUN mkdir -p /root/.ssh && \
  chmod 0700 /root/.ssh && \
  mkdir -p /home/vagrant/.ssh && \
  chown -R vagrant: /home/vagrant/.ssh && \
  chmod 0700 /home/vagrant/.ssh && \
  echo -n 'vagrant:vagrant' | chpasswd

# Copy up our SSH public keys as authorized
ADD insecure_vagrant_docker_id.pub /root/.ssh/authorized_keys
ADD insecure_vagrant_docker_id.pub /home/vagrant/.ssh/authorized_keys

# finish with the setup
RUN chmod 0600 /root/.ssh/authorized_keys && \
  chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys && \
  chmod 0600 /home/vagrant/.ssh/authorized_keys && \
  mkdir -p /etc/sudoers.d && \
  install -b -m 0440 /dev/null /etc/sudoers.d/vagrant && \
  echo 'vagrant ALL=NOPASSWD: ALL' >> /etc/sudoers.d/vagrant

CMD ["/usr/sbin/init"]