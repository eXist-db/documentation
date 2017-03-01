# URL Rewriting and MVC Framework

## Abstract

> Since version 1.3/1.4, eXist-db provides a simple, yet powerful module for URL rewriting and redirection: XQueryURLRewrite. It also incorporates a basic MVC (Model View Controller) framework, offering servlet-based pipeline processing. The module was in part inspired by the existing Open Source packages UrlRewriteFilter and Spring MVC. The main difference is that we are not using any configuration files to configure the URL rewriting. XQueryURLRewrite is based on XQuery instead.

## Basics

XQueryURLRewrite is a standard Java servlet filter. Like any other servlet filter, it is configured in `webapp/WEB-INF/web.xml`. Its main job is to intercept incoming requests and forward them to the appropriate handlers, which are again standard servlets. In fact, there's nothing eXist-specific to the servlet filter, except that it uses XQuery scripts to configure the forwarding and URL rewriting.

A controller XQuery is executed once for every requests. It should return an XML fragment, which tells the servlet filter how to proceed with the request. The returned XML fragment may just define a simple forwarding, or it could describe complex pipelines involving multiple steps.

The main advantage of using XQuery for the controller is that we have the whole power of the language available for the URL rewriting. The controller can look at request parameters or headers, add new parameters or attributes, rewrite the request URI or access the database. There's basically no limit.

## URL Rewriting

When designing RESTful web applications, a common rule is to provide meaningful URIs to the user. For example, our eXist wiki implements a hierarchical document space. The user can directly browse to a document by entering the path to it into the browser's location bar. The URL [http://atomic.exist-db.org/HowTo/OxygenXML/eXistXmlRpcChanged](http://atomic.exist-db.org/HowTo/OxygenXML/) will directly lead to the corresponding document.

Internally, however, all document views are handled by the same XQuery script. Above URL will actually be forwarded to an XQuery called `index.xql` as follows:

index.xql?feed=HowTo/OxygenXML/&ref=eXistXmlRpcChanged
The XQuery code which does the rewrite magic is shown below:

``` xquery
        let $params := subsequence(analyze-string($exist:path, '^/?(.*)/([^/]+)$')//fn:group, 2)
        (: the deprecated text module is not available anymore in eXist-db 3.0
           analyze-string() can used whereever text:groups() was used before :)
        (: subsequence(text:groups($exist:path, '^/?(.*)/([^/]+)$'), 2) :)
return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/index.xql">
            <add-parameter name="feed" value="{$params[1]}"/>
            <add-parameter name="ref" value="{$params[2]}"/>
        </forward>
    </dispatch>
```

The forward element tells XQueryURLRewrite to pass the request to the specified URL. You could also forward to a servlet instead of an URL by specifying its name (servlet="ServletName"). The forwarding is done via the `RequestDispatcher` of the servlet engine and is thus invisible to the user.

Relative URLs within forward or redirect elements are interpreted relative to the request URI, absolute paths relative to the root of the current controller hierarchy. If the controller which processes the request is stored in the db, all absolute and relative paths will be resolved against the db as well. This is explained in more detail below.

If you want the user to see the rewritten URL, you can replace the forward action with a redirect. A common use for redirect is to send the user to a default page:

``` xquery
if ($exist:path eq '/') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.xml"/>
    </dispatch>
```

If no action is specified within the dispatch element, the request will just be passed through the filter chain and will be handled the normal way. The same happens if the action is an element ignore. For example, the simplest controller script would consist of a single ignore:

``` xml
        <ignore xmlns="http://exist.sourceforge.net/NS/exist">
            <cache-control cache="yes"/>
        </ignore>
```

Most scripts in eXist-db return this if no other rule applies to a request.

> **Note**
>
> It is important to understand that only one (!) controller will ever be applied to a given request. It is not possible to forward from one controller to another (or the same). Once you either ignored or forwarded a request in the controller, it will be directly passed to the servlet which handles it or - if it references a resource - it will be processed by the servlet engine itself. The controller will not be called again for the same request.
>
> Redirects are different in this respect: they cause the client (the web browser) to send a second request and this will again be filtered by XQueryURLRewrite. It is thus possible to create redirect loops.

## Variables

Within a controller.xql file, you have access to the entire XQuery function library, including the functions in the request, response and session modules. You could thus use a function like `request:get-uri()` to get the current URI of the request. However, to simplify things, XQueryURLRewrite passes a few variables to the controller script:

exist:path  
The last part of the request URI after the section leading to the controller. If the resource `example.xml` resides within the same directory as the controller query, `$exist:path` will be `/example.xml`.

exist:resource  
The section of the URI after the last `/`, usually pointing to a resource, e.g. `example.xml`.

exist:controller  
The part of the URI leading to the current controller script. For example, if the request path is `/xquery/test.xql` and the controller is in the `xquery` directory, `$exist:controller` would contain `/xquery`.

exist:prefix  
If the current controller hierarchy is mapped to a certain path prefix, `$exist:prefix` returns that prefix. For example, the default configuration maps the path `/tools` to a collection in the database (see below). In this case, `$exist:prefix` would contain `/tools`.

exist:root  
The root of the current controller hierarchy. This may either point to the file system or to a collection in the database. Use this variable to locate resources relative to the root of the application. For example, assume you want to process a request through stylesheet `db2xhtml.xsl`, which could *either* be stored in the `/stylesheets` directory in the root of the webapp or - if the app is running from within the db - the corresponding `/stylesheets` collection. You want your app to be able to run from either location. The solution is to use `exist:root`:

&lt;forward servlet="XSLTServlet"&gt; &lt;set-attribute name="xslt.stylesheet" value="{$exist:root}/stylesheets/db2xhtml.xsl"/&gt; &lt;/forward&gt;

To summarize: if the request path is `/exist/tools/sandbox/get-examples.xql`, `$exist:prefix` would contain `/tools`, `$exist:controller` would point to `/sandbox`, `$exist:path` would be `/get-examples.xql`, and `$exist:resource`: `get-examples.xml`.

You do not need to explicitly declare the variables or the namespace. However, if you would like to do so, you can add an external declaration for each used variable at the top of your XQuery as follows:

declare variable $exist:path as external;
## Locating Controller Scripts and Configuring Base Mappings

By convention, the controller XQueries should be called `controller.xql`. XQueryURLRewrite will try to guess the path to the most-specific controller query by looking at the request path. For example, in the standard eXist distribution, the main controller file is located in `webapp/controller.xql`, but there are other controllers in the subdirectories `webapp/sandbox` or `webapp/admin`. If the servlet filter receives a request path <http://localhost:8080/exist/sandbox/>, it will find the `controller.xql` file in the `sandbox` directory and execute this controller instead of the main controller.

It is also possible to store the controller XQuery into the database instead of the file system. This makes sense if you want to keep a part of your web application within the db (which is a common approach).

In fact, one web application may have more than one controller hierarchy. For example, you may want to keep the main webapp within the file system, while some tools and scripts should be served from a database collection. This can be done by configuring two roots within the `controller-config.xml` file in `webapp/WEB-INF`. `controller-config.xml` defines the base mappings used by XQueryURLRewrite.

It basically has two components:

-   forward actions which map patterns to servlets

-   root elements define the root for a file system or db collection hierarchy

The forward tags specify path mappings for common servlets, similar to a servlet mapping in `web.xml`. The advantage is that XQueryURLRewrite becomes a single point of entry for the entire web application and we don't need to handle any of the servlet paths in the main controller. For example, if we registered a servlet mapping for `/rest` in `web.xml`, we would need to make sure that this path is ignored in our main `controller.xql`. However, if the mapping is done via `controller-config.xml`, it will already been known to XQueryURLRewrite and we don't need take care of the path in our controller.

The root elements define the roots of a directory or database collection hierarchy, mapped to a certain base path. For example, the default `controller-config.xml` uses two roots:

&lt;!-- Default configuration: main web application is served from the webapp directory. --&gt; &lt;root pattern="/tools" path="xmldb:exist:///db/www"/&gt; &lt;root pattern=".\*" path="/"/&gt;
This means that paths starting with `/tools` will be mapped to the collection hierarchy below `/db/www`. Everything else is handled by the catch all pattern pointing to the root directory of the webapp (by default corresponding to `EXIST_HOME/webapp`). For example, the URI

http://localhost:8080/exist/tools/admin/admin.xql
will be handled by the controller stored in database collection `/db/www/admin/` (if there is one) or will directly resolve to `/db/www/admin/admin.xql`. In this case, all relative or absolute URIs within the controller will be resolved against the database, not the file system. However, there's a possibility to escape this path interpretation, described [below](#EXTERNAL_RESOURCES).

## MVC and Pipelines

XQueryURLRewrite does more than just forward or redirect requests: the response can be further processed by passing it to a pipeline of views. "Views" are again just plain Java servlets. The most common use of a view would be to post-processes the XML returned from the primary URL, either through another XQuery or an XSLT stylesheet (XSLTServlet). XQueryURLRewrite passes the HTTP response stream of the previous servlet to the HTTP request received by the next servlet. Views may also directly exchange information through the use of request attributes (more on that below).

You define a view pipeline by adding a view element to the dispatch fragment returned from the controller. The view element is just a wrapper around another sequence of forward or rewrite actions.

For example, most of the documentation that comes with eXist is written in the docbook format and needs to be send through an XSLT stylesheet (`webapp/stylesheets/db2html.xsl`) to be transformed into HTML. This is done by returning the following dispatch fragment from `webapp/controller.xql`:

``` xml
<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <view>
        <forward servlet="XSLTServlet">
            <set-attribute name="xslt.stylesheet" 
                value="stylesheets/db2html.xsl"/>
        </forward>
    </view>
    <cache-control cache="no"/>
</dispatch>
```

There's no forwarding action outside the view in this example, so the request will be handled by the servlet engine in the normal way. The response is then passed to XSLTServlet. A new HTTP POST request is created whose body is set to the response data of the previous step. XSLTServlet gets the path to the stylesheet from the request attribute "xslt.stylesheet" and applies it to the data.

If any step in the pipeline generates an error or returns an HTTP status code &gt;= 400, the pipeline processing will stop and the response is send back to the client immediately. The same happens if the first step returns with an HTTP status 304 (NOT MODIFIED), which indicates that the client can use the version it has cached.

We can also pass a request through more than one "view". The following fragment applies two stylesheets in sequence (code taken from `webapp/xquery/controller.xql`):

``` xquery
if ($name eq 'acronyms.xql') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <!-- query results are passed to XSLT servlet via request attribute -->
        <set-attribute name="xquery.attribute"
            value="model"/>
        <view>
            <forward servlet="XSLTServlet">
                <set-attribute name="xslt.input"
                    value="model"/>
                <set-attribute name="xslt.stylesheet"
                    value="xquery/stylesheets/acronyms.xsl"/>
            </forward>
            <forward servlet="XSLTServlet">
                <clear-attribute name="xslt.input"/>
                <set-attribute name="xslt.stylesheet" 
                    value="stylesheets/db2html.xsl"/>
            </forward>
        </view>
    </dispatch>
```

The example also demonstrates how information can be passed between actions. XQueryServlet - which is called implicitely because the URL ends with ".xql" - can save the results of the called XQuery to a request attribute instead of writing them to the HTTP output stream. It does so if it finds a request attribute `xquery.attribute`, which should contain the name of the attribute the output should be saved to.

In the example above, `xquery.attribute` is set to "model". This causes XQueryServlet to fill the request attribute `model` with the results of the XQuery it executes. The query result will not be written to the HTTP response as you would normally expect. The HTTP response body will just be empty.

Likewise, XSLTServlet can take its input from a request attribute instead of parsing the HTTP request body. The name of the request attribute should be given in attribute `xslt.model`. XSLTServlet discards the current request content (which is empty anyway) and uses the data in the attribute's value as input for the transformation process.

XSLTServlet will always write to the HTTP response. The second invocation of XSLTServlet thus needs to read its input from the HTTP request body which contains the response of the first servlet. Since request attributes are preserved throughout the entire pipeline, we need to clear the `xslt.input` with an explicit call to clear-attribute.

What benefits does it have to exchange data through request attributes? Well, we save one serialization step: XQueryServlet directly passes the node tree of its output as a valid XQuery value, so XSLTServlet does not need to parse it again.

The advantages become more obvious if you have two or more XQueries which need to exchange information: XQuery 1 can use the XQuery extension function request:set-attribute() to save an arbitrary XQuery sequence to an attribute. XQuery 2 then calls request:get-attribute() to retrieve this value. It can directly access the data passed in from XQuery 1. No time is lost with serializing/deserializing the data.

Let's have a look at a more complex example: the XQuery sandbox web application needs to execute a user-supplied XQuery fragment. The results should be retrieved in an asynchronous way, so the user doesn't need to wait and the web interface remains usable.

Older versions of the sandbox used the `util:eval` function to evaluate the query. However, this has side-effects because util:eval executes the query within the context of another query. Some features like module imports will not work properly this way. To avoid util:eval, the controller code below passes the user-supplied query to XQueryServlet first, then post-processes the returned result and stores it into a session for later use by the ajax frontend:

``` xquery
if (starts-with($path, '/sandbox/execute')) then
    let $query := request:get-parameter("qu", ())
    let $startTime := util:system-time()
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <!-- Query is executed by XQueryServlet -->
            <forward servlet="XQueryServlet">
                <!-- Query is passed via the attribute 'xquery.source' -->
                <set-attribute name="xquery.source" value="{$query}"/>
                <!-- Results should be written into attribute 'results' -->
                <set-attribute name="xquery.attribute" value="results"/>
                <!-- Errors should be passed through instead of terminating the request -->
                <set-attribute name="xquery.report-errors" value="yes"/>
            </forward>
            <view>
                <!-- Post process the result: store it into the HTTP session
                    and return the number of hits only. -->
                <forward url="session.xql">
                    <clear-attribute name="xquery.source"/>
                    <clear-attribute name="xquery.attribute"/>
                    <set-attribute name="elapsed" 
                        value="{string(seconds-from-duration(util:system-time() - $startTime))}"/>
                </forward>
            </view>
        </dispatch>
    (: Retrieve an item from the query results stored in the HTTP session. The
    format of the URL will be /sandbox/results/X, where X is the number of the
    item in the result set :)
    else if (starts-with($path, '/sandbox/results/')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="../session.xql">
            <add-parameter name="num" value="{$name}"/>
        </forward>
    </dispatch>
```

The client passes the user-supplied query string in a request parameter, so the controller has to forward this to XQueryServlet somehow. Fortunately, XQueryServlet has an option to read the XQuery source from a request attribute, `xquery.source`. The query result will be saved to the attribute `results`. The second XQuery, `session.xql`, takes the result and stores it into a HTTP session, returning only the number of hits and the elapsed time.

When called through retrieve, `session.xql` looks at parameter `num` and returns the item at the corresponding position from the query results stored in the HTTP session.

## Controller XML Format

A controller XQuery is expected to return a single XML element: dispatch in the eXist namespace: <http://exist.sourceforge.net/NS/exist>. dispatch may contain a single action element, followed by an optional view element. Two action elements are currently allowed:

redirect  
Redirects the client to another URL, indicating that the other URL should be used for subsequent requests. The URL to redirect to is given in attribute `url`. A redirect will usually be visible to the user.

forward  
Forwards the current request to another request path or servlet. The forwarding is done on the server only, via the RequestDispatcher of the servlet engine. The client can't see where the request was forwarded to.

The request can either be forwarded to a servlet or to another request path, depending on which attribute is specified:

url  
The new request path, which will be processed by the servlet engine in the normal way, as if it were directly called. A relative path will be relative to the current request path. Absolute path will be resolved relative to the current web context. For example, if the current web context is `/exist` and the supplied attribute reads `url="/admin"`, the resulting path will be `/exist/admin`.

servlet  
The name of a servlet as given in the `servlet-name` element in the corresponding servlet definition of the web descriptor, `web.xml`. For example, valid names within the eXist standard setup would be "XQueryServlet" or "XSLTServlet".

absolute  
To be used in combination with `url`. If set to "yes", the url will be interpreted as an absolute path within the current servlet context. See [below](#EXTERNAL_RESOURCES) for an example.

method  
The HTTP method (POST, GET, PUT ...) to use when passing the request to the pipeline step (does not apply to the first step). This is important if the servlet or URL does not support all methods. The default method for pipeline steps in the view section is always POST.

In addition to the action, an element cache-control may appear:

cache-control  
has a single attribute `cache="yes|no"`. the cache-control element is used to tell XQueryURLRewrite if the current URL rewrite should be cached. Internally, XQueryURLRewrite keeps a map of input URIs to dispatch rules. With the cache enabled, the controller XQuery does only need to be executed once for every input URI. Subsequent requests will use the cache.

However, only the URL rewrite rule is cached, not the HTTP response. The cache-control setting has nothing to do with the corresponding HTTP cache headers or client-side caching within the browser.

Within an action element, parameters and attributes can be set as follows:

add-parameter  
Add (or overwrite) a request parameter. The original HTTP request will be copied before the change is applied. Subsequent steps in the pipeline will not see the parameter. The name of the parameter is taken from attribute `name`, the value from attribute `value`.

set-attribute  
Set a request attribute to the given value. The name of the attribute is read from attribute `name`, the value from attribute `value`. You can set arbitrary request attributes, e.g. to pass information between XQueries. However, some attributes may be reserved by the called servlet (see examples above).

clear-attribute  
Clears a request attribute. Unlike parameters, request attributes will be visible to subsequent steps in the processing pipeline. They does need to be cleared once they are no longer needed. The name of the attribute is read from attribute `name`.

set-header  
Set an HTTP response header field. The HTTP response is shared between all steps in the pipeline, so all following steps will be able to see the changed header.

## Accessing resources not stored in the database

If your controller.xql is stored in a database collection, all relative or absolute URIs within the controller will be resolved against the database, not the file system. This can be a problem if you need to acess common resources, which should be shared with other applications residing on the file system or in the database.

The forward directive accepts an optional attribute `absolute="yes|no"` to handle this. If one sets `absolute="yes"`, an absolute path (starting with a /) specified in the `url` attribute will be resolved relative to the current servlet context, NOT the controller context.

For example, to forward all requests starting with a path `/libs/` to a directory within the `webapp` folder of eXist, you can use the following snippet:

``` xquery
if (starts-with($exist:path, "/libs/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/{substring-after($exist:path, '/libs/')}" absolute="yes"/>
    </dispatch>
```

This simply removes the /libs/ prefix and sets absolute="yes", so the path will be resolved relative to the main context of the servlet engine, usually /exist/. In your HTML, you can now write:

&lt;script type="text/javascript" src="/libs/scripts/jquery/jquery-1.7.1.min.js"&gt;&lt;/script&gt;
This will locate the jquery file in `webapp/scripts/jquery/...`, even if the rest of your application is stored in the db and not on the file system.

## Special Attributes Accepted by eXist Servlets

eXist's XQueryServlet as well as the XSLTServlet will listen to a few, predefined request attributes. The names of those attributes are listed below and should not be used for other purposes.

### XQueryServlet

xquery.attribute  
Should contain the name of a request attribute, if set. Instead of writing query results to the response output stream, XQueryServlet will store them into the named attribute. The value of the attribute will be an XQuery Sequence (`org.exist.xquery.Sequence`). If no query results were returned, the attribute will contain an empty sequence.

xquery.source  
If set, the value of this attribute should contain the XQuery code to execute. Normally, XQueryServlet reads the XQuery from the file given in the request path. `xquery.source` is a way to overwrite this behaviour, e.g. if you want to evaluate an XQuery which was generated within the controller.

xquery.module-load-path  
The path which will be used for locating modules. This is only relevant in combination with `xquery.source` and tells the XQuery engine where to look for modules imported by the query. For example, if you stored required modules into the database collection `/db/test`, you can set `xquery.module-load-path` to "xmldb:exist:///db/test". If the query contains an expression:

import module namespace test="http://exist-db.org/test" at "test.xql";

the XQuery engine will try to find the module `test.xql` in the filesystem by default, which is not what you want. Setting `xquery.module-load-path` fixes this.

xquery.report-errors  
If set to "yes", an error in the XQuery will not result in an HTTP error. Instead, the string message of the error is enclosed in an element error which is then written to the response stream. The HTTP status is not changed.

### XSLTServlet

xslt.stylesheet  
The path to the XSL stylesheet. Relative paths will be resolved against the current request URI, absolute paths against the context of the web application (/exist). To reference a stylesheet which is stored in the database, use an XML:DB URI, e.g. `xmldb:exist:///db/styles/myxsl.xsl`.

xslt.input  
Contains the name of a request attribute from which the input to the transformation process should be taken. The input has to be a valid eXist XQuery sequence or an error will be thrown.

This attribute is usually combined with `xquery.attribute` provided by XQueryServlet and allows passing data between the two without additional serialization/parsing overhead.

xslt.user  
The name of the eXist user which should be used to read and apply the stylesheet.

xslt.password  
Password for the user given in `xslt.user`

XSLTServlet will attempt to map all other request attributes starting with the prefix `xslt.` into *stylesheet parameters*. So, for example, if you set a request attribute `xslt.myattr` it will be available within the stylesheet as parameter `$xslt.myattr`. For security reasons, this is the only way to pass request parameters into the stylesheet: use the controller query to transform the request parameter into a request attribute and pass that to the view.

However, depending on the XSLT engine used, automatic conversion of types between eXist/Java and the XSLT processor may not always work. It might be good to limit your attribute values to nodes or strings.
