xquery version "3.0";

(:== SETUP: ==:)

module namespace docbook="http://docbook.org/ns/docbook";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace dq="http://exist-db.org/xquery/documentation/search" at "search.xql";

declare namespace db5="http://docbook.org/ns/docbook";

declare variable $docbook:INLINE :=
    ("filename", "classname", "methodname", "option", "command", "parameter", "guimenu", "guimenuitem", "guibutton", "function", "envar");

(: PUBLIC INTERAFCE: :)

(:~
 : Load a docbook document. If a query was specified, re-run the query on the document
 : to get matches highlighted.
 :)
declare
    %public %templates:default("field", "all")
function docbook:load($node as node(), $model as map(*), $q as xs:string?, $doc as xs:string?, $field as xs:string) {
    let $path := $config:data-root || "/" || $doc
    return
        if (exists($doc) and doc-available($path)) then
            let $context := doc($path)
            let $data :=
                if ($q) then
                    dq:do-query($context, $q, $field)
                else
                    $context
            return
                map { "doc": util:expand($data/*, "add-exist-id=all") }
        else
            <p>Document not found: {$path}!</p>
};

(:~
 : Transform the docbook fragment given in $model.
 :)
declare %public function docbook:to-html($node as node(), $model as map(*)) {
    docbook:to-html($model("doc"))
};

(:~
 : Generate a table of contents.
 :)
declare %public function docbook:toc($node as node(), $model as map(*)) {
  let $root  as element() := $model("doc")
  return
    <div>
      <h3>Contents</h3>
      { docbook:toc-db5($root) }
    </div>
};

(:== GENERIC DISPATCHER FUNCTIONS BETWEEN DB4/DB5: ==:)

declare %private function docbook:to-html($nodes as node()*) {
  for $node in $nodes
  return
    docbook:to-html-db5($node)
};

(:== DB5 HANDLING: ==:)

(: Will create the TOC for the DB5 document. Will only go two levels deep (deeper is not very useful for a TOC). :)
declare %public function docbook:toc-db5($node as node()) as element(ul) {
  element ul {
        attribute class {'toc'},
        for $l1 in $node//db5:sect1
        let $l2 := $l1/db5:sect2
        return
            element li {
                element a {
                    attribute href {'#' || data($l1/@xml:id)},
                    $l1/db5:title/string()
                },
                if ($l2)
                then (
                element ul {
                for $n in $l2
                return
                    element li {element a {attribute href {'#' || data($n/@xml:id)}, $n/db5:title/string()}}})
                else ()
            },
            element button { attribute class {'btn btn-outline-primary btn-sm btn-block'},
        element a {
                    attribute href {escape-html-uri('https://github.com/eXist-db/documentation/issues/new?assignees=&amp;labels=docs-outdated&amp;template=content-issue.md&amp;title=[' || $node//db5:info/db5:title || ']:')},
                    'Improve this article'
                }
        }
    }
};

declare %private function docbook:to-html-db5($node as node()) {
  let $uri-reative-from-app as xs:string := replace($config:app-root, '/db/', '/')
  let $uri-relative-from-document as xs:string :=
    concat($config:data-root-rel, '/', replace(request:get-parameter('doc', ()), '(.*)[/\\][^/\\]+$', '$1'))
  let $uri-xsl := concat('xmldb:exist://', $config:app-root, '/modules/xsl/convert-db5.xsl')
  (: Create a content wrapper so we can include multiple inputs for the transformation: :)
  let $contents as element() :=
    <contentswrapper>
      <contents>{ $node }</contents>
      {
        if (exists($node//db5:para[contains(@role, 'index')]))
        then
          <index>
          {
            let $docroot as xs:string := $config:app-root || '/data'
            for $doc in collection($docroot)[exists(db5:article)][not(contains(base-uri(), '/listings/'))]
               return <doc ref="{base-uri($doc)}">{ $doc/*/db5:info }</doc>
          }
          </index>
        else
          ()
      }
    </contentswrapper>
  let $parameters as element(parameters) :=
    <parameters>
      <param name="uri-relative-from-app" value="{$uri-reative-from-app}"/>
      <param name="uri-relative-from-document" value="{$uri-relative-from-document}"/>
    </parameters>
  return
    transform:transform($contents, $uri-xsl, $parameters)
};
