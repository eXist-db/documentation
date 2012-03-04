xquery version "1.0";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

let $query := request:get-parameter("q", ())
return
if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat(request:get-uri(), '/')}"/>
    </dispatch>
    
else if ($exist:path eq "/") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="documentation.xml"/>
    </dispatch>

(: Pass all requests to XML files to the data directory, then through XSLT, then through view.xql, which handles HTML templating :)
else if (ends-with($exist:resource, ".xml")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <!-- get XML file from data directory -->
        {
        if ($query) then 
            <forward url="{$exist:controller}/modules/docs-query-highlighter.xql">
				<add-parameter name="path" value="/db/doc/data/{$exist:resource}"/>
			</forward>
        else 
            <forward url="{$exist:controller}/data/{$exist:path}"/>
        }
        <view>
            <!-- pass XML file through XSLT, largely unchanged from original webapp/controller.xql's portion for documentation -->
            <forward servlet="XSLTServlet">
				<set-attribute name="xslt.stylesheet" value="{$exist:root}{$exist:controller}/stylesheets/db2xhtml.xsl"/>
			    <set-attribute name="xslt.output.media-type" value="text/html"/>
				<set-attribute name="xslt.output.doctype-public" value="-//W3C//DTD XHTML 1.0 Transitional//EN"/>
				<set-attribute name="xslt.output.doctype-system" value="resources/xhtml1-transitional.dtd"/>
				{
				if ($query) then 
        			(
        			<set-attribute name="xslt.output.add-exist-id" value="all"/>,
        		    <set-attribute name="xslt.highlight-matches" value="all"/>,
        	        <set-attribute name="xslt.xinclude-path" value=".."/>
        	        )
                else ()
				}
				<set-attribute name="xslt.root" value="."/>
			    {
			        if ($exist:resource eq 'download.xml') then
			            <set-attribute name="xslt.table-of-contents" value="'no'"/>
	                else
	                    ()
                }
			</forward>
            <!-- pass the results through view.xql -->
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

(: Pass all requests to HTML files through view.xql, which handles HTML templating :)
else if (ends-with($exist:resource, ".html")) then
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

(: Requests for javascript libraries are resolved to the file system :)
else if (contains($exist:path, "/libs/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/{substring-after($exist:path, '/libs/')}" absolute="yes"/>
    </dispatch>

(: images, css are contained in the top /resources/ collection. :)
(: Relative path requests from sub-collections are redirected there :)
else if (contains($exist:path, "/resources/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/{substring-after($exist:path, '/resources/')}"/>
    </dispatch>

else
    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </ignore>