# XInclude Examples

## Introduction

eXist-db comes with partial support for the XInclude standard. As default, eXist-db's XML serializer will scan all XML fragments for XInclude tags. The XInclude processor is implemented as a filter which sits between the serializer's output event stream and the receiver. If it finds an XInclude element, it will try to expand it. The current element in the stream is replaced by the result of the XInclude operation. XInclude processing is thus applied whenever eXist-db serializes an XML fragment, be it a document, the result of an XQuery or an XSLT stylesheet.

eXist-db's support for XInclude is not complete. You cannot directly include raw text, only XML. XPointers are restricted to XPath; the additional features defined in the XPointer spec (points and locations) are not supported by eXist-db (in fact, no applications support these at the present time), though with eXist-db one can use XPath functions to partly substitute for XPointer's important string-range() function.

eXist-db expands XIncludes at serialization time, which means that the query engine will see the XInclude tags *before* they are expanded. You therefore cannot query across XIncludes - unless you create your own code (e.g. an XQuery function) for it. We would certainly like to support queries over xincluded content in the future though.

DTD entity declarations can be used for some of the things that XInclude can be used for; in general, however, XInclude is more powerful (except that entity declarations are able include raw text).

The following sections present some examples of how XInclude can be used in eXist-db.

> **Note**
>
> In order to see the live effect of most of the examples below, install the Demo app via the [Package Manager]({dashboard}) in the [Dashboard]({dashboard}). You are probably reading this through the Documentation app, but if you are not, you should install this as well.

## Including an Entire Document

To include an entire document, just specify its path in the `href` attribute of an xi:include tag. For example, one can include a standard disclaimer, stored in the file short-disclaimer.xml, as follows:

&lt;xi:include href="/db/apps/doc/data/disclaimer-short.xml"/&gt;
The result is included below:

For this XInclude example to work, you need to install the Documentation application. See the Package Manager in the Dashboard.
Please note that you have to provide the correct namespace for XInclude, e.g. in the root element of the document. The official namespace is:

http://www.w3.org/2001/XInclude
## Error Handling

An error will be generated if you try to xinclude a resource which does not exist. You can specify a fallback to avoid the error. The result of the XInclude will be the content of the xi:fallback element:

&lt;xi:include href="I-do-not exist.xml"&gt; &lt;xi:fallback&gt;&lt;p&gt;The included document was not found!&lt;/p&gt;&lt;/xi:fallback&gt; &lt;xi:include&gt;
See the result below:

The included document was not found!
Note that a fallback element cannot contain an XInclude.

## Selection by ID

The `xpointer` attribute is used to identify a portion of the resource to include. If the xpointer contains the value of an attribute of type ID, it will select the element of the target document that has a matching attribute of type ID. For example, the following XInclude selects the p element from file `disclaimer.xml`, which has an ID attribute with value "statement".

&lt;xi:include href="disclaimer.xml" xpointer="p"/&gt;
The result of the XInclude is displayed below:

For this XInclude example to work, you need to install the Documentation application. See the Package Reposistory in the Admin panel.
Note that in case there are several instances of the same ID attribute, only the first instance will be selcted.

## Selecting a Fragment by an XPath Expression

We may also use an XPath expression to select fragments. The `xpointer` attribute contains an XPointer, which consists of so called "schemes". An XPath expression can be passed to the `xpointer()` XPointer scheme. The results of the expression will be included in place of the xi:include element. The following expression includes the first stage direction in Shakespeare's Macbeth:

&lt;xi:include href="/db/apps/demo/data/macbeth.xml" xpointer="xpointer(//PLAY/ACT\[1\]/SCENE\[1\]/STAGEDIR\[1\])"/&gt;
As before, the results are included below:

For this XInclude example to work, you need to install the Demo application. See the Package Reposistory in the Admin panel.
## Selecting a Fragment by a Search Expression

XIncludes can perform searches, e.g. using full-text search.

&lt;xi:include href="/db/apps/demo/data/hamlet.xml" xpointer="xpointer(//SPEECH\[ft:query(., '"slings and arrows"')/LINE\[1\])"/&gt;
As before, the results are included below:

For this XInclude example to work, you need to install the Demo application. See the Package Reposistory in the Admin panel.
Note that only the first hit is retrieved – one cannot in this way list all the instances of the word "love" in Romeo and Juliet.

An XPath expression will be applied to the entire collection if the path in href points to a collection and not a single document:

&lt;xi:include href="/db/apps/demo/data" xpointer="xpointer(//SPEECH\[ft:query(., '"cursed spite"')\]/LINE\[1\])"/&gt;
For this XInclude example to work, you need to install the Demo application. See the Package Reposistory in the Admin panel.
## Namespaces

All namespace/prefix mappings declared in the source document are passed to the query context. Alternatively, you may declare mappings with xmlns().

&lt;xi:include href="disclaimer.xml" xpointer="xpointer(//comment:comment) xmlns(comment=http://test.org)"/&gt;
For this XInclude example to work, you need to install the Demo app. See the Package Reposistory in the Admin panel.
## Transforming XInclude Results

XPath functions can be used to transform the result of an XInclude. This can be done for presentation: if a sequence of elements are returned, one might want to render them on separate lines.

&lt;xi:include href="/db/apps/demo/data" xpointer="xpointer(string-join( //SPEECH\[ft:query(., '"cursed spite"')\]/LINE , '&\#xA;'))"/&gt;
For this XInclude example to work, you need to install the Demo application. See the Package Reposistory in the Admin panel.
## Implementing XPointer string-range()

One reason why the XPointer spec has hardly seen any implementation is that it operates with "points" and "locations" which can have no meaning in the XQuery/XPath Data Model. However, a major use case for the XPointer specification is to allow pointing at a range of characters inside an element and this is possible using the XPath functions string-join() and substring().

Here a range of characters in the text node of a LINE element are extracted which is 20 characters long and starts with the 22nd character.

&lt;xi:include href="/db/apps/demo/data" xpointer="xpointer( substring(string-join( //PLAY/ACT\[3\]/SCENE\[1\]/SPEECH\[19\]/LINE\[1\] ,''), 22, 20) )"/&gt;
For this XInclude example to work, you need to install the Demo application. See the Package Reposistory in the Admin panel.
Since only the string contents is involved, such ranges may also straddle text nodes belonging to different elements. In the following, the parts of succeeding lines are extracted from the SPEECH element.

&lt;xi:include href="/db/apps/demo/data" xpointer="xpointer( substring(string-join( //PLAY/ACT\[3\]/SCENE\[1\]/SPEECH\[19\] ,''), 202, 24) )"/&gt;
For this XInclude example to work, you need to install the Demo application. See the Package Reposistory in the Admin panel.
## Including the Results of a Stored XQuery

Another powerful feature is to include the result of a stored XQuery. If the target of an XInclude reference points to an XQuery resource stored in the database (i.e. a binary resource with mime-type "application/xquery"), the XInclude processor will attempt to compile and execute this query. The root element included will be the root element returned by the XQuery script. For example:

&lt;xi:include href="display-collection.xq"/&gt;
Calls a query without parameters. The result is shown below:

For this XInclude example to work, you need to install the Documentation app. See the Package Reposistory in the Admin panel.
The XInclude processor declares two variables in the XQuery's static context:

$xinclude:current-doc  
the name of the document which xincludes the query (without the collection path)

$xinclude:current-collection  
the collection in which the current document resides

The example above calls these functions.

However, we can also pass explicit parameters to the XQuery:

&lt;xi:include href="testvars.xq?var1=Hello&var2=World"/&gt;
The parameters `var1` and `var2` will be available to the XQuery as an external global variable. However, the XQuery needs to declare them or an error will be thrown:

declare variable $var1 external; declare variable $var2 external;
The result of the call is included below:

For this XInclude example to work, you need to install the Demo application. See the Package Reposistory in the Admin panel.
## Including resources from external URIs or the file system

If the URI in the href attribute specifies a known scheme (like http: or file:), eXist-db will try to load it as an external resource. For example:

&lt;xi:include href="http://localhost:8080/exist/rest/db/apps/doc/data/disclaimer-short.xml"/&gt;
Should load "disclaimer-short.xml" via HTTP (assuming that the URL is correct and you are using the default eXist-db setup):

Included url not found! Example assumes eXist-db is running at http://localhost:8080/exist/
If no scheme is specified, the XInclude processor will first try to load the referenced document from the database (relative to the current collection), and if that fails, from the file system.

If the document that contains the XInclude has been constructed in an XQuery, relative file system paths will be resolved relative to the main XQuery module source file.

You can also use XPointers on external resources:

&lt;xi:include href="http://exist-db.org/exist/index.xml" xpointer="xpointer(//blockquote)"/&gt;
The output of this is shown below:

Lookup failed! Are you sure you have an internet connection? Or is the server down?
