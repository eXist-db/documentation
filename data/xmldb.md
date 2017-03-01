# The xmldb module

## Introduction

The xmldb module (in the <http://exist-db.org/xquery/xmldb> function namespace) contains functions for manipulating database contents. The full list of functions and their documentation is in the [Function Documentation Library](/exist/apps/fundocs/view.html?uri=http://exist-db.org/xquery/xmldb&location=java:org.exist.xquery.functions.xmldb.XMLDBModule). This article discusses some of the highlights and main uses for this module.

## Manipulating Database Contents

The xmldb functions can be used to create new database collections, or to store query output into the database. To illustrate, suppose we have a large file containing several RDF metadata records, but we do not want to store the metadata records in a single file, since our application expects each record to have its own document. In this case, we must divide the document into smaller units. Using an XSLT stylesheet would be one way to accomplish this; however, this is quite memory-intensive, and the preferable option is to use XQuery to do the job.

The XQuery script below shows how to split a large RDF file into a series of smaller documents:

``` xquery
xquery version "3.0";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";

let $log-in := xmldb:login("/db", "admin", "")
let $create-collection := xmldb:create-collection("/db", "output")
for $record in doc('/db/records.rdf')/rdf:RDF/*
let $split-record := 
    <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        {$record}
    </rdf:RDF>
let $about := $record/@rdf:about
let $filename := util:hash($record/@rdf:about/string(), "md5") || ".xml"
return
    xmldb:store("/db/output", $filename, $split-record)
```

Let's look at this script in some detail. First, since we are using functions xmldb:create-collection() and xmldb:store(), which require the user to be logged in as a member of the dba group, we must log in using xmldb:login(). Once logged in, we can create a new sub-collection, called "output" using `xmldb:create-collection`, for which we need to be logged in appropriately using `xmldb:login`.

Next, the `for`-loop iterates through all child elements of the top RDF element. In each iteration, we use `xmldb:store` to write out the current child node to a new document. Since a unique document name is required for each new document, we need a way to generate unique names. In this case, the URI contained in the `rdf:about` attribute is unique, so we simply compute an MD5 key from it, append the ".xml" extension, and use it as the document's name.

## Specifying the Input Document Set

A database can contain a virtually unlimited set of collections and documents. Four functions are available to restrict the input document set to a user-defined set of documents or collections: `doc()`, `xmldb:document()`, `collection()` and `xmldb:xcollection()`. The `collection()` and `doc()` functions are standard XQuery/XPath functions, whereas `xmldb:xcollection()` and `xmldb:document()` are eXist-db-specific extensions.

Without an URI scheme, eXist-db interprets the arguments to `collection()` and `doc()` as absolute or relative paths, leading to some collection or document within the database. For example:

doc("/db/collection1/collection2/resource.xml")
refers to a resource stored in `/db/collection1/collection2`.

doc("resource.xml")
references a resource relative to the base URI property defined in the static XQuery context. The base URI contains an XML:DB URI pointing to the base collection for the current query context, e.g. `xmldb:exist:///db`.

The base collection depends on how the query context was initialized. If you call a query via the XML:DB API, the base collection is the collection from which the query service was obtained. All relative URLs will be resolved relative to that collection. If a stored query is executed via REST, the base collection is the collection in which the XQuery source resides. In most other cases, the base collection will point to the database root /db.

> **Note**
>
> As it might not always be clear what the base collection is, we recommend to use an explicit path to access a document. This makes it easier to use a query via different interfaces.

You can also pass a full URI to the `doc()` function:

doc("http://localhost:8080/exist/servlet/db/test.xml")
in this case, the URI will be retrieved and the data stored into a temporary document in the database.

doc() /
xmldb:document()  
While `doc()` is restricted to a single document-URI argument, `xmldb:document()` accepts multiple document paths to be included into the input node set. Second, calling `xmldb:document()` without an argument includes *EVERY* document node in the current database instance. Some examples:

doc("/db/apps/demo/data/hamlet.xml")//SPEAKER

xmldb:document('/db/test/abc.xml', '/db/test/def.xml')//title

collection() /
xmldb:xcollection()  
The `collection()` function specifies the collection of documents to be included in the query evaluation. By default, documents found in subcollections of the specified collection are also included. For example, suppose we have a collection `/db/test` that includes two subcollections `/db/test/abc` and `/db/test/def`. In this case, the function call `collection('/db/test')` will include all of the resources found in `/db/test`, `/db/test/abc` and `/db/test/def`.

The function `xmldb:xcollection()` can be used to change the behavior of `collection()`. For instance, the function call

xmldb:xcollection('/db/test')//title

will ONLY include resources found in `/db/test`, but NOT in `/db/test/abc` or `/db/test/def`.
