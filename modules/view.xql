xquery version "3.0";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";

(: The following modules provide functions which will be called by the templating :)
import module namespace dq="http://exist-db.org/xquery/documentation/search" at "search.xql";
import module namespace docbook="http://docbook.org/ns/docbook" at "docbook.xql";

declare option exist:serialize "method=html5 media-type=text/html";

let $lookup := function($functionName as xs:string, $arity as xs:int) {
    try {
        function-lookup(xs:QName($functionName), $arity)
    } catch * {
        ()
    }
}
let $content := request:get-data()
return
    templates:apply($content, $lookup, ())
