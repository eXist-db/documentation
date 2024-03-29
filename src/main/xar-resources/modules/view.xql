xquery version "3.0";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace lib="http://exist-db.org/xquery/html-templating/lib";

(: The following modules provide functions which will be called by the templating :)
import module namespace dq="http://exist-db.org/xquery/documentation/search" at "search.xql";
import module namespace docbook="http://docbook.org/ns/docbook" at "docbook.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace review="http://exist-db.org/xquery/documentation/review" at "review.xql";
import module namespace diag="http://exist-db.org/xquery/diagnostics" at "diagnostics.xql";
import module namespace app="http://exist-db.org/apps/docs/app" at "app.xql";

declare option exist:serialize "method=html5 media-type=text/html";

let $config := map {
    $templates:CONFIG_APP_ROOT : $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR : true()
}
let $lookup := function($functionName as xs:string, $arity as xs:integer) {
    try {
        function-lookup(xs:QName($functionName), $arity)
    } catch * {
        ()
    }
}
let $content := request:get-data()
return
    templates:apply($content, $lookup, (), $config)
