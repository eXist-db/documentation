# Developer's Guide

## Using the XML-RPC API

XML-RPC (XML Remote Procedural Call) provides a simple way to call remote procedures from a wide variety of programming languages. eXist's XML-RPC API makes it easy to access eXist from other applications, CGI scripts, PHP, JSP and more. For more information on XML-RPC see [www.xmlrpc.org](http://www.xmlrpc.org). For the Java server, eXist uses the XML-RPC library created by Hannes Wallnoefer which recently has moved to Apache (see: <http://xml.apache.org/xmlrpc>). Perl examples use the RPC::XML package, which should be available at every CPAN mirror (see [CPAN](http://www.cpan.org)).

The following is a small example, which shows how to talk to eXist-db from Java using the Apache XML-RPC library. This example can be found in `samples/org/exist/examples/xmldb/Retrieve.java`.

``` java
public class Retrieve {

protected final static String uri = 
    "http://localhost:8080/exist/xmlrpc";

protected static void usage() {
    System.out.println( "usage: org.exist.examples.xmlrpc.Retrieve " +
        "path-to-document" );
    System.exit( 0 );
}

public static void main( String args[] ) throws Exception {
    if ( args.length < 1 ) {
        usage();
    }
    XmlRpc.setEncoding("UTF-8");
    XmlRpcClient xmlrpc = new XmlRpcClient( uri );
    Hashtable options = new Hashtable();
    options.put("indent", "yes");
    options.put("encoding", "UTF-8");
    options.put("expand-xincludes", "yes");
    options.put("highlight-matches", "elements");
    
    Vector params = new Vector();
    params.addElement( args[0] ); 
    params.addElement( options );
    String xml = (String)
        xmlrpc.execute( "getDocumentAsString", params );
    System.out.println( xml );
}
}
```

As shown above, the execute method of `XmlRpcClient` expects as its parameters a method (passed as a string) to call on the server and a Vector of parameters to pass to this executed method. In this example, the method getDocumentAsString is called as the first parameter, and a Vector `params`. Various output properties can also be set through the hashtable argument (see the method description below). Since all parameters are passed in a Vector, they are necessarily Java objects.

XML-RPC messages (requests and responses sent between the server and client) are themselves XML documents. In some cases, these documents may use a character encoding which is in conflict with the encoding of the document we would like to receive. It is thus important to set the *transport* encoding to `UTF-8` as shown in the above example. However, conflicts may persist depending on which client library is used. To avoid such conflicts, eXist provides alternative declarations for selected methods, which expect string parameters as byte arrays. The XML-RPC library will send them as binary data (using Base64 encoding for transport). With this approach, document encodings are preserved regardless of the character encoding used by the XML-RPC transport layer.

> **Note**
>
> Please note that the XML-RPC API uses `int` to encode booleans. This is because some clients do not correctly pass boolean parameters.

Querying is as easy using XML-RPC. The following example:

``` java
#!/usr/bin/perl
use RPC::XML;
use RPC::XML::Client;

$query = <<'END';
for $speech in //SPEECH[LINE &= 'tear*']
order by $speech/SPEAKER[1]
return
    $speech
END

$URL = "http://guest:guest\@localhost:8080/exist/xmlrpc";
print "connecting to $URL...\n";
$client = new RPC::XML::Client $URL;

# Output options
$options = RPC::XML::struct->new(
    'indent' => 'yes', 
    'encoding' => 'UTF-8',
    'highlight-matches' => 'none');

$req = RPC::XML::request->new("query", $query, 20, 1, $options);
$response = $client->send_request($req);
if($response->is_fault) {
    die "An error occurred: " . $response->string . "\n";
}
print $response->value;
```

You will find the source code of this example in `samples/xmlrpc/search2.pl`. It uses the simple query method, which executes the query and returns a document containing the specified number of results. However, the result set is not cached on the server.

The following example calls the executeQuery method, which returns a unique session id. In this case, the actual results are cached on the server and can be retrieved using the retrieve method.

``` java
use RPC::XML;
#!/usr/bin/perl

use RPC::XML;
use RPC::XML::Client;

# Execute an XQuery through XML-RPC. The query is passed
# to the "executeQuery" method, which returns a handle to
# the created result set. The handle can then be used to
# retrieve results.

$query = <<'END';
for $speech in //SPEECH[LINE &= 'corrupt*']
order by $speech/SPEAKER[1]
return
    $speech
END

$URL = "http://guest:guest\@localhost:8080/exist/xmlrpc";
print "connecting to $URL...\n";
$client = new RPC::XML::Client $URL;

# Execute the query. The method call returns a handle
# to the created result set.
$req = RPC::XML::request->new("executeQuery", 
    RPC::XML::base64->new($query), 
    "UTF-8", {});
$resp = process($req);
$result_id = $resp->value;

# Get the number of hits in the result set
$req = RPC::XML::request->new("getHits", $result_id);
$resp = process($req);
$hits = $resp->value;
print "Found $hits hits.\n";

# Output options
$options = RPC::XML::struct->new(
    'indent' => 'no', 
    'encoding' => 'UTF-8');
# Retrieve query results 1 to 10
for($i = 1; $i < 10 && $i < $hits; $i++) {
    $req = RPC::XML::request->new("retrieve", $result_id, $i, $options);
    $resp = process($req);
    print $resp->value . "\n";
}

# Send the request and check for errors
sub process {
    my($request) = @_;
    $response = $client->send_request($request);
    if($response->is_fault) {
        die "An error occurred: " . $response->string . "\n";
    }
    return $response;
}
```

## XML-RPC: Available Methods

This section gives you an overview of the methods implemented by the eXist XML-RPC server. Only the most common methods are presented here. For a complete list see the Java interface [RpcAPI.java](api/org/exist/xmlrpc/RpcAPI.html). Note that the method signatures are presented below using Java data types. Also note that some methods like getDocument() and retrieve() accept a struct to specify optional output properties.

In general, the following optional fields for methods are supported:

indent  
Returns indented pretty-print XML. \[`yes | no`\]

encoding  
Specifies the character encoding used for the output. If the method returns a string, only the XML declaration will be modified accordingly.

omit-xml-declaration  
Add XML declaration to the head of the document. \[`yes |
                            no`\]

expand-xincludes  
Expand XInclude elements. \[`yes | no`\]

process-xsl-pi  
Specifying "yes": XSL processing instructions in the document will be processed and the corresponding stylesheet applied to the output. \[`yes | no`\]

highlight-matches  
Database adds special tags to highlight the strings in the text that have triggered a fulltext match. Set to "`elements`" to highlight matches in element values, "`attributes`" for attribute values or "`both`" for both elements and attributes.

stylesheet  
Use this parameter to specify an XSL stylesheet which should be applied to the output. If the parameter contains a relative path, the stylesheet will be loaded from the database.

stylesheet-param.key1 ... stylesheet-param.key2  
If a stylesheet has been specified with `stylesheet`, you can also pass it parameters. Stylesheet parameters are recognized if they start with the prefix `stylesheet-param.`, followed by the name of the parameter. The leading "`stylesheet-param.`" string will be removed before the parameter is passed to the stylesheet.

### Retrieving documents

-   byte\[\] getDocument(String name, Hashtable parameters)
    String getDocumentAsString(String name, Hashtable parameters)
    Retrieves a document from the database.

    name  
    Path of the document to be retrieved (e.g. `/db/shakespeare/plays/r_and_j.xml`).

    parameters  
    A struct containing `key=value` pairs for configuring the output.

-   Hashtable getDocumentData(String name, Hashtable parameters)
    Hashtable getNextChunk(String handle, Int offset)
    Hashtable getNextExtendedChunk(String handle, String offset)
    To retrieve a document from the database, but limit the number of bytes transmitted in one chunk to avoid memory shortage on the server, use the following:

    getDocumentData() returns a struct containing the following fields: `data`, `handle`, `offset`, `supports-long-offset`. `data` contains the document's data (as `byte[]`) or the first chunk of data if the document size exceeds the predefined internal limit. `handle` and `offset` can be passed to getNextChunk() or getNextExtendedChunk() to retrieve the remaining data chunks. `supports-long-offset`, when available, tells whether the server understands getNextExtendedChunk() method.

    If `offset` is 0, no more chunks are available and all of the data is already contained in the `data` field. Otherwise, further chunks can be retrieved by passing the handle and the offset (as returned by the last call) to getNextChunk() or getNextExtendedChunk(). Once the last chunk is read, `offset` will be 0 and the handle becomes invalid.

    getNextChunk() and getNextExtendedChunk() do more or less the same, but with the difference that getNextExtendedChunk() does not have the 2GB limitation in `offset`. As previous eXist servers could not implement it, you must take into account the `supports-long-offset` parameter from getDocumentData() returned structure.

    name  
    Path of the document to be retrieved (e.g. `/db/shakespeare/plays/r_and_j.xml`).

    parameters  
    A struct containing `key=value` pairs to configure the output.

    handle  
    The handle returned by the call to getDocumentData(). This identifies a temporary file on the server to be read.

    offset  
    The data offset in the document at which the next chunk in the sequence will be read.

### Storing Documents

-   boolean parse(byte\[\] xml, String docName, int overwrite)
    boolean parse(byte\[\] xml, String docName)
    Inserts a new document into the database or replace an existing one:

    xml  
    XML content of this document as a UTF-8 encoded byte array.

    docName  
    Path to the database location where the new document is to be stored.

    overwrite  
    Set this value to &gt; 0 to automatically replace an existing document at the same location.

-   String upload(byte\[\] chunk, int length)
    String upload(String file, byte\[\] chunk, int length)
    boolean parseLocal(String localFile, String docName, boolean replace)
    Uploads an entire document on to the database before parsing it.

    While the parse method receives the document as a large single chunk, the upload method allows you to upload the whole document to the server before parsing. This way, *out-of-memory* exceptions can be avoided, since the document is not entirely kept in the main memory. To identify the file on the server, upload returns an identifier string. After uploading all chunks, you can call parseLocal and pass it this identifier string as the first argument.

    file  
    The name of the file to which the uploaded chunk is appended. This is the name of a temporary file on the server. Use the two-argument version of upload for the first chunk. The method creates a temporary file and returns its name. On subsequent calls to this chunk, pass this name.

    chunk  
    A byte array containing the data to be appended.

    length  
    Defines the number of bytes to be read from chunk.

    localFile  
    The name of the local file on the server that is to be stored in the database. This should be the same as the name returned by upload.

    docName  
    The full path specifying the location where the document should be stored in the database.

    replace  
    Set this to `true` if an existing document with the same name should be automatically overwritten.

### Creating a Collection

-   boolean createCollection(String name)
    Creates a new collection

    name  
    Path to the new collection.

### Removing Documents or Collections

-   boolean remove(String docName)
    Removes a document from the database.

    docName  
    The full path to the database document.

-   boolean removeCollection( String collection)
    Removes a collection from the database (including all of its documents and sub-collections).

    collection  
    The full path to the collection.

### Querying

-   int executeQuery(String xquery, HashMap parameters)
    int executeQuery(byte\[\] xquery, HashMap parameters)
    int executeQuery(byte\[\] xquery, String encoding, HashMap parameters)
    Executes an XQuery and returns a reference identifier to the generated result set. This reference can be used later to retrieve results.

    xquery  
    A valid XQuery expression.

    parameters  
    The parameters a HashMap values.

    sort-expr :

    namespaces :

    variables :

    base-uri :

    static-documents :

    protected :

    encoding  
    The character encoding used for the query string.

-   Hashtable querySummary(int result-Id)
    Returns a summary of query results for the result-set referenced by `result-Id`.

    The `result-Id` value is taken from a previous call to executeQuery (See above). The querySummary method returns a struct with the following fields: `queryTime`, `hits`, `documents`, `doctype`.

    `queryTime` and `hits` are integer values that describe the processing time in milliseconds for the query execution and the number of hits in the result-set respectively. The field `documents` is an array of an array (i.e. `Object[][3]`) that represents a table in which each row identifies one document. The first field in each row contains the `document-id` (integer value). The second has the document's name as a string value. The third contains the number of hits found in this document (integer value).

    The`doctype` field is also an array of an array (Object\[\]\[2\]) that contains the `doctype` public identifier and the number of hits found for this `doctype` in each row.

    resultId  
    Reference to a result-set as returned by a previous call to executeQuery.

-   byte\[\] retrieve(int resultId, int pos, Hashtable parameters)
    Retrieves a single result-fragment from the result-set referenced by `resultId`. The result-fragment is identified by its position in the result-set, which is passed in the parameter `pos`.

    resultId  
    Reference to a result-set as returned by a previous call to executeQuery.

    pos  
    The position of the item in the result-sequence, starting at 0.

    parameters  
    A struct containing `key=value` pairs to configure the output.

-   Hashtable retrieveFirstChunk(int resultId, int pos, Hashtable parameters)
    Retrieves a single result-fragment from the result-set referenced by `resultId`, but limiting the number of bytes transmitted in one chunk to avoid memory shortage on the server. The result-fragment is identified by its position in the result-set, which is passed in the parameter `pos`. It returns the same structure as getDocumentData(), and its fields behaves the same, so next chunks must be fetched using either getNextChunk() or getNextExtendedChunk() (see getDocumentData() documentation for further details).

    resultId  
    Reference to a result-set as returned by a previous call to executeQuery.

    pos  
    The position of the item in the result-sequence, starting at 0.

    parameters  
    A struct containing `key=value` pairs to configure the output.

-   int getHits(int resultId)
    Get the number of hits in the result-set identified by `resultId`.

    resultId  
    Reference to a result-set as returned by a previous call to executeQuery.

-   String query(byte\[\] xquery, int howmany, int start, Hashtable parameters)
    Executes an XQuery expression and returns a specified subset of the results. This method will directly return a subset of the result-sequence, starting at `start`, as a new XML document. The number of results returned is determined by parameter `howmany`. The result-set will be deleted on the server, so later calls to this method will again execute the query.

    xquery  
    An XQuery expression.

    start  
    The position of the first item to be retrieved from the result-sequence.

    howmany  
    The maximum number of items to retrieve.

    parameters  
    A struct containing `key=value` pairs to configure the output.

-   void releaseQueryResult(int resultId)
    Forces the result-set identified by its result id to be released on the server.

### Retrieving Information on Collections and Documents

-   Hashtable describeCollection(String collection)
    Returns a struct describing a specified collection.

    The returned struct has the following fields: `name` (the collection path), `owner` (identifies the collection owner), `group` (identifies the group that owns the collection), `created` (the creation date of the collection expressed as a long value), `permissions` (the active permissions that apply to the collection as an integer value).

    `collections` is an array listing the names of available sub-collections in this collection.

    collection  
    The full path to the collection.

-   Hashtable describeResource(String resource)
    Returns a struct describing a specified resource.

    The returned struct has the following fields: `name` (the collection path), `owner` (identifies the collection owner), `group` (identifies the group that owns the collection), `created` (the creation date of the collection expressed as a long value), `permissions` (the active permissions that apply to the collection as an integer value), `type` (either `XMLResource` for XML documents or `BinaryResource` for binary files), `content-length` (the estimated size of the resource in bytes). The `content-length` is based on the number of pages occupied by the resource in the DOM storage. For binary resources, the value will always be 0.

-   Hashtable getCollectionDesc(String collection)
    Returns a struct describing a collection.

    The returned struct has the following fields: `name` (the collection path), `owner` (identifies the collection owner), `group` (identifies the group that owns the collection), `created` (the creation date of the collection expressed as a long value), `permissions` (the active permissions that apply to the collection as an integer value).

    `collections` is an array listing the names of available sub-collections in this collection.

    `documents` is an array listing information on all of the documents in this collection. Each item in the array is a struct with the following fields: name, owner, group, permissions, type. The type field contains a string describing the type of the resource: either `XMLResource`or `BinaryResource`.

    collection  
    The full path to the collection.

### XUpdate

-   int xupdate(String collectionName, byte\[\] xupdate)
    int xupdateResource(String documentName, byte\[\] xupdate)
    Applies a set of XUpdate modifications to a collection or document.

    collectionName  
    The full path to the collection to which the XUpdate modifications should be applied.

    documentName  
    The full path to the document to which the XUpdate modifications should be applied.

    xupdate  
    The XUpdate document containing the modifications. This should be send as an `UTF-8` encoded binary array.

### Managing Users and Permissions

-   boolean setUser(String name, String passwd, String digestPasswd, Vector groups)
    boolean setUser(String name, String passwd, String digestPasswd, Vector groups, String home)
    Modifies or creates a database user.

    name  
    Username value.

    passwd  
    The plain-text password for the user.

    digestPasswd  
    The md5 encoded password for the user.

    groups  
    A vector of groups assigned to the user. The first group in the vector will become the user's primary group.

    home  
    An optional setting for the user's home collection path. The collection will be created if it does not exist, and provides the user with full access.

-   boolean setPermissions(String resource, String permissions)
    boolean setPermissions(String resource, int permissions)
    boolean setPermissions(String resource, String owner, String ownerGroup, String permissions)
    boolean setPermissions(String resource, String owner, String ownerGroup, int permissions)
    Sets the permissions assigned to a given collection or document.

    resource  
    The full path to the collection or document on which the specified permissions will be set. The method first checks if the specified path points to a collection or resource.

    owner  
    The name of the user owning this resource.

    ownerGroup  
    The name of the group owning this resource.

    permissions  
    The permissions assigned to the resource, which can be specified either as an integer value constructed using the [Permission](api/org/exist/security/Permission) class, or using a modification string. The bit encoding of the integer value corresponds to Unix conventions. The modification string has the following syntax:

    \[user|group|other\]=\[+|-\]\[read|write|update\]\[, ...\]

-   Hashtable getPermissions(String resource)
    Returns the active permissions for the specified document or collection.

    The returned struct has the following fields: `name` (the collection path), `owner` (identifies the collection owner), `group` (identifies the group that owns the collection), `created` (the creation date of the collection expressed as a long value), `permissions` (the active permissions that apply to the collection as an integer value).

-   boolean removeUser(String name)
    Removes the identified user.

-   Hashtable getUser(String name)
    Returns a struct describing the user identified by its name.

    The returned struct has the following fields: `name` (the collection path), `home` (identifies the user's home directory), `groups` (an array specifying all groups to which the user belongs).

-   Vector getUsers()
    Returns a list of all users currently known to the system.

    Each user in the list is described by the same struct returned by the getUser() method.

-   Vector getGroups()
    Returns a list of all group names (as string values) currently defined.

### Access to the Index Contents

The following methods provide access to eXist's internal index structure.

-   Vector getIndexedElements(String collectionName, boolean inclusive)
    Returns a list (i.e. array\[\]\[4\]) of all indexed element names for the specified collection.

    For each element, an array of four items is returned:

    1.  name of the element

    2.  optional namespace URI

    3.  optional namespace prefix

    4.  number of occurrences of this element as an integer value

    collectionName  
    The full path to the collection.

    inclusive  
    If set to `true`, the subcollections of the specified collection will be included into the result.

-   Vector scanIndexTerms(String collectionName, String start, String end, boolean inclusive)
    Return a list (array\[\]\[2\]) of all index terms contained in the specified collection.

    For each term, an array with two items is returned:

    1.  the term itself

    2.  number occurrences of the term in the specified collection

    collectionName  
    The full path to the collection.

    start  
    The start position for the returned range expressed as a string value. Returned index terms are positioned after the start position in ascending, alphabetical order.

    end  
    The end position for the returned range expressed as a string value. Returned index terms are positioned before the end position in ascending, alphabetical order.

    inclusive  
    If set to`true`, subcollections of the specified collection will be included into the result.

### Other Methods

-   boolean shutdown()
    Shuts down the database engine. All dirty pages are written to disk.

-   boolean sync()
    Causes the database to write all dirty pages to disk.
