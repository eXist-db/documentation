# Legacy Full Text Index

## Note

> **Note**
>
> Important:
> The Legacy Full Text Index should not be used anymore. The functionaly will be removed from eXist-db in a future release, because it causes instability for the database. Please use the Lucene based fulltext index instead.

This index is used to query for a sequence of separate "words" or tokens in a longer stream of text. While building the index, the text is parsed into single tokens which are then stored in the index.

> **Important**
>
> Historically, eXist has been creating a default full text index on all text nodes and attribute values. This is no longer the case! Creating default indexes on data which you may never use is too expensive, in particular, since eXist is now providing a wider range of different indexes which can be much better optimized than the default index and will offer superior performance.

Anyway, as for the other index types, you can configure the full text index in the collection configuration and we will try to keep the configuration of the new index backwards compatible. We thus recommend to create a collection configuration file, disable the default index-all behaviour and define some explicit full text indexes on your documents. The details of this process will be described below.

The full text index is only used in combination with eXist's fulltext search extensions. In particular, you can use the following eXist-specific operators and functions that apply a fulltext index:

-   Operators: `&=` and `|=`

-   Main Functions: `text:match-all()`, `text:match-any()` and `near()`

> **Note**
>
> It is important to note that, if you have disabled full text indexing for certain elements, these operators and functions will also be effectively disabled, and will not return matches. As a result, eXist will not return results for queries that normally would have results provided fulltext indexing was enabled. Note also that this is in direct contrast to the operation of range indexing, which does fallback to full searching of the document if no range index applies (see below).

## Full text index configuration

The *fulltext index* is defined by the fulltext element - along with include, exclude and create elements. The full text index is currently subject to a major redesign and the configuration syntax somewhat reflects this because it is a bit inconsistent. eXist's current default behaviour is to create a full text index on all text nodes in a document. The include and exclude tags are used to add or hide nodes from the default indexing. The indexes created by the default indexing are always context-dependant. The nodes to include/exclude are thus specified via a `path` attribute, not a `qname` attribute.

However, you can create explicit indexes on a qname using the create element. This is the recommended approach. In fact, as the full text index is currently being redesigned, we are not sure if we will keep the current default full text indexing in its current state. A fulltext configuration which only uses create elements is shown below:

                        
    <fulltext default="none" attributes="false">
          <!-- Full text indexes -->
          <create qname="author"/>
          <create qname="title" content="mixed"/>
    </fulltext>

                    

With this example, the full text default attribute is set to "none", which disables the default full text indexing for all document elements. Attribute nodes are handled separately. Setting `attributes="false"` disables the default indexing for attributes as well.

The first child element creates a standard full text index on all author elements, identified by their *qname*. The second one puts an index on title, but adds an option `content="mixed"`. This parameter causes the indexer to watch out for mixed-content nodes. For example, if your source XML contains markup like:

                        <p>Some <span>un</span><span>even</span> amount.</p>
                    

You may want to treat "uneven" as a single word so you can query for p |= "uneven". In this case, you need to pass content="mixed" to the indexer. The concatenated text nodes of element mixed and all its descendants will be passed to the indexer as one single string. The indexer thus sees and indexes "uneven" as a single token.

On the other hand, if you have

                        <date><year>1183</year><month>March</month><date>
                    

you probably want to be able to query for "March" even though there's no space between the year and month elements. In this case the standard settings are ok as they will add a virtual break between the elements.

## Querying Text (Fulltext Searching)

The standard XPath/XQuery function library contains most of the common string manipulation functions provided by most programming languages. However, these functions are insufficient for conducting keyword or phrase searches inside a larger portion of text or mixed content. This is a weak point if you have to work with *document-centric* (i.e. mainly free-form text), as opposed to *data-centric* documents. For many types of documents, the standard string functions do not yield satisfactory search results.

For example, suppose upon reading a chapter in an electronic text, you encountered something about "XML" and "databases", but later you could not recall the exact section where you read it. Using standard XPath, you could try a query like:

//chapter\[contains(., 'XML') and contains(., 'databases')\]
This query execution will likely be quite slow, since the XPath engine will, in this case, scan the entire character content of all chapter nodes and their descendants. And yet, there is no certainty that all possible text matches will be found - for example, "databases" might have been written with a capital letter at the start of the sentence, and so would not be included in the results.

To resolve this issue, eXist-db offers additional operators and extension functions for efficient, index-based access to the full text content of nodes. With eXist-db, you could alternatively formulate the above query as follows:

//chapter\[near(., 'XML database?', 50)\]
This will return all chapters containing both keywords in the correct order, and as well, will find matches that have under 50 words between them. Additionally, the wildcard character `?` in `database?` will match the singular as well as the plural instances of "database", and the search would NOT be case-sensitive. Furthermore, since the query is index-based, it will usually be an order of magnitude faster than the standard XPath query above.

### Operators

In this section, we discuss each of eXist-db's text-search extensions. In cases where the order and distance of search terms is not important, eXist-db offers two additional operators for simple keyword queries: `&=` and `|=`.

node-set &= 'string of keywords'  
This operator selects context nodes containing *ALL* of the keywords in the right-hand argument in any order. The default tokenizer is used to split the right-hand argument into single tokens, i.e. any punctuation or white spaces are used to separate the keywords and, after which, are omitted. Note also that wildcards are allowed, and keyword comparison is NOT case-sensitive.

node-set |= 'string of keywords'  
Similar to above, this operator selects context nodes containing *ANY* of the keywords in the right-hand argument.

> **Note**
>
> With the `&=` and `|=`operations, keyword search strings are split into tokens using the default tokenizer function. The current implementation of this operation will work well for all European languages. For non-European languages, however, eXist-db uses the predefined Unicode code points (0 to 10FFFF) to determine where the string will be split.

Both of the above operators accept simple wildcards in the keyword string. A `?` matches zero or one character, `*` matches zero or more characters. A character range `[abc]` (as a regular expression) matches any of the characters in that range. You may use a backslash to escape wildcard characters.

To match more complex patterns, full regular expression syntax is supported through additional functions, which are discussed below.

> **Note**
>
> There is an important semantic difference between the following two expressions:
>
> //SPEECH\[LINE &= "cursed spite"\]
> and
>
> //SPEECH\[LINE &= "cursed" and LINE &="spite"\]
> The first expression selects all distinct `LINE` nodes that contain both of the search terms. The second expression selects all context nodes (`SPEECH` nodes) that have `LINE` children containing either or both of the terms, and should yield more results than the first one. To make the first expression select the same nodes (at least, nearly the same nodes), you would have to change the first expression to:
>
> //SPEECH\[. &= "cursed spite"\]
> Note, however, that this new expression will also include other nodes, for instance `SPEAKER` or `STAGEDIR`, which are children of the `SPEECH` parent node.

### Functions utilising the legacy full text index

near()  
As shown in a previous example, the `near()` function behaves quite similarly to the `&=` operator, but also pays attention to the order of search terms and their distance from each other in the source document.

The syntax for this function is as follows:

near(node-list, 'string of keywords' \[, max-distance\])

The function measures the distance between two search terms by counting the number of words between them. A maximum distance of 1 is assumed by default, in which case the search terms occur next to each other. Other values for the maximal and minimal distance may be specified in the optional third argument. As a special case, if the string in the second argument contains only one token, any distance values in the third and fourth argument are ignored, and the function performs identically to the &= operator. For example, with the following search expression:

//SPEECH\[near(., 'love marriage', 25)

the search engine will return any `SPEECH` elements containing the words "love" and "marriage" within the range of 25 words between them.

Similar to the `&=` operator, `near()` accepts wildcards in the keyword string, and punctuation and whitespace will be skipped according to the default tokenization rules.

text:match-all() / text:match-any()  
These two functions are variations of the `&=` and `|=` operators, and interpret their arguments as regular expressions. *However*, contrary to the `matches()` function in the XQuery core library, `text:match-all()` and `text:match-any()` try to match the regular expression argument against the keywords contained in the full text index, but *NOT* against the entire text.

For example, assume you have a document that contains the following paragraph:

&lt;para&gt;Peter lives in Frankfurt&lt;/para&gt;

Then the following expression:

text:match-all(para, "li\[vf\]e.?", "frank.\*")

will match this paragraph because it contains two keywords matching the specified regular expression patterns.

`text:match-all()` corresponds to `&=` in that it will select context nodes with keywords matching *ALL* of the specified regular expressions. `text:match-any()` will select nodes with keywords matching *ANY* of the specified regular expression.

Since tokenization doesn't work correctly with regular expression patterns, each keyword has to be specified as a separate argument, so the syntax looks like:

text:match-all(node-set, 'regexp' \[, 'regexp' ...\])

> **Note**
>
> Please note that the `text:match-any()` functions will try to match the regular expression against the entire keyword. For example, the expression
>
> //SPEECH\[text:match-all(LINE, 'li\[vf\]e')\]
> will match 'live', 'life', but not 'lives'.
>
> eXist-db uses the [java.util.regex API](http://java.sun.com/j2se/1.4.2/docs/api/java/util/regex/package-summary.html) for regular expressions. A description of the supported regexp syntax can be found on the [Sun Java Tutorial](http://java.sun.com/docs/books/tutorial/extra/regex/).
