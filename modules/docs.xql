xquery version "3.0";

(:~ ================================================
    Implements the documentation search.
    ================================================ :)
module namespace dq="http://exist-db.org/xquery/documentation";

import module namespace xdb="http://exist-db.org/xquery/xmldb";

import module namespace kwic="http://exist-db.org/xquery/kwic";

declare option exist:serialize "method=html media-type=text/html expand-xincludes=yes";

declare variable $dq:COLLECTION := "doc/data";

declare variable $dq:FIELDS :=
	<fields>
		<field name="title">section[ft:query(.//title, '$q')]</field>
		<field>section[ft:query(., '$q')]</field>
	</fields>;

declare variable $dq:CHARS_SUMMARY := 120;
declare variable $dq:CHARS_KWIC := 60;

(:~
    Templating function: process the query.
:)
declare %public function dq:query($node as node()*, $model as map(*)) {
	let $query := request:get-parameter("q", ())
	let $field := request:get-parameter("field", "all")
	return
		if ($query) then
			let $hits := dq:do-query(collection($dq:COLLECTION), $query, $field)
			let $docXPath :=
                string-join(
                    map-pairs(function($k, $v) { $k || "=" || $v }, ("q", "field"), ($query, $field)),
                    "&amp;"
                )
			return
                <div id="f-search">
				{dq:print-results($hits, $docXPath)}
                </div>
		else
			()
};

(:~
	Display the hits: this function iterates through all hits and calls
	kwic:summarize to print out a summary of each match.
:)
declare %private function dq:print($hit as element(), $docXPath as xs:string, $mode as xs:string)
as element()* {
    let $nodeId := util:node-id($hit)
	let $uri := util:document-name(root($hit)) || "?" ||
		$docXPath || "&amp;id=D" || $nodeId || "#D" || $nodeId
	let $config :=
		<config xmlns="" width="{if ($mode eq 'summary') then $dq:CHARS_SUMMARY else $dq:CHARS_KWIC}"
			table="{if ($mode eq 'summary') then 'no' else 'yes'}"
			link="{$uri}"/>
    let $matches := kwic:get-matches($hit)
    for $ancestor in ($matches/ancestor::para | $matches/ancestor::title | $matches/ancestor::td |
        $matches/ancestor::note)
    return
        kwic:get-summary($ancestor, ($ancestor//exist:match)[1], $config) 
};

(:~
	Print the hierarchical context of a hit.
:)
declare %private function dq:print-headings($section as element()*, $docXPath as xs:string) {
	$section/ancestor-or-self::chapter/title//text(),
	for $s at $p in $section/ancestor-or-self::section
	let $nodeId := util:node-id($s)
	let $uri :=
		util:document-name(root($s)) || "?" || $docXPath || "&amp;id=D" || $nodeId || "#D" || $nodeId
	return
		(" > ", <a href="{$uri}">{$s/title//text()}</a>)
};

(:~
	Display the query results.
:)
declare %private function dq:print-results($hits as element()*, $docXPath as xs:string) {
	let $mode := request:get-parameter("view", "summary")
	return
		<div id="f-results">
			<p class="heading">Found: {count($hits)}.</p>
			{
				if ($mode eq 'summary') then
					for $section in $hits
					let $score := ft:score($section)
					order by $score descending
					return
					    <div class="section">
					        <span class="score">Score: {round-half-to-even($score, 2)}</span>
							<div class="headings">{ dq:print-headings($section, $docXPath) }</div>
							{ dq:print($section, $docXPath, $mode) }
						</div>
				else
					<table class="kwic">
					{
						for $section in $hits
						order by ft:score($section) descending
						return (
							<tr>
								<td class="headings" colspan="3">
								{dq:print-headings($section, $docXPath)}
								</td>
							</tr>,
							dq:print($section, $docXPath, $mode)
						)
					}
					</table>
			}
		</div>
};

declare %public function dq:do-query($context as node()*, $query as xs:string, $field as xs:string) {
    if (count($context) > 1) then
        switch ($field)
            case "title" return
                $context//section[ft:query(.//title, $query)]
            default return
                $context//section[ft:query(.//title, $query)] | $context//section[ft:query(., $query)]
    else
        switch ($field)
            case "title" return
                $context[.//section[ft:query(.//title, $query)]]
            default return
                $context[.//section[ft:query(.//title, $query)] or .//section[ft:query(., $query)]]
};