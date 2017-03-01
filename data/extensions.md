# XQuery Extension Modules Documentation

## Introduction

eXist-db provides a pluggable module interface that allows extension modules to be easily developed in Java. These extension modules can provide additional XQuery functions through a custom namespace. The extension modules have full access to the eXist-db database, its internal API, the context of the executing XQuery and the HTTP Session (if appropriate).

The source code for extension modules should be placed in their own folder inside `$EXIST_HOME/extensions/modules/src/org/exist/xquery/modules`. They may then be compiled in place using either `$EXIST_HOME/build.sh
        extension-modules` or `%EXIST_HOME%\build.bat extension-modules` depending on the platform.

Modules associated to modularized indexes should be placed in the `$EXIST_HOME/extensions/indexes/*/xquery/modules/*` hierarchy. They will be compiled automatically by the standard build targets or as indicated above.

eXist-db must also be told which modules to load, this is done in `conf.xml` and the Class name and Namespace for each module is listed below. Note – eXist-db will require a restart to load any new modules added. Once a Module is configured and loaded eXist-db will display the module and its function definitions as part of the [function library]({fundocs}) page or through `util:decribe-function()`.

## Example Module

Demonstrates the simplest example of an Extension module with a single function. A good place to start if you wish to develop your own Extension Module.

`Creator:` Wolfgang Meier `Licence:` LGPL `Status:` production

`Class:` org.exist.xquery.modules.example.ExampleModule `Namespace:` http://exist-db.org/xquery/examples

## Cache Module

Provides a global key/value cache

`Creator:` Evgeny Gazdovsky `Licence:` LGPL `Status:` production

`Class:` org.exist.xquery.modules.cache.CacheModule `Namespace:` http://exist-db.org/xquery/cache

## Compression Module

Provides additional operations for compression

`Creator:` Adam Retter `Licence:` LGPL `Status:` production

`Class:` org.exist.xquery.modules.compression.CompressionModule `Namespace:` http://exist-db.org/xquery/compression

## Context Module

Provides access to XQuery contexts, local attributes and foreign contexts for simple inter-XQuery communication. This extension is experimental at this time and has side effects (eg. not purely functional in nature). Use at own risk!

`Creator:` Andrzej Taramina `Licence:` LGPL `Status:` experimental

`Class:` org.exist.xquery.modules.context.ContextModule `Namespace:` http://exist-db.org/xquery/context

## Date Time Module

Provides additional operations on date and time types

`Creator:` Adam Retter `Licence:` LGPL `Status:` production

`Class:` org.exist.xquery.modules.datetime.DateTimeModule `Namespace:` http://exist-db.org/xquery/datetime

## EXI Module

Provides additional operations to encode and decode Efficient XML Interchange format (EXI)

`Creator:` Robert Walpole `Licence:` LGPL `Status:` production

`Class:` org.exist.xquery.modules.exi.EXIModule `Namespace:` http://exist-db.org/xquery/exi

## File Module

Provides additional operations on files and directories. WARNING: Enabling this extension module could result in possible security issues, since it allows writing to the filesystem by xqueries!

`Creator:` Andrzej Taramina, Chaeron Corporation `Licence:` LGPL `Status:` production

`Class:` org.exist.xquery.modules.file.FileModule `Namespace:` http://exist-db.org/xquery/file

## HTTP Client Module

Functions for performing HTTP requests

`Creator:` Adam Retter and Andrzej Taramina `Licence:` LGPL `Features Used:` NekoHTML `Status:` production

`Class:` org.exist.xquery.modules.http.HTTPClientModule `Namespace:` http://exist-db.org/xquery/httpclient

## Image Module

This modules provides operations on images stored in the db, including: Retreiving Image Dimensions, Creating Thumbnails and Resizing Images.

`Creator:` Adam Retter `Contributors:` Wolfgang Meier, Rafael Troilo `Licence:` LGPL `Status:` production

`Class:` org.exist.xquery.modules.image.ImageModule `Namespace:` http://exist-db.org/xquery/image

## JNDI Directory Module

This extension module allows you to access and manipulate JNDI-based directories, such as LDAP, using XQuery functions. It can be very useful if you want to integration and LDAP directory into an eXist-db/XQuery based application.

To compile it, set the parameter include.module.jndi = true in $EXIST\_HOME/extensions/local.build.properties file (create it if missing).

Then, to enable it, edit the appropriate module entry in conf.xml

`Creator:` Andrzej Taramina, Chaeron Corporation `Licence:` LGPL `Status:` production

`Class:` org.exist.xquery.modules.jndi.JNDIModule `Namespace:` http://exist-db.org/xquery/jndi

## Mail Module

This modules provides facilities for sending text and/or HTML emails from XQuery using either SMTP or a local Sendmail binary.

`Creator:` Adam Retter `Contributors:` Robert Walpole `Licence:` LGPL `Status:` production

`Class:` org.exist.xquery.modules.mail.MailModule `Namespace:` http://exist-db.org/xquery/mail

## Math Module

This module provides mathematical functions from the java Math class.

`Creator:` Dannes Wessels `Licence:` LGPL `Status:` production

`Class:` org.exist.xquery.modules.math.MathModule `Namespace:` http://exist-db.org/xquery/math

## Oracle Module

This module allows execution of PL/SQL Stored Procedures within an Oracle RDBMS from XQuery and returns the results as XML nodes. This module should be used where an Oracle database returns results in an Oracle REF\_CURSOR and can only be used in conjunction with the SQL extension module.

`Creator:` Rob Walpole `Licence:` LGPL `Status:` production

`Class:` org.exist.xquery.modules.oracle.OracleModule `Namespace:` http://exist-db.org/xquery/oracle

## Scheduler Module

Provides access to eXist-db's Scheduler for the purposes of scheduling job's and manipulating existing job's.

`Creator:` Adam Retter `Licence:` LGPL `Status:` production

`Class:` org.exist.xquery.modules.scheduler.SchedulerModule `Namespace:` http://exist-db.org/xquery/scheduler

## Simple Query Language Module

This modules implements a Simple custom Query Language which is then converted to XPath and executed against the db.

`Creator:` Wolfgang Meier `Licence:` LGPL `Status:` production

`Class:` org.exist.xquery.modules.simpleql.SimpleQLModule `Namespace:` http://exist-db.org/xquery/simple-ql

## Spatial module

Various functions for [GML](http://www.opengeospatial.org/standards/gml) geometries, whether indexed or not. More information about the design is available [here](devguide_indexes.md).

`Creator:` Pierrick Brihaye `Licence:` LGPL `Status:` experimental

`Class:` org.exist.xquery.modules.spatial.SpatialModule `Namespace:` http://exist-db.org/xquery/spatial

## SQL Module

This module provides facilities for performing SQL operations against traditional databases from XQuery and returning the results as XML nodes.

`Creator:` Adam Retter `Licence:` LGPL `Features Used:` JDBC `Status:` production

`Class:` org.exist.xquery.modules.sql.SQLModule `Namespace:` http://exist-db.org/xquery/sql

## XML Differencing Module

This module provides facilities for determining the differences between XML nodes.

`Creator:` Dannes Wessels `Contributors:` Pierrick Brihaye `Licence:` LGPL `Status:` production

`Class:` org.exist.xquery.modules.xmldiff.XmlDiffModule `Namespace:` http://exist-db.org/xquery/xmldiff

## XSL-FO Module

This module provides XSL-FO rendering facilities.

`Creator:` [University of the West of England](http://www.uwe.ac.uk) `Licence:` LGPL `Features Used:` [Apache FOP](http://xmlgraphics.apache.org/fop/) `Status:` production

`Class:` org.exist.xquery.modules.xslfo.XSLFOModule `Namespace:` http://exist-db.org/xquery/xslfo

## XProcxq Module

This module provides XProc functionality to eXist-db.

`Creator:` [James R. Fuller](http://www.webcomposite.com) `Licence:` MPL v1.1 `Features Used:` [expath http library](http://www.expath.org) `Status:` in development for v2.0 release

`Class:` static xquery module via extensions/xprocxq.jar `Namespace:` http://xproc.net/xproc

## XML Calabash Module

This module provides simple integration with XML Calabash XProc engine.

`Creator:` [James R. Fuller](http://www.webcomposite.com) `Licence:` MPL v1.1

`Class:` org.exist.xquery.modules.xmlcalabash `Namespace:`  http://xmlcalabash.com
