## ![NGINX logo](https://raw.github.com/g17/nginx-ldap/master/images/NginxLogo.gif)

The intention to create this Dockerfile was to provide an [NGINX web server](https://github.com/nginx/nginx) with builtin [LDAP support](https://github.com/kvspb/nginx-auth-ldap). That could be used e.g. to proxy a private [Docker registry](https://github.com/docker/docker-registry) and to authenticate the users against an existing LDAP user directory.

### Basic configuration without authentication
For a basic test without any authentication simply run:


	docker run --name nginx -d h3nrik/nginx-ldap


To expose the HTTP/HTTPS ports run:


	docher run --name nginx -d -p 8080:80 8443:443 h3nrik/nginx-ldap


To run an instance with your own NGINX configuration run:


	docker run --name nginx -v /some/nginx.conf:/usr/local/nginx/conf/nginx.conf:ro -d -p 8080:80 h3nrik/nginx-ldap


To provide your own static HTML site run:


	docker run --name nginx -v /some/content:/usr/local/nginx/html:ro -d -p 8080:80 h3nrik/nginx-ldap


### Configuration with LDAP authentication

To test this NGINX image with authentication against an LDAP server follow these steps:

Start a Docker container with a running LDAP instance. This can be done e.g. using the [nickstenning/slapd](https://registry.hub.docker.com/u/nickstenning/slapd/) image. The root passwort will be set to '''toor'''.


	docker run -e LDAP_DOMAIN=example.com -e LDAP_ORGANIZATION="Example Ltd." -e LDAP_ROOTPASS=toor --name ldap -d -p 389:389 nickstenning/slapd


Add some sample groups and users to that LDAP directory. You can find a sample ldif file below the config folder.


	ldapadd -v -h <your-ip>:389 -c -x -D cn=admin,dc=example,dc=com -W -f config/sample.ldif


Then you can verify that the test user exists:


	 ldapsearch  -v -h <our-ip>:389 -b 'ou=users,dc=example,dc=com' -D 'cn=admin,dc=example,dc=com'  -x -W '(&(objectClass=person)(uid=test))'


Create an NGINX Docker container with an nginx.conf file that has LDAP authentication enabled. You can find a sample nginx.conf file below the config folder as well.


	docker run --name nginx --link ldap:ldap -d -v `pwd`/config/nginx.conf:/usr/local/nginx/conf/nginx.conf:ro -p 80:80 h3nrik/nginx-ldap


When you now access the NGINX server via port 80 you will get an authentication dialog. The user name for the test user is *test* and the password is *t3st*.

#### Further information

Information about how to configure NGINX with ldap can be found at the [nginx-auth-ldap module site](https://github.com/kvspb/nginx-auth-ldap).

### Docker registry proxy configuration

A sample configuration to act as a proxy to a Docker registry can be found at the official [Docker registry github page](https://github.com/docker/docker-registry/blob/master/contrib/nginx/nginx_1-3-9.conf).

### License

This docker image contains binaries for:

#### The NGINX web server

The NGINX license can be found at the [NGINX website](http://nginx.org/LICENSE).

#### The nginx-auth-ldap module

The nginx-auth-ldap module license can be found at [its project page](https://github.com/kvspb/nginx-auth-ldap/blob/master/LICENSE).
