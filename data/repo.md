# Package Repository

## Introduction

The eXist-db package repository is a central component of eXist-db 2.0. It makes it easy to manage and deploy external packages (.xar archives) which include everything they need to run third party XQuery libraries, full applications or other XML technology functionality. This document provides technical details on the packaging format.

In previous versions of eXist-db, most applications were split into two parts:

-   the application code (XQuery modules, HTML pages etc.) residing in the webapp directory on the file system

-   the data stored inside the database

This split made it difficult to redistribute applications. For larger setups, maintenance easily became tedious. To solve those problems, eXist-db 2.0 introduces the concept of self-contained, modular applications which can be deployed into any database instance using a standardized packaging format. The eXist-db 2.0 distribution is built around this concept: documentation, examples and administration utilities have been moved out of the webapp directory and into separate application packages, which can be easily installed or removed on demand. The Dashboard is now the central hub for managing packages.

The package repository is based on and extends the [EXPath Packaging System](http://expath.org/modules/pkg/). The core of the EXPath packaging specification has been designed to work across different XQuery implementations and is targeted at managing extension libraries (including XQuery, Java or XSLT code modules). eXist-db extends this core by adding a facility for the automatic deployment of entire applications into the database.

eXist-db packages may fall into one of the following categories:

-   **Applications** containing application code, HTML views, associated services, resources and data. An application always has a web interface which can be displayed, if for example the user clicks on the application icon in the Dashboard.

-   **Resource packages** containing only data or resources used by other applications, e.g. JavaScript libraries shared by several application packages. A resource package has no web view, but needs to be deployed into the database.

-   **Library packages** providing a set of XQuery library modules to be registered with eXist-db and used by other packages. A library package may also contain Java jar archives to be loaded into the eXist-db classpath. It has no web view and is not deployed into the database.

Those categories are not exclusive: an application may also include resources and XQuery libraries and is not required to move those into separate packages.

## Creating Packages

Creating new packages is fairly easy if you use eXide. This is described in the [web development starter](development-starter.md) document. The following sections will cover some details of the packaging format from a more technical perspective.

## EXPath Packaging Format

An EXPath package is essentially an archive file in ZIP format. By convention, the file name extension of the package is `.xar`. The archive *must* contain two XML descriptor files in the root directory: `expath-pkg.xml` and `repo.xml`:

`expath-pkg.xml`  
This is the standard EXPath descriptor as defined by the EXPath specification. It specifies the unique name of the package, lists dependencies and any library modules to register globally.

`repo.xml`  
The eXist-db specific deployment descriptor: it contains additional metadata about the package and controls how it will be deployed into the database.

Though library packages do not really need `repo.xml`, we recommend to always provide both for better tool integration.

### Descriptors: expath-pkg.xml

As an example, the EXPath descriptor for the documentation app is shown below:

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://expath.org/ns/pkg" name="http://exist-db.org/apps/doc" abbrev="doc" version="0.3.2" spec="1.0">
    <title>eXist-db Documentation App</title>
    <dependency package="http://exist-db.org/apps/shared" semver-min="0.3.5"/>
</package>
```

The schema of this file is documented in the specification. In short, the attributes are as follows:

name  
a URI used as a unique identifier for the package. The URI does not need to point to an existing web site. The package repository will use this URI to identify a package within the system.

abbrev  
a short abbreviation for the package. This will be used as part of the file name for the `.xar`. We thus recommend to choose a short, simple name without spaces or punctuation characters.

version  
the version of the package: allows the Package Manager to determine if newer versions of the same package are available.

spec  
the version of the packaging specification the package conforms to. Always "1.0" for the current specification.

title  
a descriptive title to display to the user, e.g. in the Dashboard

### Dependency Management

As shown above, a package may depend on one or more other packages. The Package Manager in the Dashboard will resolve dependencies before deployment. Dependant packages will be installed automatically from the public repository. It is an error if a dependency cannot be resolved.

A dependency on another package is defined by reference to the unique name of the other package (as given in the name attribute (URI) of the expath-pkg.xml descriptor):

``` xml
<dependency package="http://exist-db.org/apps/shared"/>
```

It is also possible to create a dependency on a specific version, based on [Semantic Versioning](http://http://semver.org/). This can be done by adding either of the attributes: version, semver, semver-min, semver-max. The attributes are mutually exclusive, except for semver-min and semver-max, which may appear together.

version  
A simple version string which has to exactly match the version string of the package to install.

semver  
A "semantic" version string: the version number has to follow the scheme "x.x.x". Selects the highest version in the range of versions starting with semver. For example, if semver is "1.2", a package with version "1.2.3" will be selected because it is in the 1.2 release series. Likewise, if semver is "1", any package with a version starting with 1 will be chosen.

semver-min  
Defines a minimal required version according to the semver scheme.

semver-max  
Maximum version allowed.

We definitely recommend to prefer semver, semver-min and semver-max where possible.

In addition to dependencies on other packages, it is also possible to require a certain eXist-db version for a package. However, this is currently not enforced because it is difficult to determine versions reliably. The Dashboard will display a hint to the user though, informing about the requirement.

To require a specific eXist-db version, include a processor dependency in your descriptor:

&lt;dependency processor="eXist-db" version="trunk &gt; rev 18070"/&gt;
### Library Modules

A package may list one or more library modules to register with eXist-db. The registered modules will become globally available within the eXist-db instance and may be used by other packages without knowing where the module code is stored. For example, the following descriptor registers the module functx.xql using the given namespace:

``` xml
<package xmlns="http://expath.org/ns/pkg"
         name="http://www.functx.com"
         abbrev="functx"
         version="1.0"
         spec="1.0">

   <title>FunctX library</title>

   <xquery>
      <namespace>http://www.functx.com</namespace>
      <file>functx.xql</file>
   </xquery>

</package>
```

The namespace has to correspond to the namespace defined in the module declaration of the XQuery module. The file should be placed into a subdirectory of the .xar archive, named "content". The structure of the .xar for the functx library would thus look as follows:

    /expath-pkg.xml
    /repo.xml
    /content/functx.xql

Only XQuery files which are registered in expath-pkg.xml need to go into the special directory. You are free to keep other XQuery files wherever you want. Also, XQuery resources which are only used by a single application should *not* be registered (to avoid messing up the global context). Registering a module only makes sense for libraries which will likely be used by several applications.

After installing the package, you should be able to use the registered XQuery modules from anywhere within the database instance without knowing the exact import path. Thus the following import statement will be sufficient to import the functx module:

``` xquery
import module namespace functx="http://www.functx.com";

functx:capitalize-first('hello')
```

### Java Libraries

eXist-db also supports XQuery extension modules written in Java. They require a slightly different mechanism for integration into a `.xar` package. This is an extension to the standard EXPath format and should thus go into a separate file, named `exist.xml`. As an example, the exist.xml descriptor of the cryptographic extension module is shown below:

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://exist-db.org/ns/expath-pkg">
    <jar>expath-crypto.jar</jar>
    <java>
        <namespace>http://expath.org/ns/crypto</namespace>
        <class>org.expath.exist.crypto.ExistExpathCryptoModule</class>
    </java>
</package>
```

The descriptor may contain one or more jar elements, each pointing to a Java `.jar` archive to be installed. Arbitrary jars can be listed here: they do not need to be XQuery extension modules. Again, the jar files should be placed into the "content" subdirectory of the .xar file.

All jars will be dynamically added to eXist-db's class loader and become immediately available after deploying a package. A restart of eXist-db is not required.

The java element registers an XQuery extension module written in Java. This is similar to the xquery element discussed above, except that the namespace is mapped to a Java class instead of an XQuery file. The Java class should point to the `Module` class which defines the module.

## The repo.xml Deployment Descriptor

The deployment descriptor contains additional metadata and defines how the package will be installed into an eXist-db database instance. An example is given below:

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<meta xmlns="http://exist-db.org/xquery/repo">
    <description>eXist 2.0 documentation application.</description>
    <author>Joe Wicentowski</author>
    <author>Wolfgang Meier</author>
    <website>http://exist-db.org</website>
    <status>alpha</status>
    <license>GNU-LGPL</license>
    <copyright>true</copyright>
    <type>application</type>
    <target>doc</target>
    <prepare>pre-install.xql</prepare>
    <finish/>
    <permissions user="admin" password="" group="dba" mode="rw-rw-r--"/>
    <note>When upgrading, please make sure you also updated the shared-resources package to > 0.3.5.</note>
    <deployed/>
</meta>
```

The two settings: `type` and `target` determine how a package is handled by the installer:

| Type of package     | type        | target        |
|---------------------|-------------|---------------|
| Application package | application | specified     |
| Resource package    | library     | specified     |
| Library package     | library     | not specified |

So an application package has `type` set to "application" and specifies a `target` because it needs to be deployed into the database. Contrary to this, a library package only registers XQuery or other modules, but no resources need to be stored into the db, so `target` is empty.

The general metadata fields should not need to be explained. The relevant elements are:

type  
Should be set to either "application" or "library". We assume a library has no GUI (i.e. no HTML view). A library will thus not be shown on the main Dashboard page, which only lists applications.

target  
Specifies the collection where the contents of the package will be stored. Top-level files in the package will end up in this collection, resources in sub-directories will go into sub-collections. Please note that the target collection can be changed by the package manager during install. It is just a recommendation, not a requirement.

The collection path should always be relative to the repository root collection defined in the configuration.

permissions  
The permissions to use when uploading package contents. All resources and collections will be owned by the specified user and permissions will be changed to those given in `mode`. If the user does not exist, the deploy function will try to create it, using the password specified in attribute `password`.

Concerning permissions, the execute ("x") flag will be set automatically on all XQuery files in addition to the default permissions defined in the descriptor. For more control over permissions, use a post-install XQuery script (see element "finish" below).

prepare  
Points to an XQuery script inside the root of the package archive, which will be executed before any package data is uploaded to the database. By convention the XQuery script should be called `pre-install.xql`, though this is not a requirement.

If you create a package via eXide, it will generate a default `pre-install.xql` which uploads the default collection configuration to the system collection. This needs to be done before deployment to guarantee that index definitions are applied when data is uploaded to the db.

The target collection, the file system path to the current package directory and eXist-db's home directory are passed to the script as external variables:

(: file path pointing to the eXist-db installation directory :) declare variable $home external; (: path to the directory containing the unpacked .xar package :) declare variable $dir external; (: the target collection into which the app is deployed :) declare variable $target external;

The script may use those variables to read files contained in the package.

finish  
Like prepare, this element should point to an XQuery script, which will be executed *after* all data has been uploaded to the database. It receives the same external variables as the prepare script. The convention is to name the script `post-install.xql`.

Use the finish trigger to run additional tasks or move data into different collections. For example, the XQuery function documentation app runs an indexing task from the finish trigger to extract documentation from all XQuery modules known to the db at the time.

deployed  
This element will be set automatically when the package is deployed into a database instance. It is used by eXide to track changes and does not need to be specified in the original repo.xml descriptor.

## Configuring the repository root

The root collection for deployed packages can be configured in `conf.xml`:

``` xml
<repository root="/db/apps"/>
```

The install location specified in the `target` element of `repo.xml` will always be relative to this root collection.

eXist-db's URL rewriting is by default configured to map any path starting with `/apps` to the repository root collection. Check `webapp/WEB-INF/controller-config.xml` and the [URL rewriting documentation](http://localhost:8080/exist/apps/doc/urlrewrite.xml).

## Programmatically installing packages

The `repo` XQuery module provides a number of functions to programmatically install, remove or inspect packages. The Dashboard Package Manager relies on the same functions.

The module distinguishes between *installation* and *deployment* steps. The reason for this distinction is: while the installation process is standardized by the EXPath packaging specification, the deployment step is implementation defined and specific to eXist-db. *installation* will register a package with the EXPath packaging system, but not copy anything into the database. *Deployment* will deploy the application into the database as specified by the `repo.xml` descriptor.

The most convenient way to install a package are the `repo:install-and-deploy` and `repo:install-and-deploy-from-db` functions. repo:install-and-deploy downloads the specified package from a public repository. For example, one can install the eXist-db demo apps using the following call:

repo:install-and-deploy("http://exist-db.org/apps/demo", "0.2.2", "http://demo.exist-db.org/exist/apps/public-repo/modules/find.xql")
The first parameter denotes the unique name of the package to install. The second may contain a specific version or the empty sequence. The third parameter is the URI for the public repository API. The function call will download, install and deploy the package as well as any dependencies it defines. If the installation succeeds, an element will be returned to indicate the target collection into which the package was deployed.

The `repo:install-and-deploy-from-db` function works in a similar way, but reads the package data to install from a resource stored in the database.

To uninstall a package, you should first call `repo:undeploy`, followed by `repo:remove`, e.g.:

``` xquery
repo:undeploy("http://exist-db.org/apps/demo"), repo:remove("http://exist-db.org/apps/demo")
```

To list all installed packages, call `repo:list`, which will return a the unique name of every installed package.

## Running your own repository

You can run your private repository and install packages from it, e.g. to distribute applications to your customers. The eXist-db repository is implemented by the application package `http://exist-db.org/apps/public-repo`. The code can be downloaded from the [eXist-db GitHub](https://github.com/eXist-db/public-xar-repo) repo.

Once you have built and installed the app, you can upload the package xars you wish to distribute into the collection `public-repo/public`. To make the uploaded xars available, run the query `public-repo/modules/update.xql` once as an admin user. This will create a document `apps.xml` in `public-repo/public`.

## General considerations when writing a package

Packages should be portable and should thus not make any assumptions about the collection path in which they will be installed. In general it is best to use relative paths throughout XQuery modules, in particular for import statements. Just as a reminder: a relative path in an "import module namespace..." expression is always relative to the XQuery which contains the import.

If an XQuery needs to access data provided by another package, it should locate the other package by its package name and not by using an absolute collection path which may change in the future. For example, if an application requires access to data stored in another package called "data-pkg", it could define a variable to point to the correct collection as follows:

``` xquery
declare namespace expath = "http://expath.org/ns/pkg";

declare variable $local:data-pkg-collection :=
    let $descriptor := 
        collection(repo:get-root())//expath:package[@name = "http://foo.com/data-pkg"]
    return
        util:collection-name($descriptor)
;

(: Query data provided by data-pkg :)
collection($local:data-pkg-collection)//foo
```
