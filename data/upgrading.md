# Upgrade Guide

## General Information

Never install a new version of eXist-db into the same directory as an older version:

Create a [backup](backup.md) of your data. If the new version is *binary compatible* with the old version, keep the data directory (by default in `webapp/WEB-INF/data`) of the old version. Note: A running instance of eXist-db needs to be stopped before copying files from the data dir.

Install the new version into a different location.

If the new version is *binary compatible*, replace the data directory of the new install with the one from the old one.

Otherwise you need to do a full [restore](backup.xml#restore) of the data.

## Upgrading to 3.0 stable

eXist-db v3.0 is not binary compatible with previous versions of eXist-db; the on-disk database file format has been updated, users should perform a full backup and restore to migrate their data.

eXist.db v3.0 and subsequent versions now require *Java 8*; Users must update to Java 8!

3.0 removes the the legacy Full Text Index and the text (http://exist-db.org/xquery/text) XQuery module. Users should now look toward `fn:analyze-string`, e.g.

1.  instead of using `text:groups()` use `analyze-string()//fn:group`,

2.  instead of `text:filter("apparat", "([pr])")` use `analyze-string("apparat", "([pr])")//fn:match/string())`.

Furthermore, the SOAP APi, SOAP server, and XACML Security features were removed.

The versioning extension is now available as a separate [EXPATH package](https://github.com/eXist-db/xquery-versioning-module)

XQueryService has been moved from `DBBroker` to `BrokerPool`.

EXPath packages that incorporate Java libraries may no longer work with eXist-db v3.0 and may need to be recompiled for our API changes; packages should now explicitly specify the eXist-db versions that they are compatible with.

eXist-db v3.0 is the culmination of almost 1,500 changes. For more information on new features head to the [blog](http://exist-db.org/exist/apps/wiki/blogs/eXist//eXist-db-v3).

## Upgrading to 2.2 final

The 2.2 release is not binary compatible with the 1.4.x series. You need to backup/restore. If you experience problems with user logins after the restore, please restart eXist-db.

2.2 introduces a *new range index module*. Old index definitions will still work though as we made sure to keep backwards compatible. If you would like to upgrade to the new index, check its [documentation](newrangeindex.md).

The XQuery engine has been updated to support the changed syntax for *maps in XQuery 3.1*. The query parser will still accept the old syntax for map constructors though (`map { x:= "y"}` instead of `map { x: "y" }` in XQuery 3.1), so old code should run without modifications. All map module functions from XQuery 3.1 are [available]({fundocs}/view.html?uri=http://www.w3.org/2005/xpath-functions/map&location=java:org.exist.xquery.functions.map.MapModule).

The signatures for some *higher-order utility functions* like fn:filter, fn:fold-left and fn:fold-right have changed as well. Please review your use of those functions. Also, fn:map is now called fn:for-each, though the old name is still accepted.

The bundled Lucene has been upgraded from 3.6.1 to 4.4 with this release. Depending on what Lucene analyzers you are using you need to change the classnames in your `collection.xconf`s. E.g. KeywordAnalyzer and WhitespaceAnalyzer has moved into package `org.apache.lucene.analysis.core`. Thus change, any occurrence of `org.apache.lucene.analysis.WhitespaceAnalyzer` into `org.apache.lucene.analysis.core.WhitespaceAnalyzer` and all other moved classes in the collection configurations and make sure you reindex your data before use. You get an error notice in the `exist.log` if you overlooked any occurrences.

## Upgrading to 2.1

The 2.1 release is not binary compatible with the 1.4.x series. You need to backup/restore. 2.1 is binary compatible with 2.0 though.

## Upgrading to 2.0

The 2.0 release is not binary compatible with the 1.4.x series. You need to backup/restore.

### Special Notes

Permissions  
eXist-db 2.0 closely follows the Unix security model (plus ACLs). Permissions have thus changed between 1.4.x and 2.0. In particular, there's now an execute permission, which is required to

1.  execute an XQuery via any of eXist-db's interfaces

2.  change into a collection to view or modify its contents

eXist-db had an update permission instead of the execute permission. Support for the update permission has been dropped because it was not used widely.

When restoring data from 1.4.x, you thus need to make sure that:

1.  collections have the appropriate execute permission

2.  XQueries are executable

You can use an XQuery to automatically apply a default permission to every collection and XQuery, and then change them manually for some collections or resources.

``` xquery
xquery version "3.0";

import module namespace dbutil="http://exist-db.org/xquery/dbutil";

dbutil:find-by-mimetype(xs:anyURI("/db"), "application/xquery", function($resource) {
    sm:chmod($resource, "rwxr-xr-x")
}),
dbutil:scan-collections(xs:anyURI("/db"), function($collection) {
    sm:chmod($collection, "rwxr-xr-x")
})
```

Webapp Directory  
Contrary to 1.4.x, eXist-db 2.0 stores most web applications into the database. The webapp directory is thus nearly empty. It is still possible to put your web application there and it should be accessible via the browser in the same way as before.

## Upgrading to 1.4.0

The 1.4 release is not binary compatible with the 1.2.x series. You need to backup/restore.

### Special Notes

Indexing  
eXist-db 1.2.x used to create a default full text index on all elements in the db. This has been *disabled*. The main reasons for this are:

1.  maintaining the default index costs performance and memory, which could be better used for other indexes. The index may grow very fast, which can be a destabilizing factor.

2.  the index is unspecific. The query engine cannot use it as efficiently as a dedicated index on a set of named elements or attributes. Carefully creating your indexes by hand will result in much better performance.

Please consider using the new Lucene-based full text index. However, if you need to switch back to the old behaviour to ensure backwards compatibility, just edit the system-wide defaults in conf.xml:

                                    <index>
        <fulltext attributes="false" default="none">
            <exclude path="/auth"/>
        </fulltext>
    </index>
                                

Document Validation  
Validation of XML documents during storage is now *turned off by default* in `conf.xml`:

&lt;validation mode="no"&gt;

The previous `auto` setting was apparently too confusing for new users who did not know what to do if eXist-db refused to store a document due to failing validation. If you are familiar with [validation](validation.md), the use of catalog files and the like, feel free to set the default back to `auto` or `yes`.

Cocoon  
eXist-db does no longer require Cocoon for viewing documentation and samples. Cocoon has been largely replaced by eXist-db's own [URL rewriting and MVC framework](urlrewrite.md).

Consequently, we now limit Cocoon to one directory of the web application (`webapp/cocoon`) and moved all the Cocoon samples in there. For the 1.5 version we completely removed Cocoon support.
