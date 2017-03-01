# New Range Index (since eXist 2.2)

## Overview

eXist version 2.2 and above includes a rewritten, modularized range index. Under the hood it is based on Apache Lucene for super fast lookups. It also provides new optimizations to speed up some types of queries which failed to run efficiently with the old index.

Range indexes are extremely important in eXist-db. Without a proper index, evaluating a general comparison in a filter (like `//foo[baz = "xyz"]`) requires eXist to do a full scan over the context node set, checking the value of every node against the argument. This is not only slow, it also limits concurrency due to necessary locking and consumes memory for loading each of the nodes. With a well-defined index, queries will usually complete in a few milliseconds instead of taking seconds. The index allows the optimizer to rewrite the expression and process the index lookup in advance, assuming that the number of baz elements with content "xyz" is much smaller than the total number of elements.

The old range indexing code had three main issues though:

1.  Index entries were organized by collection, resulting in an unfortunate dependency between collection size and update speed. In simple words: updating or removing documents became slower as the collection grew. For a long time, the general recommendation was to split large document sets into multiple, smaller sub-collections if update speed was an issue.

2.  Queries on very frequent search strings were quite inefficient: for example, a query //term\[@type ="main"\]\[. = "xyz"\] could be quite slow despite an index being defined if @type="main" occurred very often. Unfortunately this is a common use of attributes and to make it quick, you had to reformulate the query, e.g. by moving the non-selective step to the back: //term\[. = "xyz"\]\[@type = "main"\]

3.  Range indexes were baked into the core of eXist-db, making maintenance and bug fixing difficult.

The rewritten range index addresses both issues. First, indexes are now organized by document/node, so collection size does no longer matter when updating an index entry. Concerning storage, the index is entirely based on Apache Lucene instead of the B+-tree which was previously used. Most range indexes tend to be strings, so why not leave the indexing to a technology like Lucene, which is known to scale well and does a highly efficient job on string processing? Since version 4, Lucene has added support for storing numeric data types and binary data into the index, so it seemed to be a perfect match for our requirements. Lucene is integrated into eXist on a rather low level with direct access to the indexes.

To address the second issue, it is now possible to combine several fields to index into one index definition, so above XPath:

//term\[@type = "main"\] \[. = "xyz"\]
can be evaluated with a single index lookup. We'll see in a minute how to define such an index.

Finally, the new range index is implemented as a pluggable module: a separate component which is not required for the core of eXist-db to work properly. For eXist, the index is a black box: it does not need to know what the index does. If the index is there, it will automatically plug itself into the indexing pipeline as well as the query engine. If it is not, eXist will fall back to default (brute force) query processing.

## Index Configuration

We tried to keep the basic index configuration as much backwards compatible as possible. The old range index is still supported to allow existing applications to run unchanged.

``` xml
<collection xmlns="http://exist-db.org/collection-config/1.0">
    <!--from Tamboti-->
    <index xmlns:mods="http://www.loc.gov/mods/v3">
        <lucene>
            <text qname="mods:title"/>
        </lucene>
        <!-- Range indexes -->
        <create qname="mods:namePart" type="xs:string"/>
        <create qname="mods:dateIssued" type="xs:string"/>
        <create qname="@ID" type="xs:string"/>
    </index>
</collection>
```

To use the new range index, wrap the range index definitions into a range element:

``` xml
<collection xmlns="http://exist-db.org/collection-config/1.0">
    <!--from Tamboti-->
    <index xmlns:mods="http://www.loc.gov/mods/v3">
        <lucene>
            <text qname="mods:title"/>
        </lucene>
        <!-- Range indexes -->
        <range>
            <create qname="mods:namePart" type="xs:string" case="no"/>
            <create qname="mods:dateIssued" type="xs:string"/>
            <create qname="@ID" type="xs:string"/>
        </range>
    </index>
</collection>
```

If you store this definition and do a reindex, you should find new index files in the `webapp/WEB-INF/data/range directory` (or wherever you configured your data directory to be).

Just as the old range index, the new indexes will be used automatically for general or value comparisons as well as string functions like `fn:contains`, `fn:starts-with`, `fn:ends-with`.

> **Note**
>
> `fn:matches` is currently not supported due to limitations in Lucene's regular expression handling. If you require fn:matches a lot, consider using the old range index.

Above configuration applies to documents using MODS, a standard for bibliographical metadata. To provide some examples, the following XPath expressions should use the created indexes:

``` xquery
declare namespace mods="http://www.loc.gov/mods/v3";
//mods:mods[mods:name/mods:namePart = "Dennis Ritchie"],
//mods:mods[mods:originInfo/mods:dateIssued = "1978"],
//mods:mods[mods:name/mods:namePart = "Dennis Ritchie"]
    [mods:originInfo/mods:dateIssued = "1978"]
```

## New Configuration Features

### Case sensitive index

Add `case="no"` to create a case insensitive index on a string. This is a feature many users have asked for. With a case insensitive index on `mods:namePart` a match will also be found if you query for "dennis ritchie" instead of "Dennis Ritchie".

### Collations

A collation changes how strings are compared. For example, you can change the strength property of the collation to ignore diacritics, accents or case. So to compare strings ignoring accents or case, you can define an index as follows:

``` xml
<create qname="mods:namePart" 
        type="xs:string" 
        collation="?lang=en-US&amp;strength=primary"/>
```

Please refer to the [ICU documentation](http://userguide.icu-project.org/collation/concepts) (which is used by eXist) for more information on collations, strength etc.

### Combined indexes

If you know you will often use a certain combination of filters, you can combine the corresponding indexes into one to further reduce query times. For example, the mods:name element has an attribute type which qualifies the name as being "personal", "corporate" or another predefined value. To speed up a query like

//mods:mods\[mods:name\[@type = "personal"\] \[mods:namePart = "Dennis Ritchie"\]
you could create a combined index on mods:name as follows:

``` xml
<range>
    <create qname="mods:name">
        <field name="name-type" match="@type" type="xs:string"/>
        <field name="name-part" match="mods:namePart" type="xs:string"/>
    </create>
</range>
```

This index will be used whenever the context of the filter expression is a mods:name and it filters on either or both: @type and mods:namePart. Advantage: only one index lookup is required to evaluate such an expression, resulting in a huge performance boost, in particular if the combination of filters does only match a few names out of a large set!

Note that all 3 attributes of the field element are required. The name you give to the field can be arbitrary, but it should be unique within the index configuration document. The match attribute specifies the nodes to include in the field. It should be a simple path relative to the context element.

You can skip the match attribute if you want to index the content of the context node itself. In this case, an additional attribute: `nested="yes|no"` can be added to tell the indexer to skip the content of nested nodes to only index direct text children of the context node.

The index is also used if you only query one of the defined fields, e.g.: //mods:mods\[mods:name\[mods:namePart = "Dennis Ritchie"\]\]. It is important that the filter expression matches the index definition though, so the following will not be sped up by the index: //mods:mods\[mods:name/mods:namePart = "Dennis Ritchie"\] because the context of the filter expression here is mods:mods, not mods:name.

You can create as many combined indexes as you like, even if some of them refer to elements which are nested inside other elements having a different index. For example, to index a complete MODS record, we could create one nested index on the root element: mods:mods, and include all attributes or simple descendant elements we may want to query at the same time. mods:name - even though a child of mods:mods - is a complex element, so we want it to have a separate index as shown above. We thus define both indexes:

``` xml
<range>
    <create qname="mods:name">
        <field name="name-type" match="@type" type="xs:string"/>
        <field name="name-part" match="mods:namePart" type="xs:string"/>
    </create>
    <create qname="mods:mods">
        <field name="mods-dateIssued" match="mods:originInfo/mods:dateIssued" type="xs:string"/>
        <field name="mods-id" match="@ID" type="xs:string"/>
        <field name="mods-authority" match="@authority" type="xs:string"/>
        <field name="mods-lang" match="@lang" type="xs:string"/>
    </create>
</range>
```

This allows a more complex query to be optimized:

``` xquery
//mods:mods[mods:name[@type = "personal"]
           [mods:namePart = "Dennis Ritchie"]] 
           [mods:originInfo/mods:dateIssued = "1979"]
```

In this case, the mods:dateIssued lookup will be done first, which presumably returns more hits than the name lookup. For maximum performance it may thus still be faster to split the expression into two parts and do the name check first.
### Conditional combined indexes

For combined indexes, you can specify conditions to restrict the values being indexed to those contained in elements that have an attribute meeting certain criteria:

``` xml
<range>
    <create qname="tei:term">
        <condition attribute="type" value="main"/>
        <field name="mainTerm" type="xs:string/>
    </create>
</range>
```

This will only index the value of the `tei:term` element if it has an attribute named `type` with the value `"main"`. Multiple conditions can be specified in an index definition, in which case all conditions need to match in order for the value to be indexed.

In order to take advantage of query optimization for conditionally indexed fields, queries should be formulated like this://tei:term\[@type = "main"\]\[. = "xyz"\]

which then gets rewritten to a call to range:field(("mainTerm"), "eq", "xyz")

## Using Index Functions

Internally the query optimizer will rewrite range lookup expressions into optimized function calls into the `range` module (namespace `http://exist-db.org/xquery/range`). This happens transparently and you'll never see the function calls. However, for debugging and testing it is sometimes useful to be able to use the corresponding functions directly. There are two sets of functions: one for simple range index lookups, and one for indexes on fields.

Given the following index configuration:

``` xml
<range>
    <create qname="SPEAKER" type="xs:string"/>
    <create qname="SPEECH">
        <field name="stagedir" type="xs:string" match="//STAGEDIR"/>
        <field name="line" type="xs:string" match="LINE" case="no"/>
    </create>
</range>
```

A query:

//SPEECH\[SPEAKER="HAMLET"\]
translates into:

//SPEECH\[range:eq(SPEAKER, "HAMLET")\]
If the index is defined on an element with fields, the entire sub-expression, i.e. the context path and all its filters, is rewritten into a single function call. For example, take:

collection("/db/apps/demo/data")//SPEECH\[.//STAGEDIR = "Aside"\]
is replaced with

collection("/db/apps/demo/data")/range:field-eq("stagedir", "Aside")
Because the index root is defined on SPEECH, the function will always return SPEECH elements.

If multiple filters are used and each of them has a corresponding field definition, they are combined into one call:

collection("/db/apps/demo/data")/range:field-eq(("stagedir", "line"), "Aside", "what do you read, my lord?")
Note that while the field names are specified in a sequence, we add one parameter for every value to look up. This way it is possible to specify more than one value for each parameter by passing in a sequence.

Because different operators might be used inside the filters, the query engine will actually rewrite the expression to the following:

collection("/db/apps/demo/data")/range:field(("stagedir", "line"), ("eq", "eq"), "Aside", "what do you read, my lord?")
This is not easy to read, but efficient, and users will normally not see this function call anyway. However, it sometimes helps to know what the optimizer is supposed to do and try it out explicitely.
