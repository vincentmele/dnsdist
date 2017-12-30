FROM alpine:edge
MAINTAINER Vince Mele <vmele@inoc.com>

# Environment
ENV DNSDIST_VERSION 1.2.0
ENV DNSDIST_GPG D6300CABCBF469BBE392E503A208ED4F8AF58446
ENV BUILD_PKGS build-base automake autoconf libtool boost-dev luajit-dev libedit-dev libsodium-dev protobuf-dev net-snmp-dev re2-dev wget gpgme
ENV RUN_PKGS boost luajit libedit libsodium protobuf net-snmp re2

# Files
ADD https://downloads.powerdns.com/releases/dnsdist-${DNSDIST_VERSION}.tar.bz2 /tmp/
ADD https://downloads.powerdns.com/releases/dnsdist-${DNSDIST_VERSION}.tar.bz2.sig /tmp/

WORKDIR /data

RUN \
apk --update add ${RUN_PKGS} && \
apk add --virtual build-dep ${BUILD_PKGS} && \
gpg --keyserver pgp.mit.edu --recv-key ${DNSDIST_GPG} && \
gpg --verify /tmp/dnsdist-${DNSDIST_VERSION}.tar.bz2.sig && \
tar xf /tmp/dnsdist-${DNSDIST_VERSION}.tar.bz2 && \
cd dnsdist-${DNSDIST_VERSION} && \
	LIBSODIUM_CFLAGS=$CFLAGS \
	LIBSODIUM_LIBS=-lsodium \
	LIBEDIT_CFLAGS=$CFLAGS \
	LIBEDIT_LIBS=-ledit \
	PROTOBUF_CFLAGS=$CFLAGS \
	PROTOBUF_LIBS=-lprotobuf \
	RE2_CFLAGS=$CFLAGS \
	RE2_LIBS="-lre2" \
	./configure \
		--build=$CBUILD \
		--host=$CHOST \
		--prefix=/usr \
		--sysconfdir=/etc \
		--mandir=/usr/share/man \
		--enable-dnscrypt \
		--enable-libsodium \
		--enable-re2 \
		--with-protobuf \
		--with-boost=/usr/include \
		--with-net-snmp \
		--with-luajit && \
make -j2 && \
make check-local && \
make install && \
# Trim down the image
cd / && \
apk del --purge build-dep && \
rm -rf /var/cache/apk/* /tmp/* /data/dnsdist-${DNSDIST_VERSION}

RUN addgroup -S dnsdist && adduser -S -g dnsdist dnsdist
RUN chown -R dnsdist:dnsdist /data

EXPOSE 53/tcp 53/udp 8083/tcp 5199/tcp

CMD ["/usr/bin/dnsdist", "--supervised", "--disable-syslog", "-u", "dnsdist", "-g", "dnsdist"]
