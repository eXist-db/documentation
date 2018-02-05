xquery version "3.0";

(:============================================================================:)
(:== SETUP: ==:)

module namespace docbook="http://docbook.org/ns/docbook";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace dq="http://exist-db.org/xquery/documentation/search" at "search.xql";

declare namespace db5="http://docbook.org/ns/docbook";

declare variable $docbook:INLINE := 
    ("filename", "classname", "methodname", "option", "command", "parameter", "guimenu", "guimenuitem", "guibutton", "function", "envar");

(:============================================================================:)
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
                map { "doc" := util:expand($data/*, "add-exist-id=all") }
        else
            <p>Document not found: {$path}!</p>
};

(:----------------------------------------------------------------------------:)

(:~
 : Transform the docbook fragment given in $model.
 :)
declare %public function docbook:to-html($node as node(), $model as map(*)) {
    docbook:to-html($model("doc"))
};

(:----------------------------------------------------------------------------:)

(:~
 : Generate a table of contents.
 :)
declare %public function docbook:toc($node as node(), $model as map(*)) {
  let $root as element() := $model("doc")
  return
    <div>
      <h3>Contents</h3>
      { 
        if (namespace-uri($root) eq "http://docbook.org/ns/docbook")
          then docbook:toc-db5($root)
          else docbook:print-sections-db4($root/*/(chapter|section)) 
      }
    </div>
};

(:============================================================================:)
(:== GENERIC DISPATCHER FUNCTIONS BETWEEN DB4/DB5: ==:)

declare %private function docbook:to-html($nodes as node()*) {
  for $node in $nodes
  return
    if (namespace-uri($node) eq "http://docbook.org/ns/docbook")
    then docbook:to-html-db5($node)
    else docbook:to-html-db4($node)
};

(:============================================================================:)
(:== DB5 HANDLING: ==:)

declare %private function docbook:toc-db5($node as node()) {
  let $uri-xsl := concat('xmldb:exist://', $config:app-root, '/modules/xsl/convert-db5-toc.xsl')
  let $parameters as element(parameters)? := () 
  return
    transform:transform($node, $uri-xsl, $parameters)
};

(:----------------------------------------------------------------------------:)

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
(:<p>XX</p>:)
};

(:============================================================================:)
(:== DB4 HANDLING: ==:)

declare %private function docbook:print-sections-db4($sections as element()*) {
    if ($sections) then
        <ul class="toc">
        {
            for $section in $sections
            let $id := if ($section/@id) then $section/@id else concat("D", $section/@exist:id)
            return
                <li>
                    <a href="#{$id}">{ $section/title/text() }</a>
                    { docbook:print-sections-db4($section/(chapter|section)) }
                </li>
        }
        </ul>
    else
        ()
};

(:----------------------------------------------------------------------------:)

declare %private function docbook:to-html-db4($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            
            (: Main sections: :)
            case element(book) return
                <article>
                    {docbook:process-children($node/chapter)}
                </article>
            case element(article) return
                <article>
                    {docbook:process-children($node/section)}
                </article>
            case element(chapter) return
                <section>
                {docbook:process-children($node)}
                </section>
            case element(section) return
                if ($node/@role = "media-object") then
                    docbook:media($node)
                else
                    <section>
                        <a name="D{$node/@exist:id}"></a>
                        {docbook:process-children($node)}
                    </section>
                    
            case element(abstract) return
                <blockquote>{docbook:process-children($node)}</blockquote>
            case element(title) return
                let $level := count($node/(ancestor::chapter|ancestor::section))
                return
                    element { "h" || $level } {
                        if ($level = 1) then
                            attribute class { "front-title" }
                        else
                            (),
                        if ($node/../@id) then
                            <a name="{$node/../@id}"></a>
                        else
                            <a name="D{$node/../@exist:id}"></a>,
                        docbook:process-children($node)
                    }
                    
            case element(para) return
                <p>{docbook:process-children($node)}</p>
            case element(emphasis) return
                <em>{docbook:process-children($node)}</em>
            case element(itemizedlist) return
                <ul>{docbook:to-html($node/listitem)}</ul>
            case element(orderedlist) return
                <ol>{docbook:to-html($node/listitem)}</ol>
            case element(listitem) return
                if ($node/parent::varlistentry) then
                    docbook:process-children($node)
                else
                    <li>{docbook:process-children($node)}</li>
            case element(variablelist) return
                let $spacing := $node/@spacing
                return
                    <dl class="dl-horizontal {if ($spacing = 'normal') then 'wide' else ''}">{docbook:process-children($node)}</dl>
            case element(varlistentry) return (
                <dt>{docbook:process-children($node/term)}</dt>,
                <dd>{docbook:to-html($node/listitem)}</dd>
            )
            case element(figure) return
                if ($node/@role = "media-object") then
                    docbook:media($node)
                else
                    docbook:figure($node)
            case element(screenshot) return
                docbook:figure($node)
            case element(example) return
                docbook:figure($node)
            case element(screen) return
                docbook:code($node)
            case element(graphic) return
                let $align := $node/@align
                let $class := if ($align) then "img-float-" || $align else ()
                return
                    <img src="{docbook:get-resource-uri(string($node/@fileref))}">
                    { if ($class) then attribute class { $class } else () }
                    { if ($node/@width) then attribute width { $node/@width } else () }
                    </img>
            case element(mediaobject) return
                docbook:process-children($node)
            case element(imageobject) return
                docbook:process-children($node)
            case element(imagedata) return
                let $align := $node/@align
                let $class := if ($align) then "img-float-" || $align else ""
                return
                    <img src="{docbook:get-resource-uri(string($node/@fileref))}" class="{$class}"/>
            case element(videodata) return
                let $align := $node/@align
                let $class := if ($align) then "img-float-" || $align else ""
                return
                    <iframe width="{$node/@width}" height="{$node/@depth}" src="{docbook:get-resource-uri(string($node/@fileref))}" frameborder="0" allowfullscreen="yes"/>
            case element(ulink) return
                if ($node/@condition = '_blank')
                then
                    <a href="{$node/@url}" target="_blank">{docbook:process-children($node)}</a>
                else
                    <a href="{$node/@url}">{docbook:process-children($node)}</a>
            case element(xref) return
                <a href="#{$node/@linkend}">{root($node)/*//*[@id = $node/@linkend]/title/text()}</a>
            case element(note) return
                <div class="alert alert-success">
                {
                    if ($node/title) then
                        <h2>Note: { docbook:to-html($node/title/node()) }</h2>
                    else
                        ()
                }
                { docbook:to-html($node/* except $node/title) }
                </div>
            case element(important) return
                <div class="alert alert-error">
                    <h2>Important</h2>
                    { docbook:process-children($node) }
                </div>
            case element(synopsis) return
                docbook:code($node)
            case element(programlisting) return
                docbook:code($node)
            case element(procedure) return
                <div class="procedure">
                    <ol>
                    {docbook:process-children($node)}
                    </ol>
                </div>
            case element(step) return
                <li>{docbook:process-children($node)}</li>
            case element(filename) return
                <code>{docbook:process-children($node)}</code>
            case element(toc) return
                <ul class="toc">
                {docbook:process-children($node)}
                </ul>
            case element(tocpart) return
                <li>{docbook:process-children($node)}</li>
            case element(tocentry) return
                docbook:process-children($node)
            
            case element(guimenuitem) return
                <span class="guimenuitem">{docbook:process-children($node)}</span>
            case element(guibutton) return
                <span class="label label-primary">{docbook:process-children($node)}</span>
            case element(sgmltag) return
                <span class="sgmltag">&lt;{docbook:process-children($node)}&gt;</span>
            case element(exist:match) return
                <span class="hi">{$node/text()}</span>
            
                
           (: Table related: :)
            case element(informaltable) return
                <table border="0" cellpadding="0" cellspacing="0">{$node/node()}</table>
            case element(table) return
                docbook:table($node)
            case element(tgroup) return
                docbook:process-children($node)
            case element(thead) return
                <thead>{docbook:process-children($node)}</thead>
            case element(tbody) return
                <tbody>{docbook:process-children($node)}</tbody>
            case element(row) return
                <tr>{docbook:process-children($node)}</tr>
            case element(entry) return
                if ($node/ancestor::thead) then 
                    <th>{docbook:process-children($node)}</th>
                else
                    <td>{docbook:process-children($node)}</td>    
            case element(col) return
                <col width="{$node/@width}">{docbook:process-children($node)}</col>
            case element(colgroup) return
                <colgroup>{docbook:process-children($node)}</colgroup>
                
            (: Defaults/General: :)  
            case element() return
                let $name := local-name($node)
                return
                    if ($name = $docbook:INLINE) then
                        <span class="{local-name($node)}">{docbook:process-children($node)}</span>
                    else
                        element { node-name($node) } {
                            $node/@*,
                            docbook:process-children($node)
                        }
            case text() return
                $node
            case document-node() return
                docbook:to-html($node/*)
            default return
                ()
};

(:----------------------------------------------------------------------------:)

declare %private function docbook:inline($node as node()) {
    <span class="{local-name($node)}">{docbook:process-children($node)}</span>
};

(:----------------------------------------------------------------------------:)

declare %private function docbook:figure($node as node()) {
    let $float := $node/@floatstyle
    return
        <figure>
            { if ($float) then attribute class { "float-" || $float } else () }
            {docbook:to-html($node/*[not(self::title)])}
            {
                if ($node/title) then
                    <figcaption>{docbook:process-children($node/title)}</figcaption>
                else
                    ()
            }
        </figure>
};

(:----------------------------------------------------------------------------:)

declare %private function docbook:media($node as element()) {
    <div class="media well">
        <a class="pull-left" href="#">
            <img class="media-object" src="{docbook:get-resource-uri(string($node/graphic/@fileref))}"/>
        </a>
        <div class="media-body">
            <h4 class="media-heading">{$node/title/text()}</h4>
            {
                for $child in $node/* except $node/title except $node/graphic
                return
                    docbook:to-html($child)
            }
        </div>
    </div>
};

(:----------------------------------------------------------------------------:)

declare %private function docbook:table($node as node()) {
    <table class="table table-striped table-condensed">{if ($node/@border) then attribute border {$node/@border} else () }
        {docbook:to-html($node/*[not(self::title)])}
        {
            if ($node/title) then
                <caption>{docbook:process-children($node/title)}</caption>
            else
                ()
        }
    </table>
};

(:----------------------------------------------------------------------------:)

declare %private function docbook:code($elem as element()) {
    let $lang := 
        if ($elem//markup) then
            "xml"
        else if ($elem/@language) then
            $elem/@language
        else
            ()
    return
        if ($lang) then
            <div class="code" data-language="{$lang}">
            { replace($elem/string(), "^\s+", "") }
            </div>
        else
            <pre>{ replace($elem/string(), "^\s+", "") }</pre>
};

(:----------------------------------------------------------------------------:)

declare %private function docbook:process-children($elem as element()+) {
    for $child in $elem/node()
    return
        docbook:to-html-db4($child)
};

(:----------------------------------------------------------------------------:)

declare %private function docbook:print-authors($root as element()) {
(: NOT USED? :)
    <div class="authors">
    {
        for $author in $root/bookinfo/author
        return
            <address>
                <strong>{$author/firstname} {$author/surname}</strong>
                { for $jobtitle in $author/jobtitle return (<br/>, $author/jobtitle/text()) }
                { for $orgname in $author/orgname return (<br/>, $author/orgname/text()) }
                { for $email in $author/email return (<br/>, <a href="mailto:{$author/email}">{$author/email/text()}</a>) }
            </address>
    }
    </div>
};

(:----------------------------------------------------------------------------:)

declare %private function docbook:get-resource-uri($ref as xs:string) as xs:string {
  let $prefix-path := if (starts-with($ref, '/'))
  then replace($config:app-root, '/db/', '/')
  else concat($config:data-root-rel, '/', replace(request:get-parameter('doc', ()), '(.*)[/\\][^/\\]+$', '$1'))
  return 
    concat($prefix-path, '/', $ref)
};

(:============================================================================:)
(:==  ==:)
