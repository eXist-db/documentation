xquery version "3.1";


import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace lib="http://exist-db.org/xquery/html-templating/lib";

(: The following modules provide functions which will be called by the templating :)
import module namespace dq="http://exist-db.org/xquery/documentation/search" at "search.xql";
import module namespace docbook="http://docbook.org/ns/docbook" at "docbook.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace review="http://exist-db.org/xquery/documentation/review" at "review.xql";
import module namespace diag="http://exist-db.org/xquery/diagnostics" at "diagnostics.xql";
import module namespace app="http://exist-db.org/apps/docs/app" at "app.xql";


declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

declare function local:lookup ($functionName as xs:string, $arity as xs:integer) {
    function-lookup(xs:QName($functionName), $arity)
};

declare variable $local:templating-configuration := map {
    $templates:CONFIG_FILTER_ATTRIBUTES : true(),
    $templates:CONFIG_USE_CLASS_SYNTAX : false(),
    $templates:CONFIG_APP_ROOT : $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR : true()
};

templates:apply(
    request:get-data(),
    local:lookup#2,
    (),
    $local:templating-configuration
)
