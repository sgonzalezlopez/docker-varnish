# Varnish
# Use phusion/baseimage as base image
FROM phusion/baseimage:latest
MAINTAINER Paul B. "paul+swcc@bonaud.fr"

# make sure the package repository is up to date
RUN apt-get update
RUN apt-get install git pkg-config dpkg-dev autoconf curl make autotools-dev automake libtool libpcre3-dev libncurses-dev python-docutils bsdmainutils debhelper dh-apparmor gettext gettext-base groff-base html2text intltool-debian libbsd-dev libbsd0 libcroco3 libedit-dev libedit2 libgettextpo0 libpipeline1 libunistring0 man-db po-debconf xsltproc -y

# download repo key
RUN curl -s http://repo.varnish-cache.org/debian/GPG-key.txt | apt-key add -
RUN echo "deb http://repo.varnish-cache.org/ubuntu/ $(lsb_release -sc) varnish-3.0" | tee -a /etc/apt/sources.list
RUN echo "deb-src http://repo.varnish-cache.org/ubuntu/ $(lsb_release -sc) varnish-3.0" | tee -a /etc/apt/sources.list

# update varnish packages
RUN apt-get update && apt-get clean

# install varnish
RUN cd /opt && apt-get source varnish=3.0.5-2
RUN cd /opt/varnish-3.0.5 && ./autogen.sh
RUN cd /opt/varnish-3.0.5 && ./configure
RUN cd /opt/varnish-3.0.5 && make -j3
RUN cd /opt/varnish-3.0.5 && make install

# install varnish libvmod-throttle
RUN git clone https://github.com/nand2/libvmod-throttle.git /opt/libvmod-throttle
RUN cd /opt/libvmod-throttle && ./autogen.sh
RUN cd /opt/libvmod-throttle && ./configure VARNISHSRC=/opt/varnish-3.0.5
RUN cd /opt/libvmod-throttle && make -j3
RUN cd /opt/libvmod-throttle && make install

ENV LISTEN_ADDR 0.0.0.0
ENV LISTEN_PORT 80
ENV TELNET_ADDR 0.0.0.0
ENV TELNET_PORT 6083
ENV CACHE_SIZE 25MB
ENV THROTTLE_LIMIT 150req/30s
ENV VCL_FILE /etc/varnish/default.vcl
ENV GRACE_TTL 30s
ENV GRACE_MAX 1h

# Keep config
ADD config/default.vcl /etc/varnish/default.vcl.source


# Create a runit entry for your app
RUN mkdir /etc/service/varnish
ADD bin/run.sh /etc/service/varnish/run
RUN chown root /etc/service/varnish/run
RUN chmod +x /etc/service/varnish/run
RUN chmod 777 /etc/container_environment

# Clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 80

CMD ["/sbin/my_init"]
