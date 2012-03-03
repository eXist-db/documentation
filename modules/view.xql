xquery version "1.0";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";

declare option exist:serialize "method=html5 media-type=text/html";

declare variable $modules :=
    <modules>
        <module prefix="docs" uri="http://exist-db.org/apps/docs" at="docs.xql"/>
    </modules>;

let $content := request:get-data()
return
    templates:apply($content, $modules, ())