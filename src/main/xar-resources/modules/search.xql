xquery version "3.0";

(:~ ================================================
    Implements the documentation search.
    ================================================ :)
module namespace dq = "http://exist-db.org/xquery/documentation/search";

import module namespace config = "http://exist-db.org/xquery/apps/config" at "config.xqm";

import module namespace kwic = "http://exist-db.org/xquery/kwic";
import module namespace util = "http://exist-db.org/xquery/util";

declare namespace db5 = "http://docbook.org/ns/docbook";
declare namespace templates = "http://exist-db.org/xquery/templates";

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
		<div id="f-results">
			<p class="heading">Found {count($hits)} result{if (count($hits) eq 1) then "" else "s"}.</p>
			{
				if ($view eq 'summary') then
					for $hit in $hits
					let $score := ft:score($hit)
					order by $score descending
					return
					    <div class="section">
					        <span class="score">Score: {round-half-to-even($score, 2)}</span>
							<div class="headings">{ dq:print-headings($hit, $search-params) }</div>
							{ dq:print($hit, $search-params, $view) }
						</div>
				else
					<table class="kwic">
					{
						for $hit in $hits
						order by ft:score($hit) descending
						return (
							<tr>
								<td class="headings" colspan="3">
								{dq:print-headings($hit, $search-params)}
								</td>
							</tr>,
							dq:print($hit, $search-params, $view)
						)
					}
					</table>
			}
		</div>
};

(:~
: Print the hierarchical context of a hit.
:)
declare
    %private
function dq:print-headings($hit as element(), $search-params as map(xs:string, xs:string)) {
    let $search-params-uri-query := dq:to-uri-query($search-params)
	let $uri := util:document-name(root($hit)) || "?" || $search-params-uri-query || "&amp;id=D" || util:node-id($hit)
	return
	(
        <a href="{$uri}">{$hit/ancestor-or-self::db5:article/db5:info/db5:title/text()}</a>
        ,
        for $sect at $pos in $hit/(ancestor-or-self::db5:sect3|ancestor-or-self::db5:sect2|ancestor-or-self::db5:sect1)
        let $nodeId := util:node-id($sect)
        let $uri := util:document-name(root($sect)) || "?" || $search-params-uri-query || "&amp;id=D" || $nodeId || "#D" || $nodeId
        return
            (" > ", <a href="{$uri}">{$sect/db5:title/text()}</a>)
    )
};


(:~
: Display the hits: this function iterates through all hits and calls
: kwic:summarize to print out a summary of each match.
:)
declare
    %private
function dq:print($hit as element(), $search-params as map(xs:string, xs:string), $view as xs:string) as element()* {
    let $matches := kwic:get-matches($hit)
    return
        if ($view eq "kwic") then
            let $nodeId := util:node-id($hit)
            let $uri := util:document-name(root($hit)) || "?" || dq:to-uri-query($search-params) || "&amp;id=D" || $nodeId || "#D" || $nodeId
            let $config :=
                    <config xmlns="" width="{if ($view eq 'summary') then $dq:CHARS_SUMMARY else $dq:CHARS_KWIC}"
         			    table="{if ($view eq 'summary') then 'no' else 'yes'}"
         			    link="{$uri}"/>

            for $ancestor in ($matches/ancestor::db5:para | $matches/ancestor::db5:title | $matches/ancestor::db5:td | $matches/ancestor::db5:note[not(db5:para)])
            for $match in $ancestor//exist:match
            return
                kwic:get-summary($ancestor, $match, $config)
        else
            let $ancestors := ($matches/ancestor::db5:para | $matches/ancestor::db5:title | $matches/ancestor::db5:td | $matches/ancestor::db5:note[not(db5:para)])
            return
                for $ancestor in $ancestors
            return
                dq:match-to-copy($ancestor)
};

declare
    %private
function dq:match-to-copy($element as element()) as element() {
    element { node-name($element) } {
        $element/@*,
        for $child in $element/node()
        return
            if ($child instance of element()) then
                if ($child instance of element(exist:match)) then
                      <mark>{ $child/string() }</mark>
                else
                    dq:match-to-copy($child)
            else
                $child
    }
};

declare
    %private
function dq:to-uri-query($search-params as map(xs:string, xs:string)) as xs:string {
    string-join(
        map:for-each($search-params, function($k, $v) {
            if ($k eq "q") then
                ()
            else
                $k || "=" || $v
        }),
        "&amp;"
    )
};
