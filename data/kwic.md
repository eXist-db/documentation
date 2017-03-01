# Generating KWIC (Keywords in Context) Output

## Abstract

> A KWIC display helps users to quickly scan through search results by listing hits surrounded by their context. eXist provides a KWIC module that is not bound to a specific index or query operation, but can be applied to query results from all indexes that support match highlighting. This includes the Lucene-based index, the ngram index, as well as the old full text index.
>
> The documentation search function on eXist's home page is a good example. It queries documents written in the DocBook format. However, the KWIC module has also been successfully used and deployed with different schemas (e.g. TEI) and languages (e.g. Chinese).

## Preparing your Query

The KWIC module is entirely written in XQuery. To use the module, simply import its namespace into your query:

import module namespace kwic="http://exist-db.org/xquery/kwic";
You don't need to specify a location since the module is already registered in `conf.xml`. If you would still like to provide one, change the import as follows:

import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
The module is part of the main `exist.jar`, so we can use a resource link here.

## Using the Module

The easiest way to get KWIC output is to call the `kwic:summarize` function on an element node returned from a full text or ngram query:

``` xquery
import module namespace kwic="http://exist-db.org/xquery/kwic";
for $hit in doc("/db/shakespeare/plays/hamlet.xml")//SPEECH[ft:query(., "'nature'")] 
order by ft:score($hit) descending
return
    kwic:summarize($hit, <config width="40"/>)
```

Every call to `kwic:summarize` will return an HTML paragraph containing 3 spans with the text before and after each match as well as the match text itself:

``` xml
<p>
    <span class="previous">... s effect, sir; after what flourish your </span>
    <span class="hi">nature</span>
    <span class="following"> will.</span>
</p>
```

The config element, passed to `kwic:summarize` as second parameter, determines the appearance of the generated HTML. There are 3 different attributes you can set here:

width  
The maximum number of characters to be printed before and after the match

table  
if set to "yes", `kwic:summarize` will return an HTML table row (tr). The text chunks will be enclosed in a table column (td).

The default behaviour, `table="no"`, is to return an HTML paragraph with spans.

link  
If present, each match will be enclosed within a link, using the URI in the link attribute as target.

If you look at the output of above query, you may notice that a space is missing between words if the previous or following chunk extends to a different LINE element. Also, it would be nicer to only display text from LINE elements and to ignore SPEAKER or STAGEDIR tags. This can be achieved with the help of a callback function:

``` xquery
import module namespace kwic="http://exist-db.org/xquery/kwic";
                
declare function local:filter($node as node(), $mode as xs:string) as xs:string? {
  if ($node/parent::SPEAKER or $node/parent::STAGEDIR) then 
      ()
  else if ($mode eq 'before') then 
      concat($node, ' ')
  else 
      concat(' ', $node)
};

for $hit in doc("/db/shakespeare/plays/hamlet.xml")//SPEECH[ft:query(., "'nature'")] 
order by ft:score($hit) descending
return
kwic:summarize($hit, <config width="40"/>, util:function(xs:QName("local:filter"), 2))
```

The third parameter to `kwic:summarize` should be a reference to a function accepting 2 arguments: 1) a single text node which should be appended or prepended to the current text chunk, 2) a string indicating the current direction in which text is appended, i.e. "before" or "after". The function may return the empty sequence if the current node should be ignored (e.g. if it belongs to a "footnote" which should not be displayed). Otherwise it should return a single string.

The `local:filter` function above first checks if the passed node has a SPEAKER or STAGEDIR parent and if yes, *ignores* that node by returning the empty sequence. If not, the function adds a single whitespace before or after the string, so adjacent lines will be properly separated.

## Advanced Use

Using `kwic:summarize`, you will get one KWIC-formatted item for every match, even if the matches are in the same paragraph. Also, the context from which the text is taken is always the same: the element you queried.

To get more control over the output, you can directly call `kwic:get-summary`, which is the module's core function. It expects 3 or 4 parameters, where the first two parameters are: a) the current context root, b) the match object to process. Parameters 3 and 4 are the same as for `kwic:summarize`.

Before passing nodes to `kwic:get-summary` you have to *expand* them, which basically means to create an in-memory copy in which all matches are properly marked up with exist:match tags. The main part of the query should look as follows:

``` xquery
for $hit in doc("/db/shakespeare/plays/hamlet.xml")//SPEECH[ft:query(., "'nature'")]
let $expanded := kwic:expand($hit)
order by ft:score($hit) descending
return
    kwic:get-summary($expanded, ($expanded//exist:match)[1], <config width="40"/>,
        util:function(xs:QName("local:filter"), 2))
```

In this example, we select the first exist:match only, thus ignoring all other matches within `$expanded`.

Sometimes you may also want to change the context to restrict the KWIC display to certain elements within the larger query context, e.g. paragraphs within sections. The following example still queries SPEECH, but displays a KWIC entry for each LINE with a match, grouped by speech:

``` xquery
for $hit in doc("/db/shakespeare/plays/hamlet.xml")//SPEECH[ft:query(., "nature")]
let $expanded := kwic:expand($hit)
order by ft:score($hit) descending
return
    <div class="speech">{
        for $line in $expanded//LINE[.//exist:match]
        return
            kwic:get-summary($line, ($line/exist:match)[1], <config width="40"/>,
                util:function(xs:QName("local:filter"), 2))
    }</div>
```

You may ask why we are not querying LINE directly to get a different context, e.g. as in:

//SPEECH\[ft:query(LINE, "nature")\]
Well, we want Lucene to compute the relevance of each match with respect to the SPEECH context, not LINE. If we queried LINE, each single line would get a match score and the matches would end up in a completely different order.

## Marking up Matches without using KWIC

Sometimes you don't want to use the KWIC module, but you would still like to have indicated where matches were found in the text. eXist's XML serializer can automatically highlight matches when it writes out a piece of XML. All the matches will be surrounded by an exist:match tag.

You can achieve the same within an XQuery by calling the extension function util:expand:

``` xquery
let $expanded := util:expand($hit, "expand-xincludes=no")
return $expanded//exist:match
```

`util:expand` returns a copy of the XML fragment it received in its first parameter, which - unless configured otherwise - has all matches wrapped into exist:match tags.
