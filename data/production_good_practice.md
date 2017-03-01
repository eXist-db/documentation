# Production Use - Good Practice

## Abstract

> From our and our clients' experiences of developing and using eXist-db in production environments a number of lessons have been learned. This Good Practice guide is an attempt to cover some of the considerations that should be taken into account when deploying eXist-db for use in a production environment.
>
> The concepts laid out within this document should not be considered absolute or accepted wholesale - they should rather be used as suggestions to guide users in their eXist-db deployments.

## The Server

Ensure that your server is up-to-date and patched with any necessary security fixes.

eXist-db is written in Java - so for performance and security reasons, please ensure that you have the latest and greatest Java JDK release installed. At present this is the 1.6 branch, details of the latest version can always be found here - <http://java.sun.com>

## Install from Source or Release?

Most users will install an officially released version of eXist-db on their production systems, usually this is perfectly fine. However there can be advantages to installing eXist-db from source code on a production system.

eXist-db may be installed from source code to a production system in one of two ways -

via Local Build Machine (preferred)  
You checkout the eXist-db code for a release branch (or trunk) from our GitHub repository to a local machine, from here you build a distribution which you test and then deploy to your live server.

Directly from GitHub  
In this case you don't use a local machine for building an eXist-db distribution, but you checkout the code from a release branch (or the develop branch) directly from our GitHub repository on your server and build it in-situ.

If you install eXist-db from source code, some advantages might be -

patches  
If patches or fixes are developed that are relevant to your specific needs, you can update your code and re-build eXist.

features  
If you are following trunk and new features are developed which you are interested in, you can update your code and re-build to take advantage of these.

> **Caution**
>
> NOTE
> - eXist's code trunk is generally not recommended for production use, whilst it should always compile and be relatively stable, it may also contain as yet unrecognised regressions or result in unexpected behaviour.

### Upgrading

If you are upgrading the version of eXist-db that you use in your production system, please always follow these two points -

1.  `Backup` - always make sure you have a full database backup before you upgrade.

2.  `Test` - always test your application in the new version of eXist-db in a development environment to ensure expected behaviour before you upgrade your production system.

## Configuring eXist

There are four main things to consider here -

1.  `Security - Permissions` - ensure that eXist-db is installed in a secure manner.

2.  `Security - Attack Surface` - configure eXist-db so it provides *only* what you need for your application.

3.  `Resources` - configure your system and eXist-db so that eXist-db has access to enough resources and the system starts and stops eXist-db in a clean manner.

4.  `Performance` - configure your system and eXist-db so that you get the maximum performance possible.

### Permissions

#### eXist-db Permissions

At present eXist-db ships with fairly relaxed permissions to facilitate rapid application development, but for production systems these should be constrained -

admin account  
The password of the admin account is blank by default! Ensure that you set a decent password.

default-permissions  
The default permissions for creating resources and collections in eXist-db are set in conf.xml. The current settings are fairly sane, but you may like to improve on them for your own application security.

/db permissions  
The default permissions for /db are 0755, which should be sufficient in most cases. In the case you needed to change this, you could do that with (here for 0775):

``` xquery
sm:chmod(xs:anyURI("/db"), "rwxrwxr-x")
```

#### Operating System Permissions

eXist-db should be deployed and configured to run whilst following the security best practices of the operating system on which it is deployed.

Typically we would recommend creating an "exist" user account and "exist" user group with no login privileges (i.e. no shell and empty password), changing the permissions of the eXist-db installation to be owned by that user and group, and then running eXist-db using those credentials. An example of this on OpenSolaris might be -

``` bash
$ pfexec groupadd exist
$ pfexec useradd -c "eXist Native XML Database" -d /home/exist -g exist -m exist
$ pfexec chown -R exist:exist /opt/eXist 
                    
```

### Attack Surface

For any live application it is recognised best practice to keep the attack surface of the application as small as possible. There are two aspects to this -

1.  Reducing the application itself to the absolute essentials.
2.  Limiting access routes to the application.

eXist-db is no exception and should be configured for your production systems so that it provides only what you need and no more. For example, the majority of applications will be unlikely to require the WebDAV or SOAP Admin features for operation in a live environment, and as such these and other services can be disabled easily. Things to consider for a live environment -

Standalone mode  
eXist-db can be operated in a cut-down standalone mode (see server.(sh|bat)). This provides just the core services from the database, no webapp file system access, and no documentation. The entire application has to be stored in the database and is served from there. This is an ideal starting place for a production system.

Services  
eXist-db provides several services for accessing the database. You should reduce these to the absolute minimum that you need for your production application. If you are operating in standalone mode, this is done via server.xml, else see webapp/WEB-INF/web.xml. You should look at each configured service, servlet or filter and ask yourself - do we use this? Most production environments are unlikely to need WebDAV or SOAP Admin (Axis).

Extension Modules  
eXist-db loads several XQuery and Index extension modules by default. You should modify the builtin-modules section of conf.xml, to

ONLY

load what you need for your application.

### Resources

You should ensure that you have enough memory and disk space in your system so that eXist-db can cope with any peak demands by your users.

-Xmx  
However you decide to deploy and start eXist, please ensure that you allocate enough maximum memory to eXist-db via. the Java -Xmx setting. See backup.sh and startup.sh.

cacheSize and collectionCache  
These two settings in the db-connection of conf.xml should be adjusted appropriately based on your -Xmx setting (above). See the

tuning guide

for advice on sensible values.

disk space  
Please ensure that you have plenty of space for your database to grow. Unsurprisingly running out of disk space can result in database corruptions or having to rollback the database to a known state.

### Performance

It has been reported by large scale users that keeping the eXist-db application, database data files and database journal on separate disks connected to different I/O channels can have a positive impact on performance. The location of the database data files and database journal can be changed in conf.xml.

## Backups

*This is fundamental* - Make sure you have them, they are up-to-date and that they work!

eXist-db provides 3 different mechanisms for performing backups -

1.  Full database backup.
2.  Differential database backup.
3.  Snapshot of the database data files.

Each of these backup mechanisms is schedulable either with eXist-db or with your operating system scheduler. See the [backup](backup.md) page and conf.xml for further details.

## Web Deployments

eXist-db like any Web Application Server (Tomcat, WebLogic, GlassFish, etc.) should not be directly exposed to the Web. Instead, we would strongly recommend proxying your eXist-db powered Web Application through a Web Server such as [Nginx](http://wiki.nginx.org/Main) or [Apache HTTPD](http://httpd.apache.org/). See [here](production_web_proxying.md) for further details.

If you proxy eXist-db through a Web Server, then you may also configure your firewall to only allow external access directly to the Web Server. If done correctly this also means that web users will not be able to access any eXist-db services except your application which is proxyied into the Web Servers namespace.

### Enable GZip Compression

eXist-db by default operates inside the Jetty Application Server, Jetty (and most other Java Application Servers) provides a mechanism for enabling dynamic GZip compression of resources. This is to say that Jetty can be configured to dynamically GZip compress any resource received from the server by HTTP. Potentially for large resources, or even for frequently used resources. Enabling dynamic GZip compression can reduce the size of transfers, and as such reduce the transfer time of resources from the server to the client, hopefully resulting in a faster experience for the end-user.

GZip Compression can be enabled in web.xml, which can be found in either $EXIST\_HOME/webapp/WEB-INF/web.xml for default deployments or $EXIST\_HOME/tools/jetty/etc/standalone/WEB-INF/web.xml for standalone deployments.
