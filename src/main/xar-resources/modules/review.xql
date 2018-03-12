xquery version "3.0";
(:============================================================================:)
(:== 
  Module for creating an editorial overview page.
==:)
(:============================================================================:)
(:== PROLOG: ==:)

module namespace review = "http://exist-db.org/xquery/documentation/review";


import module namespace rvds="http://exist-db.org/xquery/rvd-support" at "rvd-support.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare namespace db5="http://docbook.org/ns/docbook";
declare namespace xlink="http://www.w3.org/1999/xlink";

declare variable $review:all-docs as document-node()* := collection($config:data-root)[exists(db5:article)][not(contains(base-uri(.), '/listings/'))];

(:============================================================================:)
(:== PUBLIC FUNCTIONS: ==:)

declare %public function review:editorial-view($node as node()*, $model as map(*)) {
  <div>
    <table border="1">
      <tr>
        <th>Location</th>
        <th>Title</th>
        <th>Date</th>
        <th>Keywords</th>
        <th>~#words</th>
        <th>Linked from</th>
        <th>Links to</th>
      </tr>
      {
        for $doc in $review:all-docs
        order by base-uri($doc)
        let $uri as xs:string := string(base-uri($doc))   
        let $info as element() := $doc/*/db5:info
        return
          <tr valign="top">
            <td>
            <a href="{rvds:get-name-component($uri)}" target="_blank">{substring-after($uri, $config:data-root || '/')}</a></td>
            <td>{data($info/db5:title)}</td>
            <td>{data($info/db5:date)}</td>
            <td>
            {
              for $kw in $info/db5:keywordset/db5:keyword
              order by $kw
              return ($kw, <br/>)
            }
            </td>
            <td>{count(tokenize(string($doc), '\s+'))}</td>
            <td>
            {
              for $article in local:get-incoming-links($uri)
              let $uri := base-uri($article)
              order by $uri
              let $name := rvds:get-name-component($uri)
              return
                (<a href="{$name}" target="_blank">{substring-before($name, '.xml')}</a>, <br/>)
            }
            </td>
            <td>
            {
              for $link in distinct-values(data($doc//db5:link/@xlink:href))
              order by $link
              let $linktype := rvds:get-link-type($link)
              return 
                if ($linktype = ($rvds:link-article, $rvds:link-external))
                then (<a href="{$link}" target="_blank">{$link}</a>, <br/>)
                else ()
            }
            </td>
            
            
          </tr>
      }
    </table>
  </div>
};

(:============================================================================:)
(:== /TBD/ ==:)

declare function local:get-incoming-links($uri as xs:string) as item()*
{
  for $article in $review:all-docs[local:has-link-to(., $uri)] 
  order by base-uri($article)
  return $article
};

(:----------------------------------------------------------------------------:)

declare function local:has-link-to($doc as document-node(), $uri as xs:string) as xs:boolean
{
  let $name := substring-before(rvds:get-name-component($uri), '.xml')
  return $name = local:get-article-links-out($doc)
};

(:----------------------------------------------------------------------------:)

declare function local:get-article-links-out($doc as document-node()) as xs:string*
(: Returns a sequence of outgoing article links. Article resource name only, no .xml. :)
{
  for $link in data($doc//db5:link/@xlink:href)
  let $linktype := rvds:get-link-type($link)
  return
    if ($linktype ne $rvds:link-article)
    then ()
    else 
      if (ends-with($link, '.xml'))
      then substring-before($link, '.xml')
      else $link
};

(:----------------------------------------------------------------------------:)


