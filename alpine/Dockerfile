FROM alpine:3.5

MAINTAINER Instrumentisto Team <developer@instrumentisto.com>


# Build and install Postfix
# https://git.alpinelinux.org/cgit/aports/tree/main/postfix/APKBUILD?h=2b1512eefca296b0ef1b60d2e521349385a3c353
RUN apk update \
 && apk upgrade \
 && apk add --no-cache \
        ca-certificates \
 && update-ca-certificates \

 # Install Postfix dependencies
 && apk add --no-cache \
        pcre \
        db libpq mariadb-client-libs sqlite-libs \
        libsasl \
        libldap \

 # Install tools for building
 && apk add --no-cache --virtual .tool-deps \
        curl coreutils autoconf g++ libtool make \

 # Install Postfix build dependencies
 && apk add --no-cache --virtual .build-deps \
        libressl-dev \
        linux-headers \
        pcre-dev \
        db-dev postgresql-dev mariadb-dev sqlite-dev \
        cyrus-sasl-dev \
        openldap-dev \

 # Download and prepare Postfix sources
 && curl -fL -o /tmp/postfix.tar.gz \
         http://cdn.postfix.johnriley.me/mirrors/postfix-release/official/postfix-3.1.3.tar.gz \
 && (echo "00e2b0974e59420cabfddc92597a99b42c8a8c9cd9a0c279c63ba6be9f40b15400f37dc16d0b1312130e72b5ba82b56fc7d579ee9ef975a957c0931b0401213c  /tmp/postfix.tar.gz" \
         | sha512sum -c -) \
 && tar -xzf /tmp/postfix.tar.gz -C /tmp/ \

 && cd /tmp/postfix-* \
 && curl -fL -o ./no-glibc.patch \
         https://git.alpinelinux.org/cgit/aports/plain/main/postfix/no-glibc.patch?h=2b1512eefca296b0ef1b60d2e521349385a3c353 \
 && patch -p1 -i ./no-glibc.patch \
 && curl -fL -o ./postfix-install.patch \
         https://git.alpinelinux.org/cgit/aports/plain/main/postfix/postfix-install.patch?h=2b1512eefca296b0ef1b60d2e521349385a3c353 \
 && patch -p1 -i ./postfix-install.patch \
 && curl -fL -o ./libressl.patch \
         https://git.alpinelinux.org/cgit/aports/plain/main/postfix/libressl.patch?h=2b1512eefca296b0ef1b60d2e521349385a3c353 \
 && patch -p1 -i ./libressl.patch \
 && sed -i -e "s|#define HAS_NIS|//#define HAS_NIS|g" \
           -e "/^#define ALIAS_DB_MAP/s|:/etc/aliases|:/etc/postfix/aliases|" \
        src/util/sys_defs.h \
 && sed -i -e "s:/usr/local/:/usr/:g" conf/master.cf \

 # Build Postfix from sources
 && make makefiles \
         CCARGS="-DHAS_SHL_LOAD -DDEF_DAEMON_DIR=\\\"/usr/lib/postfix\\\" \
                 -DHAS_PCRE $(pkg-config --cflags libpcre) \
                 -DUSE_TLS \
                 -DUSE_SASL_AUTH -DDEF_SASL_SERVER=\\\"dovecot\\\" \
                 -DUSE_SASL_AUTH -DUSE_CYRUS_SASL -I/usr/include/sasl \
                 -DHAS_PGSQL $(pkg-config --cflags libpq) \
                 -DHAS_MYSQL $(mysql_config --include) \
                 -DHAS_LDAP -DUSE_LDAP_SASL \
                 -DHAS_SQLITE $(pkg-config --cflags sqlite3)" \
         AUXLIBS="-lssl -lcrypto -lsasl2" \
         AUXLIBS_LDAP="-lldap -llber" \
         AUXLIBS_MYSQL="$(mysql_config --libs)" \
         AUXLIBS_PCRE="$(pkg-config --libs libpcre)" \
         AUXLIBS_PGSQL="$(pkg-config --libs libpq)" \
         AUXLIBS_SQLITE="$(pkg-config --libs sqlite3)" \
         dynamicmaps=yes \
         shared=yes \
 && make \

 # Create Postfix user and groups
 && addgroup -g 101 -S postfix \
 && adduser -u 100 -D -S -G postfix postfix \
 && addgroup -g 102 -S postdrop \

 # Install Postfix
 && make upgrade \
         shlib_directory=/usr/lib/postfix \
         # No documentation included to keep image size smaller
         readme_directory=/tmp/readme \
         manpage_directory=/tmp/man \
 # Always execute these binaries under postdrop group
 && chmod g+s /usr/sbin/postdrop \
              /usr/sbin/postqueue \
 # Ensure spool dir has coorect rights
 && install -d -o postfix -g postfix /var/spool/postfix \

 # Cleanup unnecessary stuff
 && apk del .tool-deps .build-deps \
 && rm -rf /var/cache/apk/* \
           /tmp/*


# Install s6-overlay
RUN apk add --update --no-cache --virtual .tool-deps \
        curl \
 && curl -fL -o /tmp/s6-overlay.tar.gz \
         https://github.com/just-containers/s6-overlay/releases/download/v1.19.1.1/s6-overlay-amd64.tar.gz \
 && tar -xzf /tmp/s6-overlay.tar.gz -C / \

 # Cleanup unnecessary stuff
 && apk del .tool-deps \
 && rm -rf /var/cache/apk/* \
           /tmp/*

ENV S6_CMD_WAIT_FOR_SERVICES=1


COPY rootfs /

RUN chmod +x /etc/services.d/*/run


EXPOSE 25 465 587

ENTRYPOINT ["/init"]

CMD ["/usr/lib/postfix/master", "-d"]
