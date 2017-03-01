# Extracting Content from Binary Files

## Overview

eXist-db excels at querying, indexing, and manipulating XML files. The Content Extraction module extends eXist-db's XML abilities to binary files. The module contains functions for extracting the content of the binary files, and returning the content as XML. In this form, the content can then be queried, indexed, and manipulated. This module is built on the [Apache Tika](http://tika.apache.org/) library. Tika understands a large variety of formats, ranging from PDF documents to spreadsheets and image metadata.

## Enabling the Content Extraction Module

To enable the content extraction module, edit EXIST\_HOME/extensions/build.properties and set the include.feature.contentextraction property to true:

\# Binary Content and Metadata Extraction Module include.feature.contentextraction = true
Next, call build.sh/build.bat from eXist's top directory to build the module. You should see in the output how the various libraries from the Tika project are downloaded and installed.

## Usage

To import the module use an import statement as follows:

import module namespace content="http://exist-db.org/xquery/contentextraction" at "java:org.exist.contentextraction.xquery.ContentExtractionModule";
The module provides three functions:

content:get-metadata($binary as xs:base64Binary) as document-node() content:get-metadata-and-content($binary as xs:base64Binary) as document-node() content:stream-content($binary as xs:base64Binary, $paths as xs:string\*, $callback as function, $namespaces as element()?, $userData as item()\*) as empty()
The first two functions need little explanation: get-metadata just returns some metadata extracted from the resource, while get-metadata-and-content will also provide the text body of the resource—if there is any. The third function is a streaming variant of the other two and is used to process larger resources, whose content may not fit into memory.

All functions produce XHTML. The metadata will be contained in the HTML head, the contents go into the body. The structure of the body HTML varies depending on the media type of the binary file. For example, the HTML resulting from a PDF is a sequence of divs (one per page), but that of a word processing document is more often a sequence of paragraphs.

## Storage and Indexing Strategies

While you could decide to just store the HTML returned by the content extraction functions as an XML resource into the database, this may not be efficient for certain applications. For example, a document search applications may not need to retain the extracted HTML.

In such cases the ft:index() function from the full text indexing module can be useful. This function allows users to associate a full text index with any database resource, be it binary or XML. The index will be linked to the resource, meaning that the same permissions apply; if the resource is deleted, the index will be removed as well.

To create an index, call the index function with the following arguments:

1.  The path of the resource to which the index should be linked as a string.

2.  An XML fragment describing the fields you want to add and the text content to index.

For example, to associate an index with the document test.txt one may call index as follows: ft:index("/db/apps/demo/test.txt", &lt;doc&gt; &lt;field name="title" store="yes"&gt;Indexing&lt;/field&gt; &lt;field name="para" store="yes"&gt;This is the first paragraph.&lt;/field&gt; &lt;field name="para" store="yes"&gt;And a second paragraph.&lt;/field&gt; &lt;/doc&gt;)

This creates a lucene index document, indexes the content using the configured analyzers, and links it to the eXist document with the given path. You may link more than one Lucene document to the same eXist resource. The field elements map to Lucene fields. You can use as many fields as you want or add multiple fields with the same name. The store="yes" attribute tells the indexer to also store the text string, so you can retrieve it later. It is also possible to configure the analyzers used by Lucene for indexing a given feed as well as other options in the collection configuration. To query the created index, use the search function: ft:search("/db/apps/demo/test.txt", "para:paragraph and title:indexing") The first parameter is the path to the resource or collection to query, the second specifies a Lucene query string. Note how we prefix the query term by the name of the field. Executing this query returns: &lt;results&gt; &lt;search uri="/db/apps/demo/test.txt" score="6.3111067"&gt; &lt;field name="para"&gt;This is the first &lt;exist:match&gt;paragraph&lt;/exist:match&gt;.&lt;/field&gt; &lt;field name="para"&gt;And a second &lt;exist:match&gt;paragraph&lt;/exist:match&gt;.&lt;/field&gt; &lt;field name="title"&gt;&lt;exist:match&gt;Indexing&lt;/exist:match&gt;&lt;/field&gt; &lt;/search&gt; &lt;/results&gt;

Each matching resource is described by a search element. The score attribute expresses the relevance lucene computed for the resource (the higher the better). Within the search element, every field which contributed to the query result is returned, but only if store="yes" was defined for this field at indexing time (if not, the field content won't be available). Note how the matches in the text are enclosed in match elements, just as if you did a full text query on an XML document. This makes it easy to post-process the query result, for example to create a keywords in context display using eXist's standard KWIC module.

The document the index is linked to does not need to be a binary resource. One can also create additional indexes on xml documents. This is a useful feature, because it allows us to index and query information which is not directly contained in the XML itself. For example, one could add metadata fields and retrieve them later using get-field. Or we could use fields to pre-process and normalize information already present in the XML to speed up later access.
