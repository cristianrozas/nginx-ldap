## ![NGINX logo](https://raw.github.com/g17/nginx-ldap/master/images/NginxLogo.gif)

The intention to create this Dockerfile was to provide an [NGINX web server](https://github.com/nginx/nginx) with builtin [LDAP support](https://github.com/kvspb/nginx-auth-ldap). That could be used e.g. to proxy a private [Docker registry](https://github.com/docker/docker-registry) and to authenticate the users against an existing LDAP user directory.

### Basic configuration without authentication
For a basic test without any authentication simply run:


	docker run --name nginx -d h3nrik/nginx-ldap


To expose the HTTP/HTTPS ports run:


	docher run --name nginx -d -p 8080:80 8443:443 h3nrik/nginx-ldap


To run an instance with your own NGINX configuration run:


	docker run --name nginx -v /some/nginx.conf:/etc/nginx.conf:ro -d -p 8080:80 h3nrik/nginx-ldap


To provide your own static HTML site run:


	docker run --name nginx -v /some/content:/usr/local/nginx/html:ro -d -p 8080:80 h3nrik/nginx-ldap


### Configuration with LDAP authentication

To test this NGINX image with authentication against an LDAP server follow these steps:

1. Start a Docker container with a running LDAP instance. This can be done e.g. using the [nickstenning/slapd](https://registry.hub.docker.com/u/nickstenning/slapd/) image. The root passwort will be set to *toor*.


		docker run -e LDAP_DOMAIN=example.com -e LDAP_ORGANIZATION="Example Ltd." -e LDAP_ROOTPASS=toor --name ldap -d -p 389:389 nickstenning/slapd


2. Add some sample groups and users to that LDAP directory. You can find a [sample ldif file](/config/sample.ldif) in the config folder.


		ldapadd -v -h <your-ip>:389 -c -x -D cn=admin,dc=example,dc=com -W -f config/sample.ldif


3. Then you can verify that the test user exists:


		ldapsearch  -v -h <our-ip>:389 -b 'ou=users,dc=example,dc=com' -D 'cn=admin,dc=example,dc=com'  -x -W '(&(objectClass=person)(uid=test))'


4. Create an NGINX Docker container with an nginx.conf file which has LDAP authentication enabled. You can find a sample [nginx.conf](/config/basic/nginx.conf) file in the config folder that provides the static default NGINX welcome page.

 
		docker run --name nginx --link ldap:ldap -d -v `pwd`/config/nginx.conf:/etc/nginx.conf:ro -p 80:80 h3nrik/nginx-ldap


5. When you now access the NGINX server via port 80 you will get an authentication dialog. The user name for the test user is *test* and the password is *t3st*.

Further information about how to configure NGINX with ldap can be found at the [nginx-auth-ldap module site](https://github.com/kvspb/nginx-auth-ldap).


### Docker registry proxy configuration

To run a proxy server to authenticate users against a Docker registry follow these steps:

1. To prepare a test LDAP server, follow step 1-3 of the previous chapter.

2. Instantiate a Docker registry container:


		docker run --name registry -d registry


3. Add valid SSL certificates (known by a CA - no self signed ones!) to a local folder (e.g. /ssl/cert/path) to be mounted as a volume into the proxy server in the next step.

4. Create a Docker container for the NGINX proxy.


		docker run --name nginx --link ldap:ldap --link registry:docker-registry -v /ssl/cert/path:/etc/ssl/docker:ro -v `pwd`/config/proxy:/etc/nginx:ro -p 80:80 -p 443:443 -p 5000:5000 -d h3nrik/nginx-ldap


Further information about proxying the Docker registry can be found at the official [Docker registry github page](https://github.com/docker/docker-registry/blob/master/ADVANCED.md).

### License

This docker image contains binaries for:

1. The NGINX web server. Its license can be found on the [NGINX website](http://nginx.org/LICENSE).
2. The nginx-auth-ldap module. Its license can be found on the [nginx-auth-ldap module project site](https://github.com/kvspb/nginx-auth-ldap/blob/master/LICENSE).
