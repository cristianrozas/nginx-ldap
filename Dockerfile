FROM debian:wheezy

MAINTAINER Henrik Sachse <t3x7m3@posteo.de>

ENV NGINX_VERSION v1.7.10

RUN apt-get update \
	&& apt-get install -y \
		ca-certificates \
		git \
		gcc \
		make \
		libpcre3-dev \
		zlib1g-dev \
		libldap2-dev \
		libssl-dev

# See http://wiki.nginx.org/InstallOptions
RUN mkdir /var/log/nginx \
	&& mkdir /etc/nginx \
	&& cd ~ \
	&& git clone https://github.com/kvspb/nginx-auth-ldap.git \
	&& cd nginx-auth-ldap \
	&& cd .. \
	&& git clone https://github.com/nginx/nginx.git \
	&& cd nginx \
	&& git checkout tags/${NGINX_VERSION} \
	&& ./configure \
		--add-module=/root/nginx-auth-ldap \
		--with-http_ssl_module \
		--with-debug \
		--conf-path=/etc/nginx/nginx.conf \ 
		--sbin-path=/usr/sbin/nginx \ 
		--pid-path=/var/log/nginx/nginx.pid \ 
		--error-log-path=/var/log/nginx/error.log \ 
		--http-log-path=/var/log/nginx/access.log \ 
	&& make \
	&& make install \
	&& cd .. \
	&& rm -rf nginx-auth-ldap \
	&& rm -rf nginx 

EXPOSE 80 443

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
