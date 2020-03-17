xquery version "1.0";

(:~
  Main controller for the eXist documentation app. 
:)

(:============================================================================:)
(:== SETUP: ==:)

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";

import module namespace config = "http://exist-db.org/xquery/apps/config" at "modules/config.xqm";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

(: Make sure we have a correct resource name. If this thing has no extension, amend it with .xml: :)
declare variable $resource-name as xs:string := if (contains($exist:resource, '.')) then
  $exist:resource
else
  concat($exist:resource, '.xml');

(: Find out whether the resource has a path component: :)
declare variable $has-path as xs:boolean :=
let $path-no-leading-slash := if (starts-with($exist:path, '/')) then
  substring($exist:path, 2)
else
  $exist:path
return
  contains($path-no-leading-slash, '/');

(:============================================================================:)
(:== MAIN: ==:)

(: No path at all? End it with a /: :)
if ($exist:path eq '') then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <redirect url="{concat(request:get-uri(), '/')}"/>
  </dispatch>
  
  (: A path that simply ends with a / goes to the main documentation page: :)
else
  if ($exist:path eq "/") then
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
    
    (: Pass all requests to XML files through to view.xql, which handles HTML templating 
       Request that contain a path are supposed to be resources and not handled here.
    :)
  else
    if (ends-with($resource-name, ".xml") and not($has-path)) then
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
      
      (: Pass all requests to HTML files through view.xql, which handles HTML templating :)
    else
      if (ends-with($resource-name, ".html")) then
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
        
        (: Anything with /$shared/ in it points to the eXist main shared-resources app: :)
      else
        if (contains($exist:path, "/$shared/")) then
          <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}"/>
          </dispatch>
          
          (: Shared images, css, etc. are contained in the top /resources/ collection. :)
        (:else
          if (starts-with($exist:path, "/resources/")) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
              <forward url="{$exist:controller}/resources/{substring-after($exist:path, '/resources/')}"/>
            </dispatch>:)
            
            (: Final catch-all: :)
          else
            <ignore xmlns="http://exist.sourceforge.net/NS/exist">
              <cache-control cache="yes"/>
            </ignore>
