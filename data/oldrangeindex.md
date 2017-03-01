# Legacy Range index

## Note

> **Note**
>
> This index has been replaced by a redesigned range index module in eXist 2.2. The old index is still available and fully functional though.

Range indexes provide a shortcut for the database to directly select nodes based on their typed values. They are used when matching or comparing nodes by way of standard XPath operators and functions. Without a range index, comparison operators like =, &gt; or &lt; will default to a "brute-force" inspection of the DOM, which can be extremly slow if eXist-db has to search through maybe millions of nodes: each node has to be loaded and cast to the target type.

To see how range indexes work, consider the following fragment:

                        <items>
        <item n="1">
           <name>Tall Bookcase</name>
           <price>299.99</price>
        </item>
        <item n="2">
           <name>Low Bookcase</name>
           <price>199.99</price>
        </item>
    </items>
                    

With this short inventory, the text nodes of the price elements have dollar values expressed as a floating-point number, (e.g. "299.99"), which has an [XML Schema Definition](http://www.w3.org/TR/xmlschema-0/) (XSD) data type of `xs:double`. Using this builtin type to define a range index, we can improve the efficiency of searches for price values. (Instructions on how to configure range indexes using configuration files are provided under the [Configuring Indexes](#idxconf) section below.) During indexing, eXist-db will apply this data type selection by attempting to cast all price values as double floating point numbers, and add appropriate values to the index. Values that cannot be cast as double floating point numbers are therefore ignored. This range index will then be used by any expression that compares price to an `xs:double` value - for instance:

//item\[price &gt; 100.0\]
For non-string data types, the range index provides the query engine with a more efficient method of data conversion. Instead of retrieving the value of each selected element and casting it as a `xs:double` type, the engine can evaluate the expression by using the range index as a form of lookup index. Without an index, eXist-db has to do a full scan over all price price elements, retrieve the string values of their text node and cast them to a double number. This is a time-consuming process which also scales very badly with growing data sets. With a proper index, eXist-db needs just a single index lookup to evaluate `price = 100.0`. The range expression `price > 100.0` is processed with an index scan starting at 100.

For string data, the index will also be used by the standard functions `fn:contains()`, `fn:starts-with()`, `fn:ends-with()` and `fn:matches()`.

To illustrate this functionality, let's return to the previous example. If you define a range index of type `xs:string` for element name, a query on this element to select tall bookcases using `fn:matches()` will be supported by the following index:

//item\[fn:matches(name, '\[Tt\]all\\s\[Bb\]')\]
Note that `fn:matches` will by default try to match the regular expression *anywhere* in the string. We can thus speed up the query dramatically by using "^" to restrict the match to the start of the string:

//item\[fn:matches(name, '^\[Tt\]all\\s\[Bb\]')\]
Also, if you really need to search for an exact substring in a longer text sequence, it is often better to use the NGram index instead of the range index, i.e. use `ngram:contains()` instead of `fn:contains()`. Unfortunately, there's no equivalent NGram function for `fn:matches()` yet, but we may add one in the future as it could help to increase performance dramatically.

In general, three conditions must be met in order to optimize a search using a range index:

1.  *The range index must be defined on *all* items in the input sequence.*

    For example, suppose you have two collections in the database: C1 and C2. If you have a range index defined for collection C1, but your query happens to operate on both C1 and C2, then the range index would *not* be used. The query optimizer selects an optimization strategy based on the entire input sequence of the query. Since, in this example, since only nodes in C1 have a range index, no range index optimization would be applied.

2.  *The index data type (first argument type) must match the test data type (second argument type).*

    In other words, with range indexes, there is no promotion of data types (i.e. no data type precedes or replaces another data type). For example, if you defined an index of type `xs:double` on price, a query that compares this element's value with a string literal would not use a range index, for instance:

    //item\[price = '1000.0'\]
    In order to apply the range index, you would need to cast the value as a type `xs:double`, i.e.:

    //item\[price = xs:double($price)\] (where $price is any test value)
    Similarly, when we compare `xs:double` values with `xs:integer` values, as in, for instance:

    //item\[price = 1000\]
    the range index would again not be used since the price data type differs from the test value type, although this conflict might not seem as obvious as it is with string values.

3.  *The right-hand argument has no dependencies on the current context item.*

    That is, the test or conditional value must not depend on the value against which it is being tested. For example, range indexes will not be applied given the following expression:

    //item\[price = self\]

Concerning range indexes on strings there's another restriction to be considered: up to version 1.3, range indexes on strings can only be used with the default Unicode collation. Also, string indexes will always be case sensitive (while n-gram and full text indexes are not). It is not yet possible to define a string index on a different collation (e.g. for German or French) or to make it case insensitve. This is a limitation we plan to address in the future.

## Range index configuration

                        <!-- Range indexes -->
    <create qname="title" type="xs:string"/>
    <create qname="author" type="xs:string"/>
    <create qname="year" type="xs:integer"/>
    <!-- "old" context-dependant configuration using the path attribute: -->
    <create path="//booktitle" type="xs:string"/>
                    

A range index is configured by adding a create element directly below the root index element. As explained above, the node to be indexed is either specified through a `path` or a `qname` attribute.

> **Note**
>
> Unlike the new range index, the create elements of the old range index are NOT wrapped inside a range tag.

As range indexes are type specific, the `type` attribute is always required. The type should be one of the atomic XML schema types, currently including `xs:string`, `xs:integer` and its derived types `xs:double` and `xs:float`, `xs:boolean` and `xs:dateTime`. Further types may be added in the future. If the name of the type is unknown, the index configuration will be ignored and you will get a warning written into the logs.

Please note that the index configuration will only apply to the node specified via the `path` or `qname` attribute, not to descendants of that node. Consider a mixed content element like:

                        <mixed><s>un</s><s>even</s></mixed>
                    

If an index is defined on mixed, the key for the index is built from the concatenated text nodes of element mixed and all its descendants, i.e. "uneven". The created index will only be used to evaluate queries on mixed, but not for queries on s. However, you can create an additional index on s without getting into conflict with the existing index on mixed.

## Configuration by path vs. configuration by qname

It is important to note the difference between the `path` and `qname` attributes used throughout above example. Both attributes are used to define the elements or attributes to which the index should be applied. However, the `path` attribute creates *context-dependant* indexes, while the `qname` attribute does not. The path attribute takes a simple path expression:

&lt;create path="//book/title" type="xs:string"/&gt;
The path expression looks like XPath, but it's really not. Index path syntax uses the following components to construct paths:

-   Elements are specified by their *qname*

-   Attributes are specified by `@attributeName`, so if the attribute is called "attrib1", one uses `@attrib1` in the index specification.

-   Child nodes are selected using the forward-slash (`/`)

-   All descendant nodes in a tree are selected using the double forward-slash (`//`)

The example above creates a range index of type string on all title elements which are children of book elements, which may occur at an arbitrary position in the document tree. All other title elements, e.g. those being children of section nodes, are not indexed. The path expression thus defines a *selective* index, which is also *context-dependant*: we always need look at the context of each title node before we can determine if this particular title is to be indexed or not.

This kind of context-dependant index definition helps to keep the index small, but unfortunately it makes it hard for the query optimizer to properly rewrite the expression tree without missing some nodes. The optimizer needs to make an optimization decision at compile time, where the context of an expression is unknown or at least not exactly known (read the [blog article](http://atomic.exist-db.org/blogs/eXist/NewIndexing) to get the whole picture). This means that some of the highly efficient optimization techniques can not be applied to context-dependant indexes!

We thus had to introduce an alternative configuration method which is not context-dependant. To keep things simple, we decided to define the index on the *qname* of the element or attribute alone and to ignore the context altogether:

&lt;create qname="title" type="xs:string"/&gt;
This results in an index being created on every title element found in the document node tree. Section titles will be indexed as well as chapter or book titles. Indexes on attributes are defined as above by prepending "@" to the attribute's name, e.g.:

&lt;create qname="@type" type="xs:string"/&gt;
defines an index on all attributes named "type", but not on elements with the same name.

Defining indexes on qnames may result in a considerably larger index, but it also allows the query engine to apply all available optimization techniques, which can improve query times by an order of magnitude. As so often, there's a trade-off between performance and storage space. In many cases, the performance win can be dramatic enough to justify an increase in index size.

> **Important**
>
> To be on the safe side and to benefit from current and future improvements in the query engine, you should prefer `qname` over `path` - unless you really need to exclude certain nodes from indexing.
