# NGINX LDAP

## Intention
The intention to create this Dockerfile was to provide an [NGINX web server](https://github.com/nginx/nginx) with builtin [LDAP support](https://github.com/kvspb/nginx-auth-ldap). That could be used e.g. to proxy a private [Docker registry](https://github.com/docker/docker-registry) and to authenticate the users against an existing LDAP user directory.

## Basic Usage
For a basic test simply run:

	docker run --name nginx -d h3nrik/nginx-ldap

To expose the HTTP/HTTPS ports run:

	docher run --name nginx -d -p 8080:80 8443:443 h3nrik/nginx-ldap

To run an instance with your own NGINX configuration run:

	docker run --name nginx -v /some/nginx.conf:/usr/local/nginx/conf/nginx.conf:ro -d -p 8080:80 h3nrik/nginx-ldap

To provide your own static HTML site run:

	docker run --name nginx -v /some/content:/usr/local/nginx/html:ro -d -p 8080:80 h3nrik/nginx-ldap

## LDAP configuration

Information about how to configure NGINX with ldap can be found at the [nginx-auth-ldap module site](https://github.com/kvspb/nginx-auth-ldap).

## Docker registry proxy configuration

A sample configuration to act as a proxy to a Docker registry can be found at the official [Docker registry github page](https://github.com/docker/docker-registry/blob/master/contrib/nginx/nginx_1-3-9.conf).
