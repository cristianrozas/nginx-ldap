FROM debian:wheezy

MAINTAINER Henrik Sachse <t3x7m3@posteo.de>

ENV NGINX_VERSION=v1.7.10 \
	NGINX_AUTH_LDAP_VERSION=v0.1

RUN apt-get update \
	&& apt-get install -y ca-certificates git gcc make libpcre3-dev zlib1g-dev libldap2-dev

RUN cd ~ \
	&& git clone https://github.com/kvspb/nginx-auth-ldap.git \
	&& cd nginx-auth-ldap \
	&& git checkout tags/${NGINX_AUTH_LDAP_VERSION} \
	&& cd .. \
	&& git clone https://github.com/nginx/nginx.git \
	&& cd nginx \
	&& git checkout tags/${NGINX_VERSION} \
	&& ./configure --add-module=/root/nginx-auth-ldap \
	&& make \
	&& make install 

# forward request and error logs to docker log collector
RUN mkdir /var/log/nginx \
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
