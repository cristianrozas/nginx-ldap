# ![NGINX logo](https://raw.github.com/g17/nginx-ldap/master/images/NginxLogo.gif)

## Introduction

The intention to create this Dockerfile was to provide an [NGINX web server](https://github.com/nginx/nginx) with builtin [LDAP support](https://github.com/kvspb/nginx-auth-ldap) and SSL. That can be used as a reverse proxy to a private [Docker registry](https://github.com/docker/docker-registry) which authenticates the users against an LDAP or Active Directory user directory.

The sources including the configuration sample files can be found at [GitHub](https://github.com/g17/nginx-ldap).

The docker image can be downloaded from [Docker Hub](https://registry.hub.docker.com/u/h3nrik/nginx-ldap/).

## Usage

### Static page without authentication

The following container will provide the NGINX static default page:


	docker run --name nginx -d -p 80:80 h3nrik/nginx-ldap


To run an instance with your own static page run:


	docker run --name nginx -v /some/content:/usr/local/nginx/html:ro -d -p 80:80 h3nrik/nginx-ldap


### Setting up an LDAP container

For the following chapters you can set up a container providing a test LDAP installation. But the intention is of course to connect to an existing user directory like *OpenLDAP* or *Active Directory* at the end. They can be either running as Docker containers or as a dedicated server. Therefore you might want to use an [ambassador container](http://docs.docker.com/articles/ambassador_pattern_linking/).

Follow these steps to set up an LDAP test container:

1. Start a Docker container with a running LDAP instance. This can be done e.g. using the [nickstenning/slapd](https://registry.hub.docker.com/u/nickstenning/slapd/) image. The root passwort will be set to *toor*.

		docker run -e LDAP_DOMAIN=example.com -e LDAP_ORGANIZATION="Example Ltd." -e LDAP_ROOTPASS=toor --name ldap -d -p 389:389 nickstenning/slapd

2. Add some sample groups and users to that LDAP directory. You can find a [sample ldif file](/config/sample.ldif) in the config folder.

		ldapadd -v -h <your-ip>:389 -c -x -D cn=admin,dc=example,dc=com -W -f config/sample.ldif

3. Then you can verify that the test user exists:

		ldapsearch  -v -h <your-ip>:389 -b 'ou=users,dc=example,dc=com' -D 'cn=admin,dc=example,dc=com'  -x -W '(&(objectClass=person)(uid=test))'

Now the LDAP container is ready to be used.
        
### Static page with LDAP authentication

The following instructions create an NGINX container that provides a static page authenticating against LDAP:

1. Create an NGINX Docker container with an nginx.conf file that has LDAP authentication enabled. You can find a sample [nginx.conf](/config/basic/nginx.conf) file in the config folder that provides the static default NGINX welcome page.

		docker run --name nginx --link ldap:ldap -d -v `pwd`/config/nginx.conf:/etc/nginx/nginx.conf:ro -p 80:80 h3nrik/nginx-ldap

2. When you now access the NGINX server via port 80 you will get an authentication dialog. The user name for the test user is *test* and the password is *t3st*.

Further information about how to configure NGINX with ldap can be found at the [nginx-auth-ldap module site](https://github.com/kvspb/nginx-auth-ldap).

### Setting up a Docker registry container

As the main goal of the NGINX image is to provide LDAP authentication for a private Docker registry in this chapter a Docker registry is prepared.

Instantiate a Docker registre container. It will use the hosts folder */your/local/registry/path* as a volume where the registry data is locally stored. 

	docker run -d --name registry -v /your/local/registry/path:/registry -e SETTINGS_FLAVOR=local -e STORAGE_PATH=/registry registry

You cannot connect to this instance from outside the Docker host by purpose. Otherwise it would be open without authentication at all.

### Docker registry proxy configuration

Now as we have a running registry we can configure our NGINX authentication proxy for it.

1. Add a valid SSL certificate to a local folder (e.g. /ssl/cert/path) to be mounted as a volume into the proxy server later. It must be a valid one known by a trusted CA! The certificate file itself must be named *docker-registry.crt* and the private key file *docker-registry.key*.

2. Create a Docker container for the NGINX proxy. The used sample configuration can be found [in the config/proxy folder](/config/proxy).

		docker run --name nginx --link ldap:ldap --link registry:docker-registry -v /ssl/cert/path:/etc/ssl/docker:ro -v `pwd`/config/proxy:/etc/nginx:ro -p 80:80 -p 443:443 -p 5000:5000 -d h3nrik/nginx-ldap

Theoretically you could also use self-signed certificates. Therefore the Docker daemon need to be started with the *--insecure-registry* command line parameter. But this is not recommended.

Further information about proxying the Docker registry can be found at the official [Docker registry github page](https://github.com/docker/docker-registry/blob/master/ADVANCED.md).

## Debugging

The NGINX web server has been compiled with *debug* support. You can add the following line to your NGINX configuration to get debug output:

	error_log /var/log/nginx/error.log debug;

Then the debug log can be read with the following command:

	docker exec -i -t nginx less /var/log/nginx/error.log

You will then see debug output like:

	...
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Username is "test"
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Authentication loop (phase=0, iteration=0)
	2015/02/14 17:57:10 [debug] 5#0: *2 event timer add: 3: 10000:1423936640056
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: request_timeout=10000
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Authentication loop (phase=1, iteration=0)
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Wants a free connection to "ldapserver"
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Search filter is "(&(objectClass=person)(uid=test))"
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: ldap_search_ext() -> msgid=4
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Waking authentication request "GET / HTTP/1.1"
	2015/02/14 17:57:10 [debug] 5#0: *2 access phase: 6
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Authentication loop (phase=1, iteration=1)
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Authentication loop (phase=2, iteration=1)
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: User DN is "uid=test,ou=users,dc=example,dc=com"
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Authentication loop (phase=3, iteration=0)
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Comparing user group with "cn=docker,ou=groups,dc=example,dc=com"
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: ldap_compare_ext() -> msgid=5
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Waking authentication request "GET / HTTP/1.1"
	2015/02/14 17:57:10 [debug] 5#0: *2 access phase: 6
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Authentication loop (phase=3, iteration=1)
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Authentication loop (phase=4, iteration=0)
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: ldap_sasl_bind() -> msgid=6
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Waking authentication request "GET / HTTP/1.1"
	2015/02/14 17:57:10 [debug] 5#0: *2 access phase: 6
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Authentication loop (phase=4, iteration=1)
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: User bind successful
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Authentication loop (phase=5, iteration=0)
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Rebinding to binddn
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: ldap_sasl_bind() -> msgid=7
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Waking authentication request "GET / HTTP/1.1"
	2015/02/14 17:57:10 [debug] 5#0: *2 access phase: 6
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Authentication loop (phase=5, iteration=1)
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: binddn bind successful
	2015/02/14 17:57:10 [debug] 5#0: *2 http_auth_ldap: Authentication loop (phase=6, iteration=1)
    ...

## Licenses

This docker image contains compiled binaries for:

1. The NGINX web server. Its license can be found on the [NGINX website](http://nginx.org/LICENSE).
2. The nginx-auth-ldap module. Its license can be found on the [nginx-auth-ldap module project site](https://github.com/kvspb/nginx-auth-ldap/blob/master/LICENSE).
