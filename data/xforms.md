# XForms Introduction

## XForms Support in eXist-db

eXist-db has broad support for the W3C XForms standard. It offers both a client-side ([XSLTForms](http://www.agencexml.com)) and a server-side ([betterFORM](http://www.betterform.de)) implementation and thus is ideally equipped to build complete applications that use XML from front to back.

However, eXist-db will also work with other XForms processors, such as Orbeon or Chiba (the ancestor of betterFORM).

As eXist-db has support for RESTful interactions, saving XML data is as easy as using a HTTP PUT submission. For more complex tasks, you can submit your XForms instances to an XQuery, post-process them and get the results back into your form. Several examples are referred to below.

## Using betterFORM inside of eXist-db

betterFORM is a server-side W3C XForms 1.1 implementation written in Java that is closely integrated within eXist. It covers 99% of the XForms recommendation and has been extensively tested against the official XForms 1.1 Test Suite. All modern browsers are supported without the need for plugins. betterFORM can also be obtained [via Github](https://github.com/betterFORM/betterFORM) and run separately as a standard webapp. It is published under the BSD license.

With betterFORM, XHTML/XForms documents are transcoded on the server into plain (X)HTML + JavaScript. The resulting page uses an AJAX layer to keep client and server in sync and to provide an attractive user interface without the need of writing a single line of script code.

XForms processing with betterFORM is handled by a servlet filter (XFormsFilter) which nicely integrates with the URL Rewriting feature of eXist. You can use XQuery to generate your XForms markup and process it in a single request.

### Getting started

betterFORM is activated once you have installed eXist-db on your machine. By default betterFORM is configured to run XForms exclusively from the database.

To execute an XHTML/XForms document it is sufficient to store it into your database (using WebDAV or the admin client) and access it via the REST interface.

betterFORM can also be configured to listen only for a certain collection in the database or to fetch documents from the filesystem (from a directory below the webapp directory) by changing the filter mapping in webapp/WEB-INF/web.xml.

                            
    <filter-mapping>
        <filter-name>XFormsFilter</filter-name>
        <url-pattern>/apps/*</url-pattern>
    </filter-mapping>
    <filter-mapping>
        <filter-name>XFormsFilter</filter-name>
        <servlet-name>XFormsPostServlet</servlet-name>
    </filter-mapping>
    <filter-mapping>
        <filter-name>XQueryURLRewrite</filter-name>
        <url-pattern>/*</url-pattern>
    </filter-mapping>                                                

                        

### betterFORM Add-ons

To ease the work with betterFORM it is highly recommended to install the betterFORM dashboard along with the FeatureExplorer and the demo application.

-   [**Dashboard**]({bf-XForms}/) is a simple browser to your database. It allows you to navigate the collections and shows all the containing files. It has a source code view and allows you to upload a file into the database and to create collections.

-   [**FeatureExplorer**]({bf-XForms}/reference/FeatureExplorer.xhtml) is the live documentation of betterFORM. It is itself an XForms document that offers a navigation menu with links to many sample XForms that show working examples along with relevant links to the XForms Spec. A live CSS reference helps with styling forms by showing all available CSS classes.

## Using XSLTForms inside of eXist

eXist directly supports XForms via Alain Couthures' [XSLTForms](http://www.agencexml.com) processor. XSLTForms implements the XForms standard within the browser and is thus easy to integrate. XSLTForms transforms the XForms XML into an XHTML page with JavaScript that can process XForms.

### Using XSLTForms inside of eXist

XSLTForms mainly consists of two components:

-   the XSLT stylesheet `xsltforms.xsl`, which transforms the XForms markup into HTML and JavaScript understood by the browser

-   a JavaScript library, `xsltforms.js`

The XSLT stylesheet can either be applied **server-side** or within the **client**, i.e. the browser. To let the browser do the job, all you have to do is to prepend an XSL processing instruction to your XForms document, pointing to the `xsltforms/xsltforms.xsl` stylesheet:

                            
    <?xml-stylesheet href="xsltforms/xsltforms.xsl" type="text/xsl"?>
    <html xmlns="http://www.w3.org/1999/xhtml" xmlns:xf="http://www.w3.org/2002/xforms">
        ...
    </html>

                        

Please have a look at [hello.xml]({xsltforms-demo}/modules/form.xq?form=hello.xhtml) for a very basic example using client-side transformation.

When applying the stylesheet server-side, you need to make sure serialization parameters are correctly set. For example, you can apply the stylesheet within an [XQueryURLRewrite](urlrewrite.md) controller pipeline:

                            
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <view>
            <forward servlet="XSLTServlet">
                (: Apply xsltforms.xsl stylesheet :)
                <set-attribute name="xslt.stylesheet"
                    value="xsltforms/xsltforms.xsl"/>
                <set-attribute name="xslt.output.omit-xml-declaration" value="yes"/>
                <set-attribute name="xslt.output.indent" value="no"/>
                <set-attribute name="xslt.output.media-type" value="text/html"/>
                <set-attribute name="xslt.output.method" value="xhtml"/>
                <set-attribute name="xslt.baseuri" value="xsltforms/"/>
                <set-attribute name="xslt.xsltforms_home" value="webapp/xforms/xsltforms/"/>
            </forward>
        </view>
    <cache-control cache="yes"/>
    </dispatch>
                        

It is important to set the `indent` serialization parameter to "no", otherwise you'll get JavaScript errors when viewing the page. Also, if you apply the stylesheet server-side, make sure you remove the processing instruction from the source file, or the browser will try to run the stylesheet as well (which most likely leads to errors).

### Known Issues

When you load an XForms document through eXist's REST interface, when the REST server finds an xsl-stylesheet processing instruction in the document, it tries to apply the referenced stylesheet server-side. Unfortunately, the default serialization settings of the REST interface set `indent="yes"`, which leads to problems with the XForms JavaScript library.

As a workaround, you can append a request parameter `?_indent=no` to the REST URI. However, the recommended approach would be to use XQueryURLRewrite to properly handle those requests and apply the stylesheet.

## Disabling betterFORM

Under certain conditions, e.g. when XSLTforms is used, the betterFORM engine needs to be disabled. This can be done in two ways:

-   Per request by setting a HTTP attribute: request:set-attribute("betterform.filter.ignoreResponseBody", "true")

-   System global by editing `$EXIST_HOME/webapp/WEB-INF/betterform-config.xml`: &lt;property name="filter.ignoreResponseBody" value="false"&gt; change the property `filter.ignoreResponseBody` to value `true` and restart eXist-db.

## Additional XForms Resources

### XForms examples running in eXist

-   XSLT [Examples]({xsltforms-demo}/)

-   betterFORM [Examples]({bf-XForms}/)

### Mailing Lists

-   [XSLTForms mailing list](https://lists.sourceforge.net/lists/listinfo/xsltforms-support)

-   [betterFORM Users mailing list](https://lists.sourceforge.net/lists/listinfo/betterform-users)

-   [betterFORM Developers mailing list](https://lists.sourceforge.net/lists/listinfo/betterform-developer)

### XForms Specification

-   [XForms v1.1 (W3C Recommendation)](http://www.w3.org/TR/xforms/)

### Useful

-   [betterFORM Blog](http://betterform.wordpress.com)

-   [betterFORM Issue Tracking](https://betterform.de/trac)

-   [betterFORM homepage](http://betterform.de)

-   [betterFORM@github](https://github.com/betterFORM/betterFORM) - source code available here

-   [betterFORM coverage](http://betterform.de/reports/Firefox-3.0-Mac-OS-X-10.6-ConformanceReport1.1.html) of W3C XForms 1.1 Test Suite

-   [XForms Wikibook](http://en.wikibooks.org/wiki/XForms) is a useful place to learn XForms

-   [XRX Wikibook](http://en.wikibooks.org/wiki/XRX) about XML application building

-   [XSLTForms Wikibook](http://en.wikibooks.org/wiki/XSLTForms) provides specific information on XSLTForms

-   [XSLTForms coverage](http://www.agencexml.com/xforms-tests/testsuite/XForms1.1/Edition1/driverPages/html/) of W3C test suite
