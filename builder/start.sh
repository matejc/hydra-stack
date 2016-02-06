#!/bin/bash -xe

test -d /nix/store || cp -a /nix2/* /nix/
chown -R nix /nix

ssh-keygen -A

source /home/nix/.profile

/usr/sbin/sshd -D -e
