xquery version "3.0";
(:============================================================================:)
(:==
  Module for the link diagnostics of the documentation articles.

  To see the report navigate to …/diagnostics.html 

  This is not very performant code but it doesn't matter much here. Will only be run rarely.
==:)
(:============================================================================:)
(:== PROLOG: ==:)

module namespace diag="http://exist-db.org/xquery/diagnostics";

import module namespace rvds="http://exist-db.org/xquery/rvd-support" at "rvd-support.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare namespace db5="http://docbook.org/ns/docbook";
declare namespace xlink="http://www.w3.org/1999/xlink";

declare variable $diag:link-article as xs:string := 'Article' ;
declare variable $diag:link-external as xs:string := 'External' ;
declare variable $diag:link-resource as xs:string := 'Resource' ;
declare variable $diag:link-computed as xs:string := 'Computed' ;
declare variable $diag:link-unknown as xs:string := 'Unknown' ;

declare variable $diag:error-prompt as item()* := <span style="color:red; font-weight:bold;">*ERROR* </span>;
declare variable $diag:ok-prompt as item()* := <span style="color:green; font-weight:bold;">OK </span>;

(:============================================================================:)
(:== PUBLIC FUNCTIONS: ==:)

declare function diag:diagnose($node as node(), $model as map(*)) as element()*
{
  <p>Data root: <code>{$config:data-root}</code></p>,
  <p>All errors are marked with {$diag:error-prompt} so you can search on it.</p>,
  <ul>
  {
    for $doc in collection($config:data-root)[exists(db5:article)]
    order by base-uri($doc)
    let $uri as xs:string := string(base-uri($doc))
    return
      <li>
      {
        <h3><code>{substring-after($uri, $config:data-root || '/')}</code></h3>,
        local:diagnose-document($doc)
      }
      </li>
  }
  </ul>
};

(:============================================================================:)
(:== LOCALS: ==:)

declare function local:diagnose-document($doc as document-node()) as element()*
{
  (: Create a table with all outgoing links and analyze them: :)
  <table border="1">
  <tr>
    <th>Link</th>
    <th>Type</th>
    <th>Status</th>
  </tr>
  {
    for $link in distinct-values(data($doc//@xlink:href))
    order by $link
    let $link-type := rvds:get-link-type($link)
    return
     <tr>
       <td> <code>{$link}</code> </td>
       <td> {$link-type} </td>
       <td>
       {
          switch ($link-type)
            case $diag:link-resource return local:check-link-resource($doc, $link)
            case $diag:link-article return local:check-link-article($doc, $link)
            case $diag:link-external return 'Not checked'
            case $diag:link-computed return 'Not checked'
            case $diag:link-unknown return 'Not checked'
            default return ($diag:error-prompt, 'Unrecognized link type')
       }
       </td>
     </tr>
  }
  </table>,

  <p>&#160;</p>,

  (: Create a table with all resources underneath where the document is stored and check whether they're used: :)
  <table border="1">
    <tr>
      <th>Resource</th>
      <th>Used</th>
    </tr>
    {
      let $base-collection as xs:string := rvds:get-path-component(string(base-uri($doc)))
      for $rel-resource-link in local:get-relative-resource-links($base-collection, ())
      order by $rel-resource-link
      return
        <tr>
          <td><code>{$rel-resource-link}</code></td>
          <td>
          {
            if (local:resource-link-exists($doc, $rel-resource-link))
              then $diag:ok-prompt
              else ($diag:error-prompt, ' Not referenced')
          }
          </td>
        </tr>
    }
  </table>
};

(:----------------------------------------------------------------------------:)

declare function local:get-relative-resource-links($collection-abs as xs:string, $collection-rel as xs:string?) as xs:string*
(: Get a list of all (relative) resource links underneath (not in) a collection: :)
{
  for $sub-collection in xmldb:get-child-collections($collection-abs)
    let $sub-collection-abs as xs:string := $collection-abs || '/' || $sub-collection
    let $sub-collection-rel as xs:string := $collection-rel || (if (empty($collection-rel)) then '' else '/') || $sub-collection
    return
    (
      for $resource in xmldb:get-child-resources($sub-collection-abs)
        return $sub-collection-rel || '/' || $resource,
      local:get-relative-resource-links($sub-collection-abs, $sub-collection-rel)
    )
};

(:----------------------------------------------------------------------------:)

declare function local:resource-link-exists($doc as document-node(), $rel-link as xs:string) as xs:boolean
(: Rough computation whether a resource is referenced in a document: :)
{
  $rel-link = (data($doc//@xlink:href), data($doc//@fileref))
};

(:----------------------------------------------------------------------------:)

declare function local:check-link-resource($from as document-node(), $link as xs:string) as item()*
(: Checks whether a link to a resource actulaly exists: :)
{
  let $full-collection := util:collection-name($from) || '/' || rvds:get-path-component($link)
  return
    if (xmldb:collection-available($full-collection))
      then
        if (rvds:get-name-component($link) = xmldb:get-child-resources($full-collection))
          then $diag:ok-prompt
          else ($diag:error-prompt, <code>{$link}</code>, ' not found')
      else ($diag:error-prompt, 'Collection ', <code>{$full-collection}</code>, ' not found')
};

(:----------------------------------------------------------------------------:)

declare function local:check-link-article($doc as document-node(), $link as xs:string) as item()*
(: Checks whether a link to some other article is ok (including its anchor): :)
{
  let $link-no-anchor := rvds:link-no-anchor($link)
  let $anchor := rvds:link-anchor($link)
  let $full-name as xs:string := if (contains($link-no-anchor, '.')) then $link-no-anchor else $link-no-anchor || '.xml'
  let $relative-link-to-article as xs:string? := config:get-resource-path($config:data-root, $full-name)
  let $absolute-link-to-article as xs:string := $config:data-root || '/' || $relative-link-to-article
  let $full-article as document-node()? := if ($link-no-anchor eq '')
    then $doc
    else doc($absolute-link-to-article)
  return
    if ($link-no-anchor eq '' or exists($relative-link-to-article))
      then
      (
        $diag:ok-prompt,
        if ($anchor eq '')
          then ()
          else
          (
            '(doc) ',
            if (rvds:anchor-exists($full-article, $anchor))
              then $diag:ok-prompt
              else $diag:error-prompt,
            ' (anchor)'
          )
      )
      else ($diag:error-prompt, <code>{$full-name}</code>, ' not found')
};

(:============================================================================:)
