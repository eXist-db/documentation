# Lucene-based Full Text Index

## Introduction

The 1.4 version of eXist-db introduced a new full text indexing module which replaced eXist-db's former built-in full text index. This new module is faster, more configurable and more feature-rich than eXist-db's old index. It will also be the basis for eXist-db's implementation of the W3C's full text extensions for XQuery.

The new full text module is based on [Apache Lucene](http://lucene.apache.org). It thus benefits from a stable, well-designed and widely-used framework. The module is tightly integrated with eXist-db's *modularized indexing architecture*: the index behaves like a plugin which adds itself to the db's index pipelines. Once configured, the index will be notified of all relevant events, like adding/removing a document, removing a collection or updating single nodes. No manual reindex is required to keep the index up-to-date. The module also implements common interfaces which are shared with other indexes, e.g. for highlighting matches. It is thus easy to switch between the Lucene index and e.g. the ngram index without rewriting too much XQuery code.

## Enabling the Lucene Module

The Lucene full text index is enabled by default since version 1.4 of eXist-db. However, in case it is not enabled in your installation, here's how to get it up and running:

Before building eXist-db, enable the Lucene full text index by enabling it according to the instructions in the documentation on [index modules](indexing.md#moduleconf).

Then *(re-)build eXist-db* using the provided `build.sh` or `build.bat`. The build process downloads the required Lucene jars automatically. If everything builds OK, you should find a jar `exist-lucene-module.jar` in the `lib/extensions` directory. Next, edit the main configuration file, `conf.xml` and un-comment the Lucene-related section:

                                <modules>
        <module id="lucene-index" class="org.exist.indexing.lucene.LuceneIndex" buffer="32"/>
        ...
    </modules>

                            

### Global configuration options

The index has a single configuration parameter which can be specified on the module element within the modules section:

buffer  
Defines the amount of memory (in megabytes) Lucene will use for buffering index entries before they are written to disk. See the [Lucene javadocs](http://lucene.apache.org/core/4_4_0/core/org/apache/lucene/index/IndexWriterConfig.html#setRAMBufferSizeMB(double)).

## Configuring the Index

Like other indexes, you create a Lucene index by configuring it in a `collection.xconf` document. If you have never done that before, read the corresponding [documentation](indexing.md#idxconf). An example `collection.xconf` is shown below:

                        <collection xmlns="http://exist-db.org/collection-config/1.0">
        <index xmlns:atom="http://www.w3.org/2005/Atom"
            xmlns:html="http://www.w3.org/1999/xhtml"
            xmlns:wiki="http://exist-db.org/xquery/wiki">
            <!-- Disable the old full text index -->
            <fulltext default="none" attributes="false"/>
        <!-- Lucene index is configured below -->
            <lucene>
                <analyzer class="org.apache.lucene.analysis.standard.StandardAnalyzer"/>
                <analyzer id="ws" class="org.apache.lucene.analysis.WhitespaceAnalyzer"/>
                <text qname="TITLE" analyzer="ws"/>
                <text qname="p">
                    <inline qname="em"/>
                </text>
                <text match="//foo/*"/>
                <!-- "inline" and "ignore" can be specified globally or per-index as
                     shown above -->
                <inline qname="b"/>
                <ignore qname="note"/>
            </lucene>
        </index>
    </collection>
                
                    

                        <collection xmlns="http://exist-db.org/collection-config/1.0">
        <index xmlns:atom="http://www.w3.org/2005/Atom"
            xmlns:html="http://www.w3.org/1999/xhtml"
            xmlns:wiki="http://exist-db.org/xquery/wiki">
            <!-- Disable the old full text index -->
            <fulltext default="none" attributes="false"/>
        <!-- Lucene index is configured below -->
            <lucene>
                <analyzer class="org.apache.lucene.analysis.standard.StandardAnalyzer"/>
                <analyzer id="ws" class="org.apache.lucene.analysis.core.WhitespaceAnalyzer"/>
                <text qname="TITLE" analyzer="ws"/>
                <text qname="p">
                    <inline qname="em"/>
                </text>
                <text match="//foo/*"/>
                <!-- "inline" and "ignore" can be specified globally or per-index as
                     shown above -->
                <inline qname="b"/>
                <ignore qname="note"/>
            </lucene>
        </index>
    </collection>
                
                    

                        <collection xmlns="http://exist-db.org/collection-config/1.0">
        <index xmlns:atom="http://www.w3.org/2005/Atom"
            xmlns:html="http://www.w3.org/1999/xhtml"
            xmlns:wiki="http://exist-db.org/xquery/wiki">
            <!-- Lucene index is configured below -->
            <lucene>
                <analyzer class="org.apache.lucene.analysis.standard.StandardAnalyzer"/>
                <analyzer id="ws" class="org.apache.lucene.analysis.core.WhitespaceAnalyzer"/>
                <text qname="TITLE" analyzer="ws"/>
                <text qname="p">
                    <inline qname="em"/>
                </text>
                <text match="//foo/*"/>
                <!-- "inline" and "ignore" can be specified globally or per-index as
                     shown above -->
                <inline qname="b"/>
                <ignore qname="note"/>
            </lucene>
        </index>
    </collection>
                
                    

You can either define a Lucene index on a single element or attribute name (qname="...") or a node path with wildcards (match="...", see below). It is important make sure to *choose the right context* for an index, which has to be the same as in your query. To better understand this, let's have a look at how the index creation is handled by eXist-db and Lucene. The following configuration:

&lt;text qname="SPEECH"/&gt;
creates an index ONLY on SPEECH. What is passed to Lucene is the string value of SPEECH, which includes the text of all its descendant text nodes (\*except\* those filtered out by an optional ignore). For example, consider the fragment:

                    <SPEECH>
        <SPEAKER>Second Witch</SPEAKER>
        <LINE>Fillet of a fenny snake,</LINE>
        <LINE>In the cauldron boil and bake;</LINE>
    </SPEECH>
                

If you have an index on SPEECH, Lucene will create a "document" with the text "Second Witch Fillet of a fenny snake, In the cauldron boil and bake;" and index it. eXist-db internally links this Lucene document to the SPEECH node, but Lucene has no knowledge of that (it doesn't know anything about XML nodes).

The query:

//SPEECH\[ft:query(., 'cauldron')\]
searches the index and finds the "document" containing the SPEECH text, which eXist-db can trace back to the SPEECH node in the XML document. However, it is required that you use the same context (SPEECH) for creating and querying the index. The query:

//SPEECH\[ft:query(LINE, 'cauldron')\]
will not return anything, even though LINE is a child of SPEECH and 'cauldron' was indexed. This particular 'cauldron' is linked to its ancestor SPEECH node, not its parent LINE.

However, you are free to give the user both options, i.e. use SPEECH and LINE as context at the same time. How? Simply define a second index on LINE:

                    <text qname="SPEECH"/>
    <text qname="LINE"/>
                

Let's use a different example to illustrate that. Assume you have a document with encoded place names:

                        <p>He loves <placeName>Paris</placeName>.</p>
                    

For a general query you probably want to search through all paragraphs. However, you may also want to provide an advanced search option, which allows the user to restrict his query to place names. To make this possible, simply define an index on placeName as well:

                        <lucene>
        <text qname="p"/>
        <text qname="placeName"/>
    </lucene>
                    

Based on this setup, you'll be able to query for the word 'Paris' anywhere in a paragraph:

//p\[ft:query(., 'paris')\]
as well as 'Paris' occurring within a placeName:

//p\[ft:query(placeName, 'paris')\]
### Using match="..."

In addition to defining an index on a given qname, you may also specify a "path" with wildcards. *This feature is subject to change*, so please be careful when using it.

Assume you want to define an index on all the possible elements below SPEECH. You can do this by creating one index for every element:

                        <text qname="LINE"/>
    <text qname="SPEAKER"/>
                    

As a shortcut, you can use a `match` attribute with a wildcard:

&lt;text match="//SPEECH/\*"/&gt;
which will create a separate index on each child element of SPEECH it encounters. Please note that the argument to match is a simple path pattern, not an XPath expression. It only allows / and // to denote a child or descendant step, plus the wildcard to match an arbitrary element.

As explained above, you have to figure out which parts of your document will likely be interesting as context for a full text query. The full text index will work best if the context isn't too narrow. For example, if you have a document structure with section divs, headings and paragraphs, you would probably want to create an index on the divs and maybe on the headings, so the user can differentiate between the two. In some cases, you could decide to put the index on the paragraph level, but then you don't need the index on the section since you can always get from the paragraph back to the section.

If you query a larger context, you can use the [KWIC](kwic.md) module to show the user only a certain chunk of text *surrounding* each match. Or you can ask eXist-db to [highlight each match](kwic.md#highlight) with an exist:match tag, which you can later use to locate the matches within the text.

### Whitespace Treatment and Ignored Content

#### Inlined elements

By default, eXist-db's indexer assumes that element boundaries break a word or token. For example, if you have an element:

                                <size><width>12</width><height>8</height></size>
                            

You want "12" and "8" to be indexed as separate tokens, even though there's no whitespace between the elements. By default, eXist-db will indeed pass the content of the two elements to Lucene as separate strings and Lucene will thus see two tokens instead of just "128".

However, you usually don't want this behaviour for mixed content nodes. For example:

                                <p>This is <b>un</b>clear.</p>
                            

In this case, you want "unclear" to be indexed as one word. This can be done by telling eXist-db which nodes are "inline" nodes. The example configuration above defines:

&lt;inline qname="b"/&gt;
The inline option can be specified globally, which means it will be applied to all b elements, or per-index:

&lt;text qname="p"&gt; &lt;inline qname="em"/&gt; &lt;/text&gt;
#### Ignored elements

Also, it is sometimes necessary to skip the content of an inlined element, which can appear in the middle of a text sequence you want to index. Notes are a good example:

                                <p>This is a paragraph
    <note>containing an inline note</note>.</p>
                            

Use an ignore element in the collection configuration to have eXist-db ignore the note:

&lt;ignore qname="note"/&gt;
Basically, ignore simply allows you to hide a chunk of text before Lucene sees it.

Like the inline tag, ignore may appear globally or within a single index definition.

The ignore only applies to descendants of an indexed element. You can still create another index on the ignored element itself. For example, you can have index definitions for p and note:

                                <lucene>
        <text qname="p"/>
        <text qname="note"/>
        <ignore qname="note"/>
    </lucene>
                            

If note appears within p, it will not be added to the index on p, but only to the index on note. This means that the query

//p\[ft:query(., "note")\]
may not return a hit if "note" occurs within a note, while

//p\[ft:query(note, "note")\]
may still find a match.

### Boost

A boost value can be assigned to an index to give it a higher score. The score for each match will be multiplied by the boost factor (default is: 1.0). For example, you may want to rank matches in titles higher than other matches. Here's how we configure the documentation search indexes in eXist-db:

                            <lucene>
        <analyzer class="org.apache.lucene.analysis.standard.StandardAnalyzer"/>
        <text qname="section">
            <ignore qname="title"/>
            <ignore qname="programlisting"/>
            <ignore qname="screen"/>
            <ignore qname="synopsis"/>
        </text>
        <text qname="para"/>
        <text qname="title" boost="2.0"/>
        <ignore qname="title"/>
    </lucene>
                        

The title index gets a boost of 2.0 to make sure that title matches get a higher score. Since the title element does occur within section, we add an ignore rule to the index definition on the section and create a separate index on title. We also ignore titles occurring inside paragraphs. Without this, title would be matched two times.

Because the title is now indexed separately, we also need to query it explicitly. For example, to search the section and the title at the same time, one could issue the following query:

for $sect in /book//section\[ft:query(., "ngram")\] | /book//section\[ft:query(title, "ngram")\] order by ft:score($sect) descending return $sect
#### Attribute Boost

Starting with eXist-db 3.0 a boost value can also be assigned to an index by attribute. This could be used to weight your search results even if you have flat data structures with the same attribute value pairs in attributes throughout your documents. Two flavours of dynamic weighting are available through the new pairs match-sibling-attribute, has-sibling-attribute and match-attribute, has-attribute child elements in the full-text index configuration. If you have data in Lexical metadata framework (LMF) format you will recognize these repeated structures of feat elements with 'att' attributes and 'val' attributes within LexicalEntry elements, e g feat att='writtenForm' val='LMF feature value'. The attribute boosting allows you to weight the results based on the value of the 'att' attribute so that eg hits in definitions come before hits in comments and examples. This behaviour is enabled by adding a child match-sibling-attr to a Lucene configuration text element. An example index configuration for it looks like this:

                      
              <text qname='@val'>
                   <match-sibling-attr qname='att'
                           value='writtenForm' boost='25'/>
              </text>
            
            

This means that the ft:score\#1 function will boost hits in 'val' attributes with a factor of 25 times for 'writtenForm' value of the 'att' attribute.

In the same way match-attr would be used for element qnames in the text element.

If you do not care about any value of the sibling attribute then use the has-attribute index configuration variant. An example index configuration with has-attr looks like this:

                      
                <text qname='feat'>
                   <has-attr qname='xml:lang' boost='0'/>
                   </text>
              
            

This means that if your feat elements have an attribute xml:lang it will score them nil and push them last of the pack, which might be useful to demote hits in features in other languages than the main entry language.

In the same way has-sibling-attr would be used for attribute qnames in the text element.

### Analyzers

One of the strengths of Lucene is that it allows the developer to determine nearly every aspect of the text analysis. This is mostly done through analyzer classes, which combine a tokenizer with a chain of filters to post-process the tokenized text. eXist-db's Lucene module already allows different analyzers to be used for different indexes.

                            <lucene>
        <analyzer class="org.apache.lucene.analysis.standard.StandardAnalyzer"/>
        <analyzer id="ws" class="org.apache.lucene.analysis.core.WhitespaceAnalyzer"/>
        <text match="//SPEECH//*"/>
        <text qname="TITLE" analyzer="ws"/>
    </lucene>
                        

In the example above, we define that Lucene's [StandardAnalyzer](http://lucene.apache.org/core/4_4_0/analyzers-common/org/apache/lucene/analysis/standard/StandardAnalyzer.html) should be used by default (the analyzer element without `id` attribute). We provide an additional analyzer and assign it the id `ws`, by which the analyzer can be referenced in the actual index definitions.

The [whitespace analyzer](http://lucene.apache.org/core/4_4_0/analyzers-common/org/apache/lucene/analysis/core/WhitespaceAnalyzer.html) is the most basic one. As the name says, it tokenizes the text at white space characters, but treats all other characters - including punctuation - as part of the token. The tokens are not converted to lower case and there's no stopword filter applied.

#### Configuring the Analyzer

We provide the capability to send configuration parameters to the instantiation of the Analyzer. These parameters must match a Constructor signature on the underlying Java class of the Analyzer, so we would first recommend that you review the Javadoc for the Analyzer that you wish to configure.

We currently support passing the following types: "String" (default if no type is specified) "java.io.FileReader" (since Lucene 4) or "file" "java.lang.Boolean" or "boolean" "java.lang.Integer" or "int" "org.apache.lucene.analysis.util.CharArraySet" or "set" "java.lang.reflect.Field" The value [Version\#LUCENE\_CURRENT](http://lucene.apache.org/core/4_4_0/core/org/apache/lucene/util/Version.html#LUCENE_CURRENT) is always added as first parameter for the analyzer constructor, but a fall back mechanism is present for older analyzers. The previously valid values "java.io.File" and "java.util.Set" can not be used since Lucene 4.

                                
    <analyzer id="stdstops" class="org.apache.lucene.analysis.standard.StandardAnalyzer">
        <param name="stopwords" type="java.io.FileReader" value="/tmp/stop.txt"/>
    </analyzer>
                                
                            

                                
    <analyzer id="stdstops" class="org.apache.lucene.analysis.standard.StandardAnalyzer">
        <param name="stopwords" type="org.apache.lucene.analysis.util.CharArraySet">
            <value>the</value>
            <value>this</value>
            <value>and</value>
            <value>that</value>
        </param>
    </analyzer>
                                
                            

Note that using the Snowball analyzer requires you to add additional libraries to lib/user.

                                
    <analyzer id="sbstops" class="org.apache.lucene.analysis.snowball.SnowballAnalyzer">
        <param name="name" value="English"/>
        <param name="stopwords" type="org.apache.lucene.analysis.util.CharArraySet">
            <value>the</value>
            <value>this</value>
            <value>and</value>
            <value>that</value>
        </param>
    </analyzer>
                                
                            

We will certainly add more features in the future, e.g. a possibility to construct a new analyzer from a set of filters. For the time being, you can always provide your own analyzer or use one of those supplied by Lucene or compatible software.

### Defining Fields

Sometimes you may want to define different Lucene indexes on the same set of elements, e.g. to use a different analyzer. eXist-db allows to name a certain index using the `field` attribute:

&lt;text field="title" qname="title" analyzer="en"/&gt;
Such an index is called `named index`. See [Query a Named Index](#query-a-named-index) on how to query the `named indexes`.

## Querying the Index

Querying lucene from XQuery is straightforward. For example:

``` xquery
for $m in //SPEECH[ft:query(., "boil bubble")]
order by ft:score($m) descending
return $m
```

The query function takes a query string in Lucene's default [query syntax](http://lucene.apache.org/core/3_6_0/queryparsersyntax.html). It returns a set of nodes which are relevant with respect to the query. Lucene assigns a relevance score or rank to each match. This score is preserved by eXist-db and can be accessed through the score function, which returns a decimal value. The higher the score, the more relevant is the text. You can use Lucene's features to "boost" a certain term in the query, i.e. give it a higher or lower influence on the final rank.

Please note that the score is computed relative to the root context of the index. If you created an index on SPEECH, all scores will be computed on basis of the text in the SPEECH nodes, even though your actual query may only return LINE children of SPEECH.

The Lucene module is fully supported by eXist-db's query-rewriting optimizer, which means that the query engine can rewrite the XQuery expression to make best use of the available indexes. All the rules and hints given in the [tuning](tuning.md) guide fully apply to the Lucene index.

To present search results in a *Keywords in Context* format, you may want to have a look at eXist-db's [KWIC](kwic.md) module.

### Query a Named Index

To query a named index (see [Defining Fields](#named-indexes)), use the `ft:query-field($fieldName, $query)` instead of `ft:query`:

ft:query-field("title", "xml")
`ft:query-field` works exactly like `ft:query`, except that the set of nodes to search is determined by the nodes in the named index. The function returns the nodes selected by the query, which would be title elements in the example above.

You can thus use `ft:query-field` with an XPath filter expression just as you would call `ft:query`:

//section\[ft:query-field("title", "xml")\]
### Describing Queries in XML

Lucene's default query syntax does not provide access to all available features. However, eXist-db's `ft:query` function also accepts a description of the query in XML as an alternative to passing a query string. The XML description closely mirrors Lucene's query API. It is transformed into an internal tree of query objects, which is directly passed to Lucene for execution. This has some advantages. For example, you can specify if the order of terms should be relevant for a phrase query:

``` xquery
let $query :=
    <query>
        <near ordered="no">miserable nation</near>
    </query>
return
    //SPEECH[ft:query(., $query)]
```

The following elements may occur within a query description:

term  
Defines a single term to be searched in the index. If the root query element contains a sequence of term elements, wrap them in &lt;bool&gt;&lt;/bool&gt; and they will be combined as in a boolean "or" query. For example:

let $query := &lt;query&gt; &lt;bool&gt;&lt;term&gt;nation&lt;/term&gt;&lt;term&gt;miserable&lt;/term&gt;&lt;/bool&gt; &lt;/query&gt; return //SPEECH\[ft:query(., $query)\]

finds all SPEECH elements containing either "nation" or "miserable" or both.

wildcard  
A string with a '\*' wildcard in it, which will be matched against the terms of a document. Can be used instead of a term element. For example:

let $query := &lt;query&gt; &lt;bool&gt;&lt;term&gt;nation&lt;/term&gt;&lt;wildcard&gt;miser\*&lt;/wildcard&gt;&lt;/bool&gt; &lt;/query&gt; return //SPEECH\[ft:query(., $query)\]

regex  
A regular expression which will be matched against the terms of a document. Can be used instead of a term element. For example:

let $query := &lt;query&gt; &lt;bool&gt;&lt;term&gt;nation&lt;/term&gt;&lt;regex&gt;miser.\*&lt;/regex&gt;&lt;/bool&gt; &lt;/query&gt; return //SPEECH\[ft:query(., $query)\]

bool  
Constructs a boolean query from its children. Each child element may have an occurrence indicator, which could be either `must`, `should` or `not`:

must  
this part of the query *must* be matched

should  
this part of the query *should* be matched, but doesn't need to

not  
this part of the query *must not* be matched

let $query := &lt;query&gt; &lt;bool&gt;&lt;term occur="must"&gt;boil&lt;/term&gt;&lt;term occur="should"&gt;bubble&lt;/term&gt;&lt;/bool&gt; &lt;/query&gt; return //SPEECH\[ft:query(LINE, $query)\]

phrase  
Searches for a group of terms occurring in the correct order. The element may either contain explicit term elements or text content. Text will be automatically tokenized into a sequence of terms. For example:

let $query := &lt;query&gt; &lt;phrase&gt;cauldron boil&lt;/phrase&gt; &lt;/query&gt; return //SPEECH\[ft:query(., $query)\]

has the same effect as:

let $query := &lt;query&gt; &lt;phrase&gt;&lt;term&gt;cauldron&lt;/term&gt;&lt;term&gt;boil&lt;/term&gt;&lt;/phrase&gt; &lt;/query&gt; return //SPEECH\[ft:query(., $query)\]

The attribute `slop` can be used for a proximity search: Lucene will try to find terms which are within the specified distance:

let $query := &lt;query&gt; &lt;phrase slop="10"&gt;&lt;term&gt;frog&lt;/term&gt;&lt;term&gt;dog&lt;/term&gt;&lt;/phrase&gt; &lt;/query&gt; return //SPEECH\[ft:query(., $query)\]

near  
near is a powerful alternative to phrase and one of the features not available through the standard Lucene query parser.

If the element has text content only, it will be tokenized into terms and the expression behaves like phrase. Otherwise it may contain any combination of term, first and nested near elements. This makes it possible to search for two sequences of terms which are within a specific distance. For example:

let $query := &lt;query&gt; &lt;near slop="20"&gt;&lt;term&gt;snake&lt;/term&gt;&lt;near slop="1"&gt;tongue dog&lt;/near&gt;&lt;/near&gt; &lt;/query&gt; return //SPEECH\[ft:query(., $query)\]

Element first matches a span against the start of the text in the context node. It takes an optional attribute `end` to specify the maximum distance from the start of the text. For example:

let $query := &lt;query&gt; &lt;near slop="50"&gt;&lt;first end="2"&gt;&lt;near&gt;second witch&lt;/near&gt;&lt;/first&gt;&lt;near slop="1"&gt;tongue dog&lt;/near&gt;&lt;/near&gt; &lt;/query&gt; return //SPEECH\[ft:query(., $query)\]

As shown above, the content of first can again be text, a term or near.

Contrary to phrase, near can be told to ignore the order of its components. Use parameter `ordered="yes|no"` to change near's behaviour. For example:

let $query := &lt;query&gt; &lt;near slop="100" ordered="no"&gt;&lt;term&gt;bubble&lt;/term&gt;&lt;term&gt;fillet&lt;/term&gt;&lt;/near&gt; &lt;/query&gt; return //SPEECH\[ft:query(., $query)\]

All elements in a query may have an optional `boost` parameter (a float value). The score of the nodes matching the corresponding query part will be multiplied by the *boost*.

### Additional parameters

The ft:query function allows a third parameter, which can be used to pass some additional settings to the query engine. The parameter should contain an XML fragment which lists the configuration properties to be set as child elements:

``` xquery
let $options :=
    <options>
        <default-operator>and</default-operator>
        <phrase-slop>1</phrase-slop>
        <leading-wildcard>no</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>
return
    //SPEECH[ft:query(., $query, $options)]
```

The meaning of those properties is as follows

filter-rewrite  
Controls how terms are expanded for wildcard or regular expression searches. If set to "yes", Lucene will use a filter to pre-process matching terms. If set to "no", all matching terms will be added to a single boolean query which is then executed. This may generate a "too many clauses" exception when applied to large data sets. Setting filter-rewrite to "yes" avoids those issues.

default-operator  
The default operator with which multiple terms will be combined. Allowed values: "or", "and".

phrase-slop  
Sets the default slop for phrases. If zero, then exact phrase matches are required. Default value is zero.

leading-wildcard  
When set to "yes", \* or ? are allowed as the first character of a PrefixQuery and WildcardQuery. Note that this can produce very slow queries on big indexes.

## Adding Constructed Fields to a Document

This feature allows to add arbitrary fields to a binary or XML document and have them indexed with lucene. It was developed as part of the [content extraction framework](contentextraction.md) to attach metadata extracted from e.g. a PDF to the binary document. It works equally well for XML documents though and is an efficient method, e.g. to attach computed fields to a document, containing information which does not exist in the XML as such.

The field indexes are not configured via `collection.xconf`. Instead we add fields programmatically from an XQuery (which could be run via a trigger):

``` xquery
ft:index("/db/demo/test.xml", <doc>
    <field name="title" store="yes">Indexing</field>
    <field name="author" store="yes">Me</field>
    <field name="date" store="yes">2013</field>
</doc>)
```

The `store` attribute indicates that the fields content should be stored as a string. Without this attribute, the content will be indexed for search, but you won't be able to retrieve the contents.

To get the contents of a field, use the `ft:get-field` function:

ft:get-field("/db/demo/test.xml", "title")
To query this index, use the `ft:search` function:

ft:search("/db/demo/test.xml", "title:indexing and author:me")
Custom field indexes are automatically deleted when their parent document is removed. If you want to update fields without removing the document, you need to delete the old fields first though. This can be done using the `ft:remove-index` function:

ft:remove-index("/db/demo/test.xml")
