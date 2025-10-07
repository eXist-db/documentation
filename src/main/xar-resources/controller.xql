xquery version "1.0";

(:~
  Main controller for the eXist documentation app. 
:)

(:============================================================================:)
(:== SETUP: ==:)

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace config = "http://exist-db.org/xquery/apps/config" at "modules/config.xqm";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $local:method := lower-case(request:get-method());
declare variable $local:is-get := $local:method eq 'get';

(: Make sure we have a correct resource name. If this thing has no extension, amend it with .xml: :)
declare variable $resource-name as xs:string :=
    if (contains($exist:resource, '.')) then (
        $exist:resource
    ) else (
        concat($exist:resource, '.xml')
    )
;

(: Find out whether the resource has a path component: :)
declare variable $has-path as xs:boolean :=
    let $path-no-leading-slash :=
        if (starts-with($exist:path, '/')) then (
            substring($exist:path, 2)
        ) else (
            $exist:path
        )

    return
        contains($path-no-leading-slash, '/')
;

(:============================================================================:)
(:== MAIN: ==:)

if ($exist:path eq '') then (
    (: No path at all? Append a slash :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat(request:get-uri(), '/')}"/>
    </dispatch>
) else if ($local:is-get and $exist:path eq "/") then (
    (: A path that simply ends with a / goes to the main documentation page: :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/templates/content.html"/>
        <view>
            <!-- pass the results through view.xql -->
            <forward url="{$exist:controller}/modules/view.xql">
                <add-parameter name="doc" value="{config:get-resource-path($config:data-root, 'documentation.xml')}"/>
                <set-attribute name="$exist:prefix" value="{$exist:prefix}"/>
                <set-attribute name="$exist:controller" value="{$exist:controller}"/>
            </forward>
        </view>
        <error-handler>
            <forward url="{$exist:controller}/error-page.html" method="get"/>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </error-handler>
    </dispatch>
) else if ($local:is-get and ends-with($resource-name, ".xml") and not($has-path)) then (
    (: Pass all requests to XML files through to view.xql, which handles HTML templating 
       Request that contain a path are supposed to be resources and not handled here.
    :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/templates/content.html"/>
        <view>
            <!-- pass the results through view.xql -->
            <forward url="{$exist:controller}/modules/view.xql">
                <add-parameter name="doc" value="{config:get-resource-path($config:data-root, $resource-name)}"/>
                <set-attribute name="$exist:prefix" value="{$exist:prefix}"/>
                <set-attribute name="$exist:controller" value="{$exist:controller}"/>
            </forward>
        </view>
        <error-handler>
            <forward url="{$exist:controller}/error-page.html" method="get"/>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </error-handler>
    </dispatch>
) else if ($local:is-get and ends-with($resource-name, ".html")) then (
    (: Pass all requests to HTML files through view.xql, which handles HTML templating :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <view>
            <forward url="{$exist:controller}/modules/view.xql">
                <set-attribute name="$exist:prefix" value="{$exist:prefix}"/>
                <set-attribute name="$exist:controller" value="{$exist:controller}"/>
            </forward>
        </view>
        <error-handler>
            <forward url="{$exist:controller}/error-page.html" method="get"/>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </error-handler>
    </dispatch>
) else if ($local:is-get and matches($exist:path, "^/data/.+\.(png|jpg|jpeg|gif|svg)$")) then (
    (: article assets like screenshots and diagrams :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}{$exist:path}">
            <set-header name="Cache-Control" value="max-age=73600; must-revalidate;"/>
        </forward>
    </dispatch>
) else if ($local:is-get and matches($exist:path, "/resources/(styles|fonts|images|scripts|svg)/.+")) then (
    (: static page assets like images, fonts, styles and scripts :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}{$exist:path}">
            <set-header name="Cache-Control" value="max-age=73600; must-revalidate;"/>
        </forward>
    </dispatch>
) else (
    response:set-status-code(404),
    <data>Not Found</data>
)
