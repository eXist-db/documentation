xquery version "3.1";

module namespace md="http://exist-db.org/xquery/apps/markdown-docs";

import module namespace markdown="http://exist-db.org/xquery/markdown" at "xmldb:exist:///db/apps/markdown/content/markdown.xql";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";

(:~
 : Load a markdown document.
 :)
declare 
    %public %templates:default("field", "all")
function md:load($node as node(), $model as map(*), $q as xs:string?, $doc as xs:string?, $field as xs:string) {
    let $path := $config:data-root || "/" || replace($doc, '\.md$', '.xml')
    return
        if (exists($doc) and doc-available($path)) then
            let $html := doc($path)
            return
                map { "doc": $html, "doc-title": $html//h1[1]/string() }
        else
            <p>Document not found: {$path}!</p>};

(:~
 : Transform the markdown fragment given in $model.
 :)
declare %public function md:to-html($node as node(), $model as map(*)) {
    $model("doc")
};

(:~
 : Generate a table of contents.
 :)
declare %public function md:toc($node as node(), $model as map(*)) {
    <div>
        <h3>Contents</h3>
        {
        md:print-sections($model("doc")/body/section/section)
        }
    </div>
};

declare %private function md:print-sections($sections as element()*) {
    if ($sections) then
        <ul class="toc">
        {
            for $section in $sections
            let $id := head($section/*)/@id
            return
                <li>
                    <a href="#{$id}">{ head($section/*)/text() }</a>
                    { md:print-sections($section/section) }
                </li>
        }
        </ul>
    else
        ()
};