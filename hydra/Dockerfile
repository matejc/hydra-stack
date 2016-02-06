FROM alpine:3.3

RUN apk add --update bzip2 curl bash netcat-openbsd openssh postgresql-client \
    supervisor procps git && rm -rf /var/cache/apk/*

RUN adduser -D hydra \
    && mkdir -m 0755 /nix && chown hydra /nix \
    && mkdir -m 0755 /var/lib/hydra && chown hydra /var/lib/hydra \
    && mkdir -m 0755 /nix2 && chown hydra /nix2

USER hydra
WORKDIR /tmp
ENV USER "hydra"

RUN curl https://nixos.org/nix/install | sh
RUN echo ". /home/hydra/.nix-profile/etc/profile.d/nix.sh" >> ~/.profile

# RUN source ~/.profile \
#      && nix-channel --add http://hydra.nixos.org/jobset/hydra/master/channel/latest hydra \
#      && nix-channel --update \
#      && nix-env -iA hydra

RUN source ~/.profile \
    && cd /home/hydra \
    && git clone --depth 1 https://github.com/matejc/hydra.git src \
    && sed -i 's/name = "Net-Statsd-0.11";/name = "Net-Statsd-0.11"; doCheck = false;/' src/release.nix \
    && nix-env -f src/release.nix -iA build.x86_64-linux

USER root
ENV USER "root"
ENV TZ "UTC"
ENV LC_ALL "C"
ENV HYDRA_DATA "/var/lib/hydra"
ENV HYDRA_CONFIG "/var/lib/hydra/hydra.conf"
ENV LOGNAME "hydra"
ENV NIX_REMOTE_SYSTEMS "/etc/nix/machines"
ENV NIX_BUILD_HOOK "/home/hydra/.nix-profile/libexec/nix/build-remote.pl"
RUN mv /nix/* /nix2/

EXPOSE 3000
COPY supervisord.conf /
COPY start.sh /
ENTRYPOINT touch /tmp/log && tail -f /tmp/log & supervisord -c /supervisord.conf
