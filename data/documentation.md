# Documentation

## Recommended Reading

### Screencasts

![](https://img.youtube.com/vi/xvMau2aHRDo/1.jpg)

For the first steps with your freshly installed eXist-db, we suggest to watch the screencasts available on the [eXist-db homepage](http://exist-db.org).

If you are new to eXist-db, we recommend that you read these articles first:

| | |
| ---  | --- |
| [Quick Start](quickstart.md) | How to download, install, and get up and running with eXist-db. |
| [Dashboard](dashboard.md) | Using the package manager to install or remove packages. |
| [Getting Started with Web Application Development in eXist-db](development-starter.md) | eXist-db provides a complete platform for the development of rich web applications based on XML and related technologies |
| [Indexing](indexing.md) | Properly configured indexes have a huge impact on database performance! Some expressions might run a hundred times faster with an index. Must read. |
| [Learning XQuery](learning-xquery.md) | (For beginners) Tips and resources for learning XQuery for use with eXist-db. |
| [XQuery Support](xquery.md) | (For advanced developers) In depth discussion of eXist-db's support for the XQuery language, including features and extensions. |
| [Tuning the Database](tuning.md) | Tips and best practices for optimizing the performance of your queries. |

You can search the entire documentation library using the search box to the right. If you have questions that you can't find the answer to here, see the articles [Troubleshooting](troubleshooting.md) and [Getting Help](getting-help.md).

## All Documentation

Besides these articles, you can search eXist-db's XQuery [function module library]({fundocs}/index.html).

### Getting Started

| | |
| --- | --- |
| [Quick Start](quickstart.md) | How to download, install, and get up and running with eXist-db. |
| [Advanced Installation Methods](advanced-installation.md) | How to install on a headless system; how to run as a background service. |
| [Dashboard](dashboard.md) | Using the Dashboard to install applications from the eXist-db.org public application repository. |
| [Getting Started with Web Application Development in eXist-db](development-starter.md) | eXist-db provides a complete platform for the development of rich web applications based on XML and related technologies |
| [Uploading Files](uploading-files.md) | How to get your data into eXist-db. |
| [Upgrade Guide](upgrading.md) | Upgrading from an older version of eXist-db. |
| [Troubleshooting](troubleshooting.md) | Troubleshooting installation problems and other advanced installation topics. |

### General

| | |
| --- | --- |
| [Configuring Indexes](indexing.md) | How to configure indexes (*must read*). |
| [Deployment](deployment.md) | Alternatives for server deployment. |
| [Developer's Guide](devguide.md) | Using various interfaces: XML:DB API, XML-RPC, REST, SOAP. |
| [Using oXygen](oxygen.md) | How to set up oXygen XML Editor for use with eXist-db. |
| [Security](security.md) | Security features including authentication realms (LDAP, OAuth, OpenID), managing users and groups, changing passwords, and permissions and access controls. |
| [Server Configuration](configuration.md) | Configuring the server. |
| [Tuning the Database](tuning.md) | Tips and best practices for optimizing the performance of your queries. |
| [Package Repository](repo.md) | Manage libraries & application packages (.xar) using eXist-db Package Repository. |
| [Learning XQuery](learning-xquery.md) | Tips and resources for beginners learning XQuery for use with eXist-db. |
| [XQuery Support](xquery.md) | In depth discussion of eXist-db's support for the XQuery language, including features and extensions. |

### Documentation for Specific Features

| | |
| --- | --- |
| [Ant Tasks](ant-tasks.md) | How to automate tasks with Ant. |
| [Backup and Restore](backup.md) | How to backup/restore your database contents. |
| [Configuring Triggers](triggers.md) | How to configure triggers. |
| [Content Extraction](contentextraction.md) | How to extract content from binary files. |
| [HTTP-Related Functions](http-request-session.md) | The request and session modules contain functions for performing HTTP-related operations. |
| [JMX](jmx.md) | Java Management Extensions (JMX) support. |
| [Java Admin Client](java-admin-client.md) | Using the Java client from the command line. |
| [KWIC display module](kwic.md) | An XQuery module to easily produce a Keywords in Context (KWIC) output of search results. |
| [Lucene-based Full Text Index](lucene.md) | Apache Lucene integrated into eXist-db's XQuery engine. |
| [Replication](replication.md) | Configure two or more eXist-db instances to work together to automatically synchronize documents. |
| [Scheduler Module](scheduler.md) | An optional module to schedule jobs. |
| [URL Rewriting and MVC Framework](urlrewrite.md) | Simple-but-powerful URL rewriting and redirection. Provides some support for MVC (model-view-controller) and servlet-based pipelines. |
| [The util module](util.md) | A module with numerous useful utility functions. |
| [Validation](validation.md) | Validate XML documents. |
| [Versioning](versioning.md) | Versioning extensions. |
| [WebDAV](webdav.md) | How to setup your favourite WebDAV application. |
| [XACML](xacml.md) | XQuery access control. |
| [XInclude](xinclude.md) | XInclude support in eXist-db. |
| [XForms](xforms.md) | XForms support in eXist-db (using betterFORM or XSLTForms). |
| [The xmldb module](xmldb.md) | Functions for manipulating database contents. |
| [XQDoc](xqdoc.md) | The format for documenting XQuery library and main modules. |
| [XQuery Update Extensions](update_ext.md) | Extensions to update document fragments from within an XQuery. |
| [XQuery Debugger](debugger.md) | A debugging interface to XQuery code on the server. This is functional, but incomplete (the client side in particular). We used emacs and vi as our main clients during development. |
| [XSL Transformations](xsl-transform.md) | The transform module provides functions for directly applying an XSL stylesheet to an XML fragment within an XQuery script. |

### eXist-db Development

| | |
| --- | --- |
| [Getting Started with Web Application Development in eXist-db](development-starter.md) | eXist-db provides a complete platform for the development of rich web applications based on XML and related technologies |
| [Building eXist-db](building.md) | Compiling and building eXist-db from GitHub. |
| [eXist-db Developer Manifesto](devguide_manifesto.md) | Guidelines for contributing to the eXist-db codebase. |
| [Code Review Guide](devguide_codereview.md) | Notes on reviewing code during development. |
| [Test Guide](xqsuite.md) | Perform XQuery tests with the XQuery unit test suite. |
| [Log4J Logging Guide](devguide_log4j.md) | How use Log4J within eXist-db code. |
| [Developer's Guide to Modularized Indexes](devguide_indexes.md) | Describes how modularized indexes work through a use case. |
| [A Beginners Guide to XRX with eXist](beginners-guide-to-xrx-v4.md) | Describes how to use XForms to perform CRUD operations within an XRX framework. |

### Production use

| | |
| --- | --- |
| [Production use Good Practice](production_good_practice.md) | Best Practices for production environments. |
| [Proxying eXist-db behind a Web Server](production_web_proxying.md) | How to proxy eXist-db behind various web servers. |

### External Libraries

The following is an incomplete list of libraries to connect eXist-db with other languages.

| | |
| --- | --- |
| [XQJ](http://xqj.net/exist/) | An eXist-db driver for the XQuery API for Java (XQJ) |
| [nodejs](https://github.com/wolfgangmm/existdb-node) | node.js Client Module for the eXist-db Native XML Database |
| [PHP](https://github.com/CuAnnan/php-eXist-db-Client) | A client that abstracts out the XML RPC calls for eXist-db. |
| [XQuery for Scala](https://github.com/fancellu/xqs) | A Scala Library based on the XQuery API for Java (XQJ) |
