xquery version "3.0";


import module namespace config = "http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace templates = "http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace dq = "http://exist-db.org/xquery/documentation/search" at "search.xql";

declare namespace db5 = "http://docbook.org/ns/docbook";

declare variable $INLINE :=
("filename", "classname", "methodname", "option", "command", "parameter", "guimenu", "guimenuitem", "guibutton", "function", "envar");

declare variable $test-doc := doc($config:data-root || "/backup/backup.xml");

declare %private function local:toc-db5($node as node()) as element(ul) {
    element ul {
        attribute class {'toc'},
        for $l1 in $node//db5:sect1
        let $l2 := $l1/db5:sect2
        return
            element li {
                element a {
                    attribute href {'#' || id($l1)},
                    $l1/db5:title/text()
                },
                if ($l2) 
                then (
                element ul {
                for $n in $l2
                return
                    element li {element a {attribute href {'#' || id($l2)}, $n/db5:title/text()}}})
                else ()
            }
    }
};

declare %private function local:missing-id() { 

(:
ant-tasks.xml                               x
author-reference.xml                       x
backup.xml                                  
beginners-guide-to-xrx-v4.xml
contentextraction.xml
dashboard.xml
deployment.xml
development-starter.xml
devguide_codereview.xml
devguide_indexes.xml
devguide_log4j.xml
devguide_manifesto.xml
devguide_rest.xml
devguide_soap.xml
devguide_xmldb.xml
devguide_xmlrpc.xml
documentation.xml
extensions.xml
faq_performance.xml
getting-help-how-to-report.xml
http-request-session.xml
indexing.xml
jmx.xml
kwic.xml
learning-xquery.xml
lucene.xml
newrangeindex.xml
ngram.xml
oldrangeindex.xml
production_good_practice.xml
production_web_proxying.xml
repo.xml
scheduler.xml
structure.xml
templating.xml
triggers.xml
tuning.xml
urlrewrite.xml
using-collections.xml
versioning.xml
xforms.xml
xinclude.xml
xqdoc.xml
xqsuite.xml
xsl-transform.xml
:)

let $no-id := distinct-values(
for $n in collection($config:data-root)//db5:article/db5:sect1
return
    if ($n/@xml:id) then ()
    else (util:document-name($n))
)

for $m in  $no-id
order by $m
return
    $m
};

local:missing-id()

(:local:toc-db5($test-doc):)