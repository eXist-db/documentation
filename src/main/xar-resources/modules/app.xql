xquery version "3.1";

module namespace app = "http://exist-db.org/apps/docs/app";

import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace config = "http://exist-db.org/xquery/apps/config" at "config.xqm";

declare namespace expath = "http://expath.org/ns/pkg";

declare function app:bread-nav($node as node(), $model as map(*)) as element(nav) {
    let $uri := tokenize(request:get-uri(), '/')[position() = last()]
    let $file :=
                if (contains($uri, '.'))
                then (substring-before($uri, '.'))
                else ($uri)


    return
    <nav aria-label="breadcrumb">
        <ol class="breadcrumb">
            <li class="breadcrumb-item"><a href="documentation" data-toggle="popover" title="Version: {data($config:expath-descriptor//@version)}">Home</a></li>
            <li class="breadcrumb-item"><a href="#">{$file}</a></li>
        </ol>
    </nav>
};
