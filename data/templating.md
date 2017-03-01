# HTML Templating Module

## Introduction

The main goal of the HTML templating framework in eXist-db is a clean separation of concerns. Generating entire pages in XQuery is quick and dirty, but makes maintenance and code sharing difficult. Ideally people should be able to look at the HTML view of an application and modify its look and feel without knowing XQuery. The application logic - written in XQuery - should be kept separate. Likewise, the XQuery developer should only deal with the minimal amount of HTML which is generated dynamically.

The templating module also handles most of the HTTP processing an application requires. It does so using sophisticated features like automatic parameter injection and type conversion. The goal was to remove repeating code like:

let $query := request:get-parameter("query", ()) let $field := request:get-parameter("field", ()) ...
In fact you should not see many calls to the HTTP request or session module inside a templating function. It is all handled by parameter injection.

> **Note**
>
> Working examples for the templating module can be found in the [demo application]({demo}/examples/templating/templates.html).

## Writing the HTML

The templating module is mainly based on conventions. Wherever possible it tries to make a best guess instead of requiring additional code or annotations to be written. This works as long as the conventions used are sufficiently clear.

The input for the templating framework is always a plain HTML file. The module scans the HTML view for elements with class (or data-template, see below) attributes following a simple convention and tries to translate them into XQuery function calls. By using class attributes, the HTML remains sufficiently clean and does not get messed up with application code. A web designer could take the HTML files and work on them without being bothered by the extra class names.

In the simplest case, a template call inside a class attribute is just the name of a function known in the XQuery context. To start with the usual "Hello world" example:

&lt;div class="demo:hello grey-box"&gt;Greet the user&lt;/div&gt;
When the module encounters demo:hello, it will try to find a function named "demo:hello" in all the modules known to the XQuery. If the function's signature follows a certain convention (see below), it will be called and the div will either be replaced or enhanced by whatever the function returns.

Please note that the additional class "grey-box" does not interfere with the template call and is just ignored. "grey-box" might be a class used for styling, so we don't want to remove it. The templating framework will only take a closer look at class names which follow the `prefix:local-name` pattern.

It is also possible to pass static parameters to a template call. Those are encoded like URI parameters, e.g.: `demo:hello?language=de`. A static parameter will be passed to the XQuery function as a fallback value if it cannot be determined by looking at the HTTP context (see below).

### HTML5 Method

Instead of "abusing" class attributes to encode template calls or other application-specific information, HTML5 provides a standard method for adding data to an element, using `data` attributes. This approach is supported in newer versions of the templating framework (beginning with version 0.3.0 of the shared-resources package, which contains the source of the templating).

The `data` attributes must follow a certain naming pattern. The templating function to call has to be specified in an attribute: `data-template`, while optional parameters would go into one or more attributes of the form: `data-template-xxx`. For example, you could change the pre-HTML5 style template call:

&lt;div class="demo:hello?language=de"&gt;&lt;/div&gt;
into

&lt;div data-template="demo:hello" data-template-language="de"&gt;&lt;/div&gt;
The templating framework supports both alternatives.

## Templating Functions

A templating function is an ordinary XQuery function in a module which takes at least two parameters (of a certain type), though additional parameters are allowed. If a function does not follow this convention, it will simply be ignored by the templating framework. For example, our "Hello world!" function could be defined as follows:

``` xquery
declare function demo:hello($node as node(), $model as map(*), $language as xs:string, $user as xs:string) as element(div) {
    <div>
    {
        switch($language)
            case "de" return
                "Hallo " || $user
            case "it" return
                "Ciao " || $user
            default return
                "Hello " || $user
    }
    </div>
};
            
```

The two required parameters here are `$node` and `$model`. $node contains the HTML node currently being processed: in this case, the div element. $model is an XQuery map with application data. It will be empty for now, but we'll see later why it is important.

## Parameter Injection and Type Conversion

The additional parameters, `$language` and `$user`, will be injected automatically. The templating framework tries to make a best guess about how to fill those parameters with values. It checks the following 3 contexts for parameters with the same name (in the order below):

1.  if the current *HTTP request* contains a (non-empty) parameter with the same name as the parameter variable, it is used to set the value of the variable

2.  if the *HTTP session* contains an attribute with the same name as the parameter variable, the variable's value will be set to it

3.  if the *static parameters* passed to the template call contain a parameter matching the variable name, it will be used

If neither 1. nor 2. lead to a non-empty value, the function signature will thus be checked for an annotation `%templates:default("name", "value1",
                    ..., "valueN")`. The first parameter of the annotation should match the name of the parameter variable. All other parameters of the annotation are taken as values for the variable.

If "language" is passed as a parameter in the HTTP request, it will overwrite the static parameter we provided because the HTTP request is checked first.

The templating framework will attempt automatic type conversion for all parameters. If the parameter has a declared type of xs:integer, it will try to cast a parameter it finds into an integer. If the type is node(), the parameter value will be parsed into XML. These conversions may fail and you may get an error if you are passing a parameter with the wrong type.

## Additional Annotations

Our "Hello world" example above does not preserve the div from which it was called, but replaces it with a new one which lacks the "grey-box" class. This is the default behavior. To preserve the enclosing div, we should add the XQuery annotation `%templates:wrap` to the function signature.

A second annotation can be used to provide a default value for a parameter: `%templates:default("parameter", "value1", "value2", ...)`. For example, we may want to set the $language parameter to "en" if the value cannot be determined otherwise:

``` xquery
declare 
    %templates:wrap %templates:default("language", "en")
function demo:hello($node as node(), $model as map(*), $language as xs:string, $user as xs:string) as xs:string {
    switch($language)
        case "de" return
            "Hallo " || $user
        case "it" return
            "Ciao " || $user
        default return
            "Hello " || $user
};
```

As you can see, we could remove the wrapping div and just return a string now.

## Using the Model to Keep Application Data

In a more complex application, a view will have many templating functions, which all access the same data. For example, take a typical search page: there might be one HTML element to display the number of hits, one to show the query, and another one for printing out the results. All those components need to access the search result. How do you do this in a templating framework?

This is where the `$model` parameter becomes important. It is passed to all template functions and they can add data to it, which will then be available to nested template calls. A search page could thus contain HTML like this:

``` xml
<div class="demo:search">
    <p>Found <span class="demo:hit-count"></span> hits</p>
    <ul class="demo:result-list"></ul>
</div>
```

The `demo:hit-count` and `demo:result-list` occur inside the div calling `demo:search`. They are thus nested template calls. `demo:search` would probably perform the actual search operation based on the parameters passed by the user. But instead of directly printing the search result in HTML, it delegates this to the nested templates. demo:search might be implemented as:

``` xquery
declare 
    %templates:wrap
function demo:search($node as node(), $model as map(*), $query as xs:string) as map(*) {
    let $result :=
        for $hit in collection($config:app-root)//SCENE[ft:query(., $query)]
        order by ft:score($hit) descending
        return $hit
    return
        map { "result" := $result }
};
```

`demo:search` differs from the functions we have seen so far in that it returns an XQuery map and not HTML or an atomic type. If a templating function returns a map, the templating framework will proceed as follows:

1.  add the returned map to the current `$model` map (adding it to the map entries produced by any ancestor templates calling it)

2.  resume processing the children of the current HTML node

The `demo:hit-count` and `demo:result-list` can thus access the query results in the `$model` map passed to them:

``` xquery
declare function demo:hit-count($node as node(), $model as map(*)) as xs:integer {
    count($model("result"))
};
```

### Manual Processing Control

Inside a templating function, you can also call `templates:process($nodes
                        as node()*, $model as map(*))` to let the templating module process the given node sequence. You just need to make sure you are not running into an endless loop by calling `templates:process` on the currently processed node. A common pattern is to trigger `templates:process` on the children of the current node:

``` xquery
templates:process($node/node(), $model)
```

This is comparable to calling xsl:apply-templates in XSLT and will have the same effect as returning a map (see the section above), but with your templating function having full control.

For example, it is sometimes necessary to first process all the descendant nodes of the current element, then apply some action to the processed tree. The documentation app has a function, `config:expand-links`, which scans the final document tree for links and expands them. The function is implemented as follows:

``` xquery
declare %templates:wrap function config:expand-links($node as node(), $model as map(*), $base as xs:string?) {
    for $node in templates:process($node/node(), $model)
    return
        config:expand-links($node, $base)
};
```

## Set-Up

The templating module is entirely implemented in XQuery. It provides a single public function, `templates:apply`. A complete main module which calls the templating framework to process an HTML file passed in the HTTP request body could look as follows:

``` xquery
(:~
 : This is the main XQuery which will (by default) be called by controller.xql
 : to process any URI ending with ".html". It receives the HTML from
 : the controller and passes it to the templating framework.
 :)
xquery version "3.0";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";

(: 
 : The following modules provide functions which will be called by the 
 : templating framework.
 :)
import module namespace app="http://my.domain/myapp" at "app.xql";

declare option exist:serialize "method=html5 media-type=text/html";

(:
 : We have to provide a lookup function to templates:apply to help it
 : find functions in the imported application modules. The templates
 : module cannot see the application modules, but the inline function
 : below does see them.
 :)
let $lookup := function($functionName as xs:string, $arity as xs:int) {
    try {
        function-lookup(xs:QName($functionName), $arity)
    } catch * {
        ()
    }
}
(:
 : The HTML is passed in the request from the controller.
 : Run it through the templating framework and return the result.
 :)
let $content := request:get-data()
return
    templates:apply($content, $lookup, ())
```

This module would be called from the URL rewriting controller. For example, we could add a rule to `controller.xql` to pass any .html resource to the above main query (saved to `modules/view.xql`):

``` xquery
(: Pass all requests to HTML files through view.xql, which handles HTML templating :)
if (ends-with($exist:resource, ".html")) then
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
```

The only part of the main module code which might look a bit unusual is the inline lookup function: the templating module uses dynamic function calls to execute template functions in application modules. But unfortunately, XQuery modules can only "see" functions in their own context. There is thus no way for the templating module to determine what functions are defined in application modules which are outside its context. We thus need to "help" it by providing a callback function to resolve function references. The lookup function is defined in the main context and can thus access all the modules imported into the main module.

Normally you can just copy and paste the main module code as given above. To adopt it to your own application, just import your application modules and you're done.

## Integration with eXide

The "New Application" templates in eXide already include the HTML templating module and configure the URL rewriting to call it for any path ending in `.html`. Using eXide is thus the easiest way to get started with the templating framework. Please consult the [Getting Started with Web Application Development](development-starter.md) guide to read more.

## Where to Find the Module?

If you generate your application with eXide, a copy of the HTML templating module will be included, so you can customize it. If you rather want to make sure you have the latest version of the templating module: the [shared-resources](https://github.com/eXist-db/shared-resources) application also exports the module. This will always be the latest version. You could thus define a dependency on the shared-resources app (see the [packaging documentation](repo.md)). In this case you can just import the module by its namespace URI, but without specifying a location.

import module namespace templates="http://exist-db.org/xquery/templates";
The documentation and demo applications all read the templating module from shared-resources.

## Pre-defined Template Commands

The templating module defines a number of general-purpose templating functions, which are described below for reference. `templates:surround` is probably the most powerful one and used by almost all HTML views.

### templates:include

templates:include?path=path-to-xml-resource
Includes the content of the resource given by path into the current element. The path is always interpreted relative to the current application directory or collection.

### templates:each

templates:each?from=map-key&amp;to=map-key
Retrieve the sequence identified by the map key `from` from the `$model` map. If it exists, iterate over the items in the sequence and process any nested content once. During each iteration, the current item is added to the `$model` map using the key `to`.

### templates:if-parameter-set

templates:if-parameter-set?param=request-parameter
Conditionally includes its content only if the given request parameter is set and is not empty.

### templates:if-parameter-unset

templates:if-parameter-unset?param=request-parameter
Conditionally includes its content only if the given request parameter is not set or is empty.

### templates:surround

templates:surround?with=xml-resource&at=id&using=id
Surrounds its content with the contents of the XML resource specified in "with". The "at" parameter determines where the content is inserted into the surrounding XML. It should match an existing HTML id in the template.

The "using" parameter is optional and specifies the id of an element in the "with" resource. The current content will be surrounded by this element. If the parameter is missing, the entire document given in "with" will be used.

The surround template instruction is used by all pages of the [Demo]({demo}/index.html) application. The header, basic page structure and menus are the same for all pages. Each page thus only contains a simple div with a template instruction:

templates:surround?with=templates/page.html&at=content
The instruction takes the content of the current element and injects it into the template page.

### templates:form-control

templates:form-control
Use on &lt;input&gt; and &lt;select&gt; elements: checks the HTTP request for a parameter matching the name of the form control and fills it into the value of an input or selects the corresponding option of a select.

### templates:load-source

templates:load-source
Normally used with an &lt;a&gt; element: opens the document referenced in the href attribute in eXide.
