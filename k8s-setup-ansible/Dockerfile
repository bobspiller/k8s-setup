FROM rockylinux/rockylinux:9.1

ENV container docker

RUN yum -y install sudo procps-ng net-tools iproute iputils wget && yum clean all

RUN cd /lib/systemd/system/sysinit.target.wants/; \
for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done; \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;\
rm -f /lib/systemd/system/*.wants/*update-utmp*;
# VOLUME [ "/sys/fs/cgroup" ]

RUN yum -y install openssh-server && yum clean all

EXPOSE 22

# Create the vagrant user
RUN useradd --create-home -s /bin/bash -p vagrant vagrant 
WORKDIR /home/vagrant

# Configure vagrant and root users
RUN mkdir -p /root/.ssh && \
  chmod 0700 /root/.ssh && \
  mkdir -p /home/vagrant/.ssh && \
  chown -R vagrant: /home/vagrant/.ssh && \
  chmod 0700 /home/vagrant/.ssh && \
  echo -n 'vagrant:vagrant' | chpasswd && \
  mkdir -p /etc/sudoers.d && \
  install -b -m 0440 /dev/null /etc/sudoers.d/vagrant && \
  echo 'vagrant ALL=NOPASSWD: ALL' >> /etc/sudoers.d/vagrant

ADD insecure_vagrant_docker_id.pub /root/.ssh/authorized_keys
ADD insecure_vagrant_docker_id.pub /home/vagrant/.ssh/authorized_keys

# Adjust perms on authorized_keys files
RUN chmod 0600 /home/vagrant/.ssh/authorized_keys && \
  chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys && \
  chmod 0600 /root/.ssh/authorized_keys

# https://www.freedesktop.org/wiki/Software/systemd/ContainerInterface/
STOPSIGNAL SIGRTMIN+3

# something is creating and leaving a nologin file lying around prventing sshd from accepting login attempts
# System is booting up. See pam_nologin(8)
ADD ./enable-login.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/enable-login.sh
ADD ./init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh

CMD ["/usr/local/bin/init.sh"]
# CMD ["/sbin/init"]
