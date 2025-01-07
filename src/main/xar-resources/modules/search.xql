xquery version "3.0";

(:~ ================================================
    Implements the documentation search.
    ================================================ :)
module namespace dq = "http://exist-db.org/xquery/documentation/search";

import module namespace config = "http://exist-db.org/xquery/apps/config" at "config.xqm";

import module namespace kwic = "http://exist-db.org/xquery/kwic";
import module namespace util = "http://exist-db.org/xquery/util";

declare namespace db5 = "http://docbook.org/ns/docbook";
declare namespace templates = "http://exist-db.org/xquery/html-templating";

declare option exist:serialize "method=html media-type=text/html expand-xincludes=yes";

declare variable $dq:CHARS_SUMMARY := 1000;
declare variable $dq:CHARS_KWIC := 80;

(:~
: Templating function: process the query.
:)
declare
    %public
    %templates:default("field", "all")
    %templates:default("view", "summary")
function dq:query($node as node()*, $model as map(*), $q as xs:string?, $field as xs:string, $view as xs:string) as element(div)? {
	if ($q) then
		let $hits := dq:do-query(collection($config:data-root), $q, $field)
		return
            <div id="f-search">
			{
                dq:print-results($hits, map { "q": $q, "field": $field}, $view)
			}
            </div>
	else
		()
};

(:~
: Returns the elements for which the $query matches.
:
: @param context the nodes to search
: @param query the full-text query
: @param field the name of a field, if the query should be restricted to a specific field
:
: @return The elements that match the query, typically one of:
:     db5:title, db5:keyword, db5:para, db5:sect1, db5:sect2, db5:sect3.
:)
declare
    %public
function dq:do-query($context as node()*, $query as xs:string?, $field as xs:string?) as element()* {
    switch ($field)
        case "title" return
            $context/db5:article/db5:info/db5:title[ft:query(., $query)]
            |
            $context//(db5:sect3|db5:sect2|db5:sect1)/db5:title[ft:query(., $query)]

        default return
            $context//db5:keyword[ft:query(., $query)]
            |
            $context/db5:article/(db5:info/db5:title|db5:para)[ft:query(., $query)]
            |
            $context//(db5:sect3|db5:sect2|db5:sect1)/db5:title[ft:query(., $query)]
            |
            $context//(db5:sect3|db5:sect2|db5:sect1)[ft:query(., $query)]
};

(:~
: Display the query results.
:)
declare
    %private
function dq:print-results($hits as element()*, $search-params as map(xs:string, xs:string), $view as xs:string) {
    <section id="f-results">
        <p class="heading">Found {count($hits)} result{if (count($hits) eq 1) then "" else "s"}.</p>
        {
            for $hit in $hits
            let $score := ft:score($hit)
            order by $score descending
            return
                <article class="hit hit__{$view}" data-score="{$score}">
                {
                    dq:print-headings($hit, $search-params),
                    dq:print($hit, $search-params, $view)
                }
                </article>
        }
    </section>
};

declare %private function dq:get-id ($e) {
    ($e/@xml:id/string(), "D" || util:node-id($e))[1]
};

(:~
: Print the hierarchical context of a hit.
:)
declare
    %private
function dq:print-headings($hit as element(), $search-params as map(xs:string, xs:string)) {
    let $article-url := util:document-name(root($hit))
    return
        <header class="hit-heading">
        {
            <a class="hit-link hit-link__article" href="{ $article-url }">{
                $hit/ancestor-or-self::db5:article/db5:info/db5:title/text()
            }</a>,
            for $sect at $pos in $hit/(ancestor-or-self::db5:sect3|ancestor-or-self::db5:sect2|ancestor-or-self::db5:sect1)
            return (
                <span class="separator">&gt;</span>,
                <a class="hit-link" href="{$article-url|| "#" || dq:get-id($sect) }">{$sect/db5:title/text()}</a>
            )
        }
        </header>
};

(:~
: Display the hits: this function iterates through all hits and calls
: kwic:summarize to print out a summary of each match.
:)
declare
    %private
function dq:print($hit as element(), $search-params as map(xs:string, xs:string), $view as xs:string) as element()* {
    let $matches := kwic:get-matches($hit)
    let $ancestors := (
        $matches/ancestor::db5:para |
        $matches/ancestor::db5:title |
        $matches/ancestor::db5:td |
        $matches/ancestor::db5:note[not(db5:para)]
    )

    return
        if ($view eq "kwic") then
            let $config := <config xmlns="" width="{ $dq:CHARS_KWIC }" table="no" />

            for $ancestor in $ancestors
            for $match in $ancestor//exist:match
            return
                kwic:get-summary($ancestor, $match, $config)
        else
            for $ancestor in $ancestors
            return <p class="hit-summary">{ dq:transform-hit($ancestor) }</p>
};

declare
    %private
function dq:transform-hit($element as node()) as node()* {
    typeswitch($element) 
    case element(exist:match)
        return element mark { $element/node() ! dq:transform-hit(.) }
    case element()
        return $element/node() ! dq:transform-hit(.)
    case text() return $element
    default return ()
};

declare
    %private
function dq:serialize-parameter($key as xs:string, $value as xs:string) as xs:string {
    $key || "=" || $value
};

declare
    %private
function dq:to-uri-query($search-params as map(xs:string, xs:string)) as xs:string {
    string-join(
        map:for-each(
            map:remove($search-params, "q"),
            dq:serialize-parameter#2
        ),
        "&amp;"
    )
};
