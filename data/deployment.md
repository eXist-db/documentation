# Database Deployment

## Overview

There are *three* ways to deploy the eXist-db database:

1.  *In a Servlet Context*

    In this case, the database is deployed as part of a web application. eXist will happily live together with other servlets. This is the default mode established when the database has been deployed according to instructions provided in the [Quick Start Guide](quickstart.md).

    All resources used by eXist-db in this mode will have paths relative to the web application's current context. For example, eXist will store all its database files in the `WEB-INF/data` directory of the web application.

2.  *Stand-alone Server Process*

    In stand-alone mode, eXist-db runs in its own Java virtual machine (JVM). Clients have to access the database through the network, either using the XML-RPC or WebDAV protocol or the REST-style HTTP API (see the [Developer's Guide](devguide.md)).

3.  *Embedded in an Application*

    In embedded mode, the database is basically used as a Java library, controlled by the client application. It runs in the same Java virtual machine as the client, thus no network connection is needed and the client has full access to the database.

Note that all three deployments are thread-safe and allow concurrent operations by multiple users. Also note that servlets running in the same web application context will have direct access to the database. External client applications may still use the supplied network interfaces.

As detailed instructions on how to set up eXist-db for use with a servlet-engine are provided in the [Quick Start Guide](quickstart.md), the sections in this document concern the other two deployment options. In section 2, we introduce the XML:DB URI and explain how different servers are addressed by Java clients. Section 3 deals with running eXist as a stand-alone server, and in Section 4 we discuss the required steps to directly embed eXist into an application, including how to embed in the [XMLdbGUI](http://titanium.dstc.edu.au).

## Addressing Different Servers using the XML:DB URI

One way to access eXist-db from Java applications is to use the XML:DB API. The XML:DB API uses a specific URI scheme to locate a collection of XML resources on the server. You will encounter XML:DB URIs when working with the Java client, the backup tools and sometimes in XQuery functions. It is thus important to understand how the URI scheme addresses servers and resources.

eXist's XML:DB API implementation supports transparent access to remote as well as embedded database servers. This means the database on the server is available on the client as though it were locally connected to the client - i.e. the user should not have to be aware of where a resource is physically located. Given this transparency, applications need not be affected by how the database has been deployed.

The XML:DB URI identifies the database implementation, the name of the collection, and optionally the location of the database server on the network. For example, the URI:

xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare
points to the shakespeare-collection on a remote server which is running in a servlet-engine. The host part: `localhost:8080/exist/xmlrpc` describes the path to the XML-RPC listener, which is running as a servlet. The collection part (`/db/shakespeare`) defines the collection to retrieve. If eXist had started as a stand-alone server, the URI would change its port to `8088` to become:

xmldb:exist://localhost:8088/xmlrpc/db/shakespeare
Finally, to access an embedded instance of the database, we simply drop the host part altogether, and use three forward slashes (`///`) in front of the collection path:

xmldb:exist:///db/shakespeare
You can use the command-line client to experiment with these settings. The client utilizes the XML:DB API to access the database. The `Login` dialog offers a text field where you can specify an XML:DB URI to connect to. The default URI shown here is configured through a properties-file called `client.properties`. By default, the client tries to access the database engine located at the base URI:

xmldb:exist://localhost:8080/exist/xmlrpc/
To use the client with another server, you can simply change the `uri` property for the server location. For permanent changes, edit the properties-file `client.properties`. To make temporary changes, pass the `-ouri` option on the command line. For example, if you start the Admin client using the command:

bin/client.sh -ouri=xmldb:exist://
this will cause a local database instance to run in the same Java virtual machine as the client. Note that the short form for this particular command uses the `-l` option that causes the client to launch a local database instance - i.e.:

bin/client.sh -l
## Deploying eXist-db in a Servlet Container

The standard distribution does by default launch eXist-db as a web application deployed in a servlet container (if you start eXist via `bin/startup.sh` or `bin\startup.bat`). The container used is [Jetty](http://jetty.mortbay.org/).

The Jetty configuration can be found in `tools/jetty/etc/jetty.xml`. It defines a single web application context `/exist`, mapped to the `webapp` directory.

We think that Jetty is small, efficient and stable, so there's no need to switch to a different servlet engine unless your server setup requires this. However, it is not difficult to deploy eXist in a different servlet container, e.g. Apache's Tomcat.

We usually provide a `.war` web archive for download for all major releases. You may either download that or - if you already installed the standard distribution - build a .war archive yourself. For building the .war, you need the eXist sources. In the installer GUI, include the "source" module when selecting installable packages. To build the .war file, just call the main build script (`build.sh` or `build.bat`) with the target `dist-war`:

build.sh dist-war
To install the .war, just copy it into the corresponding folder below your servlet engine installation (usually `webapps`) and rename it to `exist.war`. The servlet engine will normally unpack the file when you restart the server. To have better control of where the file is unpacked, you can also create a directory `exist` below the `webapps` folder and manually extract the .war there, e.g. with:

jar xfv exist.war
> **Important**
>
> Please remember that the `data` and `log` directories need to be writable!

There are a few differences between the standard distribution and the .war install: in particular, the configuration files are found in the `WEB-INF` directory, including the important files `conf.xml` (eXist configuration) and `log4j.xml` (logging). The example data is in `samples`.

To start the Java admin client (described in the [QuickStart](quickstart.md)), use the following command line (from within the `exist` web application root directory:

java -jar WEB-INF/lib/start.jar client -ls
## Running eXist-db as a Stand-alone Server

There are many cases in which it is preferable to have the database engine running in its own Java virtual machine. In stand-alone mode, eXist will launch its own, embedded web server to provide XML-RPC, WebDAV and REST services to the outside world. The embedded server is based on a stripped-down Jetty. It uses a limited configuration, excluding all the additional services available in a full-blown servlet environment.

In general, the stand-alone deployment is more reliable and performant than the web application setup, since no other threads (simultaneous tasks) are running. If your application does not need WebDAV or SOAP, you should use the stand-alone server.

The stand-alone database server offers XML-RPC, WebDAV and REST-style HTTP interfaces for external client access. Please note that it does not support SOAP. The XML-RPC and REST interfaces are explained in-depth in the [Developer's Guide](devguide.md).

By default, the stand-alone server listens on port `8088`, though this can be changed (see configuration below). The Java class for launching the server is `org.exist.jetty.StandaloneServer`.

### Starting the Stand-alone Server

To start the server, launch either the Unix shell script:

bin/server.sh
OR the Windows/DOS batch file:

bin\\server.bat
The server is multi-threaded - a server thread is assigned to each client request. If the specified maximum number of threads is reached, the server will block the client until one of the server-threads is available to respond. By default, the maximum number of threads is 5. To change this, use the `-t` option, e.g.:

bin\\server.bat -t 20
To access the stand-alone server using the interactive command line client (or by your own Java classes), you must change the XML:DB server URI set by the `uri` property, as described above, to the following:

xmldb:exist://localhost:8088/xmlrpc
### StandaloneServer Configuration with tools/jetty/etc/standalone/WEB-INF/web.xml

The `tools/jetty/etc/standalone/WEB-INF/web.xml` configuration file is used when the server operates in standalone mode, in which case, an instance of the Jetty web server is configured using its settings. As for the services offered with eXist, each has its own configuration servlet element in this file. Currently, the servlet API alternatives are "`webdav`, "`xmlrpc`", and "`rest`". Any of these servlets can be disabled by setting a init-param `enabled` attribute to "`no`".

The standalone.xml/web.xml document has the following basic structure:

                            fixme!/ljo

                        

#### Controlling the Binding Address (&lt;indexer&gt;)

You can control the binding address by changing the addConnector Call element in tools/jetty/etc/standalone.xml:

port  
The port on which the server will listen. The Jetty web server will bind to the port `8088` by default.

host  
The hostname on which the server will respond.

address  
The IP address on which the server should bind. This may be useful when the server has multiple addresses that serve the same hostname.

#### WebDAV Servlet

The WebDAV servlet provides services at the context address specified. This servlet is represented by the webdav element in the `server.xml` configuration file. For this element, the "`context`" attribute controls the web server context at which the WebDAV services are provided. If the "`context`" attribute is not specified, it defaults to `/webdav/`.

#### XML-RPC Servlet

The XML-RPC servlet provides database API services to clients like the Admin GUI client. This servlet is represented by the xmlrpc element in the `server.xml` configuration file. For this element, the "`context`" attribute controls the web server context at which the XMLRPC services are provided. If the "`context`" attribute is not specified, it defaults to `/xmlrpc/`. Note that if you disable this servlet, you effectively disable the use of the admin client.

#### REST Servlet

NB! Updated for Jetty 7 in trunk from December 2009

The REST servlet provides HTTP/REST-style interactions with the database. It is configured by a servlet element with servlet-classorg.exist.http.servlets.EXistServlet in the `tools/jetty/etc/standalone/WEB-INF/web.xml` configuration file. It depends on the XQueryURLRewrite filter for the context, defaults is `/`.

The RestServlet has a number of other parameters that can be set by child elements:

                                <servlet>
            <servlet-name>EXistServlet</servlet-name>
            <servlet-class>org.exist.http.servlets.EXistServlet</servlet-class>
          <init-param>
                <param-name>use-default-user</param-name>
                <param-value>true</param-value>
            </init-param>
    ...
     </servlet>
                            

form-encoding  
The default encoding of form POSTs.

container-encoding  
The default encoding of the servlet container for all HTTP interactions except POSTs.

use-default-user  
A boolean value (`true`/`false`) that indicates whether a user you supply the credentials `user` and `password` for or if the `guest` user with default password should be used for non-authenticated interactions. If any of these fails a simple AUTH interaction is undertaken.

user  
The username of the default user.

user  
The password of the default user (required when every users has a password).

#### Custom Servlets

Any servlet can be configured to run in the Jetty server by adding a 'servlet' element to the server.xml configuration file. The 'servlet' element has the standard attributes of 'enabled' and 'context' as well as the 'class' attribute to specify the servlet implementation class.

This element can have any number of `param` element children to set parameters on the servlet. The structure looks like:

                                <servlet enabled="yes" context="/myservlet/*" class="com.example.MyServlet">
          <param name="auth" value="true"  />
          <param name="demo" value="false"  />
     </servlet>
                            

#### Forwarding Requests

The forwarding-request settings allow you to map incoming URL requests to specific resources on the server (e.g. queries). All of which are encapsulated in the forwarding element. Inside this element is a single root element and any number of forward elements. Each of these latter elements specifies a specific URL path that is forwarded to secondary URL path. This allows you to map a "clean" URL to an XQuery or some other resource within the server. The target is always specified by a `destination` attribute.

The root element maps requests to the root directory of the server (i.e. the "`/`" path) to a specified resource. For example:

                                <root destination="/db/admin/admin.xql" />
                            

The above element maps requests for the (default) server root to the XQuery resource `/db/admin/admin.xql`.

The forwardelement, on the other hand, maps the request specified by the `path` attribute to a resource. For example:

                                <forward path="/admin" destination="/db/admin/admin.xql"/>
    <forward path="/docs" destination="/db/products/docs.xml"/>
                            

In this example, the first element (&lt;forward&gt;) maps the URI path `/admin` to the XQuery resource `/db/admin/admin.xql`, while the second element maps the URI path `/docs` to the document `/db/products/docs.xml`.

### Shutting Down the Database

By default, the `shutdown.bat` (Windows/DOS) and `shutdown.sh` (Unix) scripts try to connect to the default server URI - i.e.:

xmldb:exist://localhost:8080/exist/xmlrpc
If your database is running in stand-alone mode, you must specify a different server URI. Specifically, to stop eXist when running in stand-alone mode listening on port `8088`, use the following:

java -jar start.jar shutdown --uri=xmldb:exist://localhost:8088/xmlrpc
## Embedding eXist in an Application

In the embedded mode, the database runs in the same Java virtual machine as the client application. The database will not be accessible by any outside application, and no network listeners are started.

You can embed eXist into any Java application using the XML:DB API. Other APIs might be added in the future. In particular, we are currently working to implement JSR 225: the "XQuery API for Java" (XQJ). However, until alternatives are available, we recommend using the XML:DB.

To prepare the environment for using an embedded eXist, follow the steps below:

Copy `conf.xml` and `log4j.xml` to the target directory.

Create a subdirectory `data` in the target directory. Edit the `files` attribute in the `db-connection` section of `conf.xml` to point to this data directory. Do the same for the `journal-dir` in the `recovery` element.

To see logging output, edit `log4j.xml`. The simplest way is to change the `appender-ref` in the root category to `"console"`, which will result in most log messages being written to the console.

Create a `lib` directory below the target directory and copy the following `.jar` files from eXist-db into it:

-   `exist.jar`

-   `lib/extensions/exist-modules.jar`

-   `lib/core/antlr-X.X.X.jar`

-   `lib/core/commons-pool-X.X.jar`

-   `lib/core/commons-collections-X.X.jar`

-   `lib/core/commons-logging-X.X.X.jar`

-   `lib/core/log4j-X.X.X.jar`

-   `lib/optional/slf4j-api-X.X.X.jar`

-   `lib/optional/slf4j-log4j12-X.X.X.jar`

-   `lib/core/quartz-X.X.X.jar`

-   `lib/core/sunxacml.jar`

-   `lib/core/xmldb.jar`

-   `lib/core/xmlrpc-client-X.X.X.jar`

-   `lib/core/xmlrpc-common-X.X.X.jar`

-   `lib/core/xmlrpc-server-X.X.X.jar`

-   `lib/core/jta.jar`

-   `lib/core/pkg-repo.jar`

If you plan to use extension modules (like the n-gram index), you also need to copy the corresponding jars from `lib/extensions`. The default eXist configuration needs:

-   `exist-ngram-module.jar`

-   `exist-lucene-module.jar`

-   `exist-versioning.jar`

For the Lucene module you also need to copy the jars from `extensions/indexes/lib`:

-   `lucene-core-X.X.X.jar`

-   `lucene-regex-X.X.X.jar`

The `lib/endorsed` directory furthermore plays a special role: the Java releases come with their own XML support libraries, including Xalan for XSLT processing, an XML parser, and the standard Java interfaces for SAX and DOM. Some features of eXist will not work properly with a wrong version of Xerces or the resolver jar (schema validation, catalog loading, ...). To ensure that the correct versions are available, we have included these versions of Xerces, Xalan and Saxon, plus the standard interfaces used by both of them. You can use Java's endorsed library loading mechanism to ensure that the correct XML support libraries are loaded.

-   Create a directory `endorsed`

-   Copy all jar files from eXist's `lib/endorsed` directory into the newly created directory

Specifying the `-Djava.endorsed.dirs=lib/endorsed` system property on the Java command line will force the JVM to prefer any library it finds in the endorsed directory over its own system libraries. Copying the jars into `$JAVA_HOME/jre/lib/endorsed` will do the same thing. Note that the batch and shell scripts included with eXist all set the `java.endorsed.dirs` system property to point to `lib/endorsed`.

Make sure your CLASSPATH includes these jar files.

Internally, eXist has two different XML:DB driver implementations: the first communicates with a remote database engine using XML-RPC calls; the second has direct access to a local instance of eXist. Which implementation is selected depends on the XML:DB URI as described above. To access an embedded database, simply drop the host portion (i.e. `localhost:8088/xmlrpc/`) from the URI - for instance:

xmldb:exist:///db
To start an embedded database instance, simply set the system property exist.initdb to `true`. This will notify the XML:DB driver to read the configuration settings when starting the database if none has been previously started. For example, to launch your own Java application with an embedded instance, you may enter the command:

java -Dexist.initdb=true MyApp
The driver will try to read the eXist configuration file, create the required database files if they have not already been created, and launch the database. This of course implies that the driver should be able to read the configuration file `conf.xml`. In fact, the driver looks for `conf.xml` in the directory specified by the `exist.home` system property. You should therefore ensure a copy of `conf.xml` is placed in the correct directory. For example, to launch your own application, while setting `exist.home`, you may enter:

java -Dexist.initdb=true -Dexist.home=/home/exist/eXist MyApp
> **Important**
>
> Please note that the paths to the data and log directories in `conf.xml` need to point to *writable* directories.

Instead of using the `-Dexist.initdb` property, you can also tell the database driver to create a local database instance during the initialization of the XML:DB database manager. To do this, simply set the create-database property on the created `Database` object to `true` - for example:

``` java
Class cl = Class.forName("org.exist.xmldb.DatabaseImpl");
Database database = (Database) cl.newInstance();
database.setProperty("create-database", "true");
DatabaseManager.registerDatabase(database);
```

When running eXist in embedded mode, you must ensure to properly shut down the database before your application exits. The main reason for this action is to flush all of the unwritten data buffers to disk. The database uses a background thread to periodically synchronize its buffers with the data files on the disk, and this thread will keep running if you don't shut down the database.

There is a special XML:DB service, `DatabaseInstanceManager`, which contains a single method: shutdown. To properly shut down the database instance, retrieve the service from the `/db-collection` and call shutdown(). For example:

``` java
DatabaseInstanceManager 
manager = (DatabaseInstanceManager) 
    collection.getService("DatabaseInstanceManager", "1.0"); 
manager.shutdown();
```

To summarize, a minimal working class with a single static main to start/stop the db may look like this:

``` java
import org.xmldb.api.DatabaseManager;
import org.xmldb.api.base.Collection;
import org.xmldb.api.base.Database;
import org.exist.xmldb.DatabaseInstanceManager;

public class TestDB {       
    public static void main(String args[]) throws Exception {
        // initialize driver
        Class cl = Class.forName("org.exist.xmldb.DatabaseImpl");
        Database database = (Database)cl.newInstance();
        database.setProperty("create-database", "true");
        DatabaseManager.registerDatabase(database);
        
        // try to read collection
        Collection col = 
            DatabaseManager.getCollection("xmldb:exist:///db", "admin", "");
        String resources[] = col.listResources();
        System.out.println("Resources:");
        for (int i = 0; i < resources.length; i++) {
            System.out.println(resources[i]);
        }
        
        // shut down the database
        DatabaseInstanceManager manager = (DatabaseInstanceManager) 
            col.getService("DatabaseInstanceManager", "1.0"); 
        manager.shutdown();
    }
}
```

Put this code into a Java file `TestDB.java` and store it into the target directory, which we already prepared above. Compile and run it with:

javac TestDB.java java -Dexist.initdb=true -Dexist.home=. TestDB
