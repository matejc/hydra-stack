FROM alpine:3.3

RUN apk add --update bzip2 curl bash openssh && rm -rf /var/cache/apk/*

RUN echo "nix:x:1000:100::/home/nix:/bin/bash_wrap" >> /etc/passwd
RUN mkdir -m 0755 /nix && chown nix /nix \
     && mkdir -m 0755 /nix2 && chown nix /nix2 \
     && mkdir -m 0700 /home/nix && chown nix /home/nix

USER nix
WORKDIR /tmp
ENV USER "nix"

RUN curl https://nixos.org/nix/install | sh

RUN echo ". /home/nix/.nix-profile/etc/profile.d/nix.sh" >> /home/nix/.profile

USER root
ENV USER "root"

RUN echo "PasswordAuthentication no" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin no" >> /etc/ssh/sshd_config \
    && echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config \
    && echo "StrictModes no" >> /etc/ssh/sshd_config \
    && echo "AuthorizedKeysFile /home/nix/.ssh/authorized_keys" >> /etc/ssh/sshd_config \
    && sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config \
    && echo "#!/bin/bash" > /bin/bash_wrap && echo "source /home/nix/.nix-profile/etc/profile.d/nix.sh" >> /bin/bash_wrap && echo '/bin/bash -c "$@"' >> /bin/bash_wrap && chmod +x /bin/bash_wrap

COPY start.sh /start.sh
ENTRYPOINT /start.sh
RUN chmod +x /*.sh
EXPOSE 22
ENV LC_ALL "C"
RUN mv /nix/* /nix2/
