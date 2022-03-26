FROM debian:11 AS wsdd2-builder

RUN apt-get -y update \
 && apt-get -y install build-essential wget \
 && wget -O - https://github.com/Netgear/wsdd2/archive/refs/heads/master.tar.gz | tar zxvf - \
 && cd wsdd2-master \
 && make

FROM debian:11

COPY --from=wsdd2-builder /wsdd2-master/wsdd2 /usr/sbin

ENV PATH="/container/scripts:${PATH}"

RUN apt-get -y update \
 && apt-get -y install runit avahi-daemon samba samba-vfs-modules libgfapi0 glusterfs-client bash \
 && apt-get clean \
 \
 && sed -i 's/#enable-dbus=.*/enable-dbus=no/g' /etc/avahi/avahi-daemon.conf \
 && rm -vf /etc/avahi/services/* \
 \
 && mkdir -p /external/avahi \
 && touch /external/avahi/not-mounted \
 && echo done

VOLUME ["/shares"]

EXPOSE 139 445

COPY . /container/

HEALTHCHECK CMD ["/container/scripts/docker-healthcheck.sh"]
ENTRYPOINT ["/container/scripts/entrypoint.sh"]

CMD [ "runsvdir","-P", "/container/config/runit" ]
