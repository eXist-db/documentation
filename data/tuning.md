# Tuning the Database

## Overview

This article describes strategies for improving the performance of eXist-db and optimizing its efficiency. It covers the a range of areas that can constrain performance, from memory and cache settings to the way a query is constructed. Many users of eXist-db have little reason to read this document until they encounter a query or operation that is performing poorly. However, whether you have reached that point or you are just curious about learning strategies for keeping your database and queries performing at peak efficiency, this is an essential document.

## Memory settings

Java always limits the maximum amount of memory available to a process. eXist-db will thus not automatically use all of the memory available on your machine. The default setting is 1024MB.

The maximum amount of memory Java will allocate is determined by the `-Xmx` parameter passed to Java on the command line. When eXist-db is started via the graphical launcher, parameters will be read from the file `vm.properties`.

    # This file contains a list of VM parameters to be passed to Java
    # when eXist is started by double clicking on start.jar (or calling
    # "java -jar start.jar" without parameters on the shell).

    # Minimum and maximum memory
    vmoptions=-Xms64m -Xmx4098m -Dexist.autodeploy=on

    # Mac specific properties
    vmoptions.mac=-Xdock:name="eXist-db" -Xdock:icon="icon.png" -Dapple.laf.useScreenMenuBar="true"

If you launch eXist via one of the shell or batch scripts, you need to change `-Xmx` in there.

On a *Unix* system, edit `EXIST_HOME/bin/functions.d/eXist-settings.sh`. Search for the `JAVA_OPTIONS` variable, which sets `-Xmx` for the server. The `CLIENT_JAVA_OPTIONS` variable does the same for the Java admin client. Instead of directly editing `eXist-settings.sh`, you may also override those variables globally in your own shell.

On *Windows*, the `-Xmx` settings is done in the main .bat files, .e.g. `EXIST_HOME\bin\startup.bat`.

If you launch *eXist-db as a service*, all Java settings will be controlled by the service wrapper. In this case, the file to edit is `EXIST_HOME/tools/yajsw/conf/wrapper.conf`. The installer sets the memory you chose at install time (NNNN), but if you want to change it afterwards search for one of the following lines:

\# Maximum Java Heap Size (in MB) \# alternative for wrapper.java.additional.&lt;n&gt;=-Xmx wrapper.java.maxmemory=NNNN
## Cache settings

Each of the core database files and indexes has a page cache. The main purpose of this cache is to make sure that the most frequently used pages of the db files are kept in memory. If a file's cache becomes too small, eXist may start to unload pages just to reload them a few moment later. This "trashing effect" results in an immediate performance drop, in particular while indexing documents.

All caches share a single memory pool, whose size is determined by the attribute `cacheSize` in the db-connection section of `conf.xml`. The global cache manager will dynamically grant more memory to caches while they are under load and free the memory used by idle caches.

``` xml
<db-connection cacheSize="48M" collectionCache="24M" database="native"
        files="webapp/WEB-INF/data" pageSize="4096" nodesBuffer="-1">
```

The default setting for `cacheSize` is very conservative (48M). It will be OK for smaller databases, but you may soon experience a performance drop when indexing more than several 100M of XML data. Consider increasing `cacheSize` up to approx. 1/3 of the main memory available to Java (determined by the `-Xmx` parameter passed to the Java command line). If you are running eXist-db with other web applications in the same servlet engine, you may need to choose a smaller setting (running out of memory will crash the database, so please be careful).

The `cacheSize` is mainly relevant when storing/updating data. The effect on query speed should not be that big, unless some of the index caches are really much too small.

If you continue to experience performance issues while storing data, you may need to revisit your index configuration. Removing unused indexes will give more room to the other indexes. In particular, the full text index can grow very fast until it becomes a bottleneck. Try to disable the default full text index (see below).

The `nodesBuffer` attribute can be used to set eXist-db's temporary internal buffer to a fixed size. The buffer is used during indexing to cache nodes before they are flushed to disk. The default setting (nodesBuffer="-1") is to use as much memory as is available, but this can be problematic if you have to store large documents in a multi-user environment. For a production server, a good recommendation would be to set nodesBuffer to 1000 or less if there are many concurrent write operations.

## Index configuration

### Don't rely on the default behaviour

eXist-db does *NOT* index any element or attribute values by default. It may create a full text index (see below), but this won't help with standard comparison operators or functions. Thus, when evaluating an expression like

//SPEECH\[SPEAKER = "HAMLET"\]
the query engine will fall back to a full scan over all SPEAKER elements in the db. This is very slow and limits concurrency. You should at least create a global index definition (in `/db/system/config/db/collection.xconf`) and add range indexes for the most frequently used comparisons.

### Disable any default indexes (pre 1.4)

If no other index [index configuration](indexing.md) is found for a database collection, eXist-db will use the default settings specified in `conf.xml`. For older eXist-db versions, the default is to create a full text index on *ALL* elements and attributes in the database. The problem with this is that

1.  maintaining the default index costs performance and memory, which could be better used for other indexes. The index may grow very fast, which can be a destabilizing factor.

2.  the index is unspecific. The query engine cannot use it as efficiently as a dedicated index on a set of named elements or attributes ([see below](#idxdefs)).

If you experience memory issues or observe a constantly decreasing performance while loading documents, tuning your indexes should be one of the first steps:

-   disable the default full text index in your index [definitions](indexing.xml#N10422):

    ``` xquery
    <collection xmlns="http://exist-db.org/collection-config/1.0">
        <index>
            <fulltext default="none" attributes="false">
            </fulltext>
        </index>
        ...
    </collection>
    ```

-   recreate full text or other indexes only on those elements and attributes you want to query. Prefer index definitions by qname over a configuration by path.

-   if you are using eXist-db 1.4 or above, consider *switching to the new [Lucene-based index](lucene.md)*. It provides better performance and stability.

### Prefer simple index definitions

Keeping your [index definitions](indexing.xml#N10422) simple makes it easier for the query optimizer to resolve dependencies. In particular, avoid context-dependant index definitions unless you really have a reason to use them. A context-dependant index is defined on a path like `/book/chapter/title`, while general indexes are defined on a simple element or attribute qname:

``` xquery
<collection xmlns="http://exist-db.org/collection-config/1.0">
    <index>
        <!-- Range indexes by qname -->
        <create qname="title" type="xs:string"/>
        <create qname="@ID" type="xs:string"/>

        <!-- context-dependant configuration using the path attribute: -->
        <create path="/book/title" type="xs:string"/>
    </index>
</collection>
```

Defining indexes on qnames may result in a larger index, but it also allows the query engine to apply all available optimization techniques, which can improve query times by an order of magnitude. Replacing a context-dependant index by a simple index on qname can thus result in a performance boost, thanks to eXist-db's new [query-rewriting optimizer](http://atomic.exist-db.org/blogs/eXist/NewIndexing). Older versions of eXist-db did not offer those possibilities.

### Use range indexes on strongly typed data or short strings

Range indexes work with the standard XQuery operators and string functions. Querying for something like

//book\[year = 2000\]
will always be slow without an index. As long as no index is defined, eXist-db has to scan over every year element in the db, casting its string value to an integer.

For queries on string content, range indexes work well for exact comparisons (`author = 'Joe Doe'`) or regular expressions (`matches(author, "^Joe.*")`), though you may also consider using a full text index in the latter case. However, please note that range indexes on strings are *case-sensitive* or rather, to use the correct formulation, sensitive to the default [collation](http://en.wikipedia.org/wiki/Collation). If you need case-insensitive queries, consider an ngram index.

### Consider an n-gram index for exact substring queries on longer text sequences

While range indexes tend to become slow for substring queries (like `contains(title, "XSLT 2.0")`), an n-gram index is nearly as fast as a full text index, but it also indexes whitespace and punctuation. `ngram:contains(title, "XSLT 2.0")` will only match titles containing the exact phrase "XSLT 2.0". n-gram indexes are *case insensitive*.

### Choose a full text index for tokenizable text where whitespace/punctuation is mostly irrelevant

The full text index is fast and should be used whenever you need to query for a sequence of separate words or tokens in a longer text. It can sometimes even be faster to post-process the returned node set and filter out wrong matches than using a much slower regular expression.

From version 1.4, eXist-db offers a [full text index](lucene.md) which is based on Apache Lucene. It provides better performance and overall stability than the built-in index.

## Writing Queries

### Prefer short paths

eXist-db uses indexes to directly locate an element or attribute by its name. It doesn't need to [traverse](http://en.wikipedia.org/wiki/Tree_traversal) the entire document tree. This means that the direct selection of a node through a single descendant step is *faster* than walking down the child axis. For example:

a/b/c/d/e/f
will be *slower* than

a//f
The first expression requires 6 (!) index lookups while the second just needs two. The same rules apply to the ancestor axis, e.g. f/ancestor::a.

### Always process the most selective filter/expression first

If you need multiple steps to select certain nodes from a larger node set, try to process the most selective steps first. The earlier you can reduce the node set to be processed, the faster your query will run. For example, assume we have to find publications written by "Bjarne Stroustrup" after the year 2000:

/dblp/\*\[year &gt; 2000\]\[author = 'Bjarne Stroustrup'\]
The database has 568824 records matching `year > 2000`, but only 41 of them were written by Stroustrup. Moving the filter on the author to the front of the expression should thus result in better performance:

/dblp/\*\[author = 'Bjarne Stroustrup'\]\[year &gt; 2000\]
It would certainly be nice if eXist-db could do this kind of optimization automatically. We are working on it. eXist-db recognizes more and more cases for intelligent query rewritings. For example, it already transforms the boolean expression

/dblp/\*\[author = 'Bjarne Stroustrup' and year &gt; 2000\]
into a multi filter step as shown above.

### Avoid unnecessary nested filters

Nesting filters in an XPath expression is often required and eXist-db will process them correctly. However, unnecessary nesting should be avoided and has a negative impact on the query optimizer. For example:

//A\[B\[C = "D"\]\]
could also be written as

//A\[B/C = "D"\]
without changing the result. The variant with only one filter is easier to optimize for eXist-db, whereas the nested filter implies a performance penalty.

Likewise, if you are calling one of the optimized functions (contains, matches, ft:query ...), make sure you do not nest them unless really required:

//A\[B/C\[contains(., "D")\]\]
can be rewritten to

//A\[contains(B/C, "D")\]
### Allow eXist-db to process large node sets in one step

The query engine is optimized to process a path expression in one, single operation. For instance, the XPath:

//A/\*\[B = 'C'\]
is evaluated in a single operation for all context items. It doesn't make a difference if the input set comes from a single large document, includes all the documents in a specific collection or even the entire database. The logic of the operation remains the same.

However, "bad" queries can force the query engine to partition the input sequence and process it in an item-by-item mode. Several examples for bad uses of FLWOR expressions will be given below. They should be easy to understand, but other cases are not so obvious. For example, most function calls will also force the query engine into item-by-item mode:

//A/\*\[f:process(B) = 'C'\]
The function has to be called once for every instance of B. Normally, eXist-db would try to evaluate the general comparison in a single step (assuming there's a usable index on B). However, it now needs to call a (non-optimized) function for each B and will thus need to process the entire comparison once for every context item.

There are functions to which the above does not apply. This includes most functions which operate on indexes, e.g. `contains`, `matches`, `starts-with`, `ngram:contains`, and the like. They are optimized so eXist-db only needs to call them once to process the entire context set. For example, using `ngram:contains` as below is perfectly OK:

//A/\*\[ngram:contains(B, 'C')\]
while

//A/\*\[ngram:contains(f:process(B), 'C')\]
will again force eXist-db into step-by-step evaluation.

### Prefer XPath predicates over where expressions

This is a variation of the problems discussed above. Many users tend to formulate SQL-style queries using an explicit "where" clause:

``` xquery
for $e in //entry 
where $e/@type = 'subject'
return $e
```

This could be rewritten as:

``` xquery
for $e in //entry[@type = 'subject'] 
return $e
```

The "for … where" expression forces the query engine into a step-by-step iteration over the input sequence, testing each instance of $e against the where expression. Possible optimizations are lost.

Contrary to this, the XPath predicate expression can be processed in one single step, making best use of any available indexes. Sure, there are use cases which cannot be handled without using "where", e.g. joins between multiple documents, but you shouldn't use "where" if you can replace it by a simple XPath.

Internally, the query engine will always try to process a "where" clause like an equivalent XPath with predicate. However, it only detects the simple cases.

### Use general comparisons to compare an item to a list of alternatives

General comparisons are very handy if you need to compare a given item to several alternative values. For example, you could use an "or" to find all b children whose string value is either "c" or "d".

//a\[b eq 'c' or b eq 'd'\]
A shorter way to express this is:

//a\[b = ('c', 'd')\]
The comparison will be true if b's string value matches one of the strings in the right hand sequence. If an index is defined on b, eXist-db will need only one index lookup to find all b's matching the comparison. The equivalent "or" expression needs two separate index lookups.

### Use "group by"

The XQuery 3.0 group by feature is much more efficient than using e.g. distinct-values. For example, to order the results of a query by the value of the child element SPEAKER, you may have used:

``` xquery
xquery version "3.0";

let $query := "king"
let $speeches := //SPEECH[ft:query(., $query)]
for $speaker in distinct-values($speeches/SPEAKER)
let $speechBySpeaker := $speeches[SPEAKER = $speaker]
order by $speaker
return
    <speaker name="{$speaker}">
    { $speechBySpeaker }
    </speaker>
```

The XQuery 3.0 variant with group by is much more efficient:

``` xquery
let $query := "king"
for $speechBySpeaker in //SPEECH[ft:query(., $query)]
group by $speaker := $speechBySpeaker/SPEAKER
order by $speaker
return
    <speaker name="{$speaker}">
    { $speechBySpeaker }
    </speaker>
```

### Querying multiple collections

If you need to query multiple collections which are on the same level of the collection hierarchy, you could use a for loop to iterate over the collection paths. However, this forces the query engine to process the remaining expression once for each collection. It is thus better to construct the initial node set once and use it as input for the main expression. For example:

``` xquery
for $path in ('/db/a', '/db/b')
for $result in collection($path)//test[...]
return
    ...
```

will be less efficient than:

``` xquery
let $docs :=
    for $path in ('/db/a', '/db/b') return $collection($path)
for $result in $docs//test[...]
return
    ...
```

### Use the ancestor or parent axis instead of a top-down approach

eXist-db can navigate the ancestor axis as fast as the descendant axis. It can thus be more efficient to build a query bottom-up instead of top-down. Here's a top-down example:

``` xquery
for $section in collection("/db/articles")//section
for $match in $section//p[contains(., "XML")]
return
    <match>
        <section>{$section/title/text()}</section>
        {$match}
    </match>
```

This query walks through a set of sections and queries each of them for paragraphs containing the string "XML". It then outputs the title of the section, followed by the matching paragraphs. Note that it will also return the title of all sections which do not have any matches.

The nested for loop again forces the query engine into a step-by-step iteration over the section elements. We can avoid this by using a bottom-up approach:

``` xquery
for $match in collection("/db/articles")//section//p[contains(., "XML")]
return
    <match>
        <section>{$match/ancestor::title/text()}</section>
        {$match}
    </match>
```

The second query should be several times faster than the first one.

### Match regular expressions against the start of a string

Function fn:matches returns true if any substring of its argument string matches the regular expression. The query engine thus needs to scan all index entries as the match could be at any position of an entry.

You can reduce the range of entries to be scanned by anchoring your pattern at the start of a string (where applicable):

fn:matches($str, "^XQuery")
### Use fn:id to lookup xml:id attributes

eXist-db automatically indexes all xml:id attributes and other attributes with type ID as declared in a DTD (only if validation is enabled). This automatic index is used by the standard id functions and provides a fast way to look up an element. For example,

id("sect1")/head
locates the element with id "sect1" and returns its head child. This is done through a fast index lookup. However, please note that the equivalent expression

//section\[@xml:id = 'sect1'\]/head
will *NOT* use the id index (you will need to declare an extra range index for that).

Please be also aware that larger xml:id values cost performance as has been reported by some users working with large databases.

### Defer output generation until really needed

When working with large result sets within a query, it is important to understand the *differences between stored nodes and in-memory XML*: if a node set consists of nodes which are stored in the database, eXist-db will usually never load those nodes into memory. Instead, it uses lightweight references for most processing steps. This way, even large node sets do not consume too much memory.

However, all new XML nodes created within an XQuery will reside in memory and you should be aware that the constructed XML fragments need to fit into the memory available to the Java VM. If a query generates too many nodes, the XQuery watchdog (if enabled) may step in and kill it.

A typical scenario: a query selects a large number of documents from the database and then iterates through each to generate some HTML output for display. However, only the first 10 results are really returned to the user, the rest is stored into an HTTP session for later viewing.

In this case it is important to limit the HTML generation to those items which are actually returned. Though the source XML documents may be large, eXist-db will not load them into memory, but just keep references to them. Storing those references into a session does not consume much memory.

``` xquery
let $nodes := (: select some nodes in the db :)
let $session := session:set-attribute("result", $nodes) (: store result into session :)
(: only return the first 10 nodes :)
for $node in subsequence($nodes, 1, 10)
return
    (: Generate HTML for output :)
    <div>(: Create complex HTML markup using $node :)</div>
```

Please note also that eXist-db uses *lazy evaluation* when constructing new XML fragments. For example:

&lt;book&gt;{$node/title}&lt;/book&gt;
Assuming that $node references a node in the database, the query engine will not copy $node/title into the constructed book element. Instead, only a reference is inserted. The reference will not be expanded until the fragment is serialized or queried. So if you only need to wrap selected parts of an element into a new fragment, memory consumption will not be too high.
