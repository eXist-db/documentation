# XQuery in eXist-db

## Introduction

eXist-db provides strong support for the W3C recommendation of the XQuery language, implementing the XQuery and XPath functions and operators. eXist-db builds on the recommendation, adding a rich family of extension functions and other capabilities that allow XQuery developers to create powerful applications with eXist-db.

> **Note**
>
> This document is an important reference work intended to help advanced developers to understand eXist-db's implementation of XQuery, but for readers who are new to XQuery or programming in general, this document may be too complex. We recommend you start with the resources listed in [Learning XQuery with eXist-db](learning-xquery.md) or [Getting Started with Web Application Development](development-starter.md).

To briefly summarize each section's contents:

-   [Current Status of XQuery Support](#current-status-of-xquery-support) describes the precise nature of eXist-db's conformance to the XQuery specification.

-   [Function Library](#function-library) outlines where to find the library of documentation about the XQuery functions built into eXist-db.

-   [The Module System](#module-system) outlines the different kind of library modules that eXist-db supports, ranging from modules written in XQuery to those written in Java, and how to register modules as globally available, and how to import them by URI.

-   [XQuery Caching](#xquery-caching) describes how eXist-db uses caching to improve performance when reusing modules.

-   [eXist-db Extension Functions](#extension-functions) describes some of the convenient functions available in eXist-db for addressing documents and collections.

-   [Calling Java Methods from XQuery](#calling-java) describes how enable Java binding to call arbitrary Java methods directly from XQuery.

-   [Creating XQuery Modules](#modules) describes how to create XQuery Modules in XQuery and Java.

-   [Using Collations](#collations) describes how to specify language-specific string sorting and comparisons.

-   [Serialization Options](#serialization) explains how to control the output of a query.

-   [Pragmas](#pragmas) describes the pragmas that eXist-db implements.

-   [Other Options](#other-options) describes how to set timeouts and other limits and variables on a query.

## Current Status of XQuery Support

eXist-db fully implements the XQuery 1.0 language as specified in the [W3C recommendation](http://www.w3.org/TR/xquery/), with the exception of features [detailed below](#unsupported-features). Functions in the standard function library follow the ["XQuery 1.0 and XPath 2.0 Functions and Operators" recommendation](http://www.w3.org/TR/xpath-functions/); see the eXist-db [XQuery Function Documentation](/exist/apps/fundocs).

eXist-db also implements most features of the current ["XQuery 3.0"](http://www.w3.org/TR/xquery-30/) Working Draft, as detailed in the section on [XQuery 3 support](#xquery-30) below. From [XQuery 3.1](#xquery-31), the map data type is fully supported. An implementation of arrays is in the works.

### XQuery Test Suite compliance

The eXist-db XQuery implementation is tested against the official [XML Query Test Suite (XQTS)](http://dev.w3.org/2006/xquery-test-suite/). This suite, which focuses on XQuery 1.0, contains more than 14,000 tests, and eXist-db passes more than 99.4% of the tests. We are continuously trying to improve these results. The [XQuery 3.0 Test Suite (QT3)](http://dev.w3.org/2011/QT3-test-suite/) has just become available and has been integrated into our test harness, though the results are not reliable yet.

### Supported Optional Features

In addition to the standard features, eXist-db provides extended support for [*modules*](#module-system) and implements the *full axis* feature, which means you can use the *optional axes*: `ancestor`, `ancestor-or-self`, `following`, `following-sibling`, `preceding`, and `preceding-sibling`. (The only optional axis not supported is the `namespace` axis.)

### Unsupported features

eXist-db implements all features described in the XQuery 1.0 specification, with the exception of the following:

-   Schema-related Features (`validate` and `import schema`). eXist-db's XQuery processor does currently not support the [schema import](http://www.w3.org/TR/xquery/#id-schema-import-feature) and [schema validation features](http://www.w3.org/TR/xquery/#id-schema-validation-feature) defined as [optional](http://www.w3.org/TR/xquery/#id-conform-optional-features) in the XQuery specification. eXist-db provides [extension functions]({fundocs}/view.html?uri=http://exist-db.org/xquery/validation&location=java:org.exist.xquery.functions.validation.ValidationModule) to perform XML validation. The database does not store type information along with the nodes. It therefore cannot know the typed value of a node and has to assume `xs:untypedAtomic`. This is the behaviour defined by the XQuery specification.

-   eXist-db does not support specifying a data type in an element or attribute test. The node test `element(test-node)` is supported, but the test `element(test-node,
                                    xs:integer)` will result in a syntax error.

eXist-db does nevertheless support strong typing whenever the expected type of an expression, a function argument or function return value is explicitly specified or can be known otherwise. eXist-db is not lax about type checks.

### XQuery 3.0 Support

eXist-db implements the following features of the ["XQuery 3.0"](http://www.w3.org/TR/xquery-30/) Working Draft

-   Higher Order Functions: eXist-db completely supports higher-order functions, including features like inline functions, closures, and partial function application. For more information, see the article on the eXist-db blog, [Higher-Order Functions in XQuery 3.0](http://atomic.exist-db.org/blogs/eXist/HoF)

-   Group by clause in FLWOR expressions: "group by" provides an efficient way to group the sequences generated in a FLWOR expression. For example,

    ``` xquery
    xquery version "3.0";
    for $speechBySpeaker in //SPEECH[ft:query(., "king")]
    group by $speaker := $speechBySpeaker/SPEAKER
    order by $speaker
    return
        <speaker name="{$speaker}">
        { $speechBySpeaker }
        </speaker>
    ```

    queries the Shakespeare plays and groups the result by speaker.

-   Try/Catch: The try/catch expression provides error handling for dynamic errors and type errors. For example, try { 'a' + 7 } catch \* { concat($err:code, ": ", $err:description) } returns the full error (excerpted here): err:XPTY0004: It is a type error if... For more information, see the article on the eXist-db blog, [Higher-Order Functions in XQuery 3.0](http://atomic.exist-db.org/HowTo/XQuery3/Try-CatchExpression) and the [specification](http://www.w3.org/TR/xquery-30/#id-try-catch).

-   The new String Concatenation expression: A convenient alternative to the `concat()` function. Strings can be joined with ||. For example, "Hello " || $world || "!" is equivalent to concat("Hello", $world, "!"). See the original [announcement](http://markmail.org/message/a7dmmhixwbbnwikt) on exist-open and the [specification](http://www.w3.org/TR/xquery-30/#id-string-concat-expr).

-   The Simple Map Operator: Can be used to replace short "for" loops, providing performance benefits due to its simpler processing compared to a full "for" statement. In an example like ("red", "blue", "green") ! string-length() ! (. \* 2), the right-hand expression is evaluated once for each item in the sequence to the left of "!". The example results in 6, 8, 10. See the original [announcement](http://markmail.org/message/a7dmmhixwbbnwikt) on exist-open and the [specification](http://www.w3.org/TR/xquery-30/#id-map-operator).

-   Switch expression: Eliminates the need for long conditional chains for string values. See the article on the eXist-db blog, [Switch Expression](http://atomic.exist-db.org/HowTo/XQuery3/SwitchExpressionExample), and the [specification](http://www.w3.org/TR/xquery-30/#id-switch).

-   New functions: XQuery 3.0 adds a number of functions, some previously available only in XSLT are now available in XQuery 3.0. See, for example, the specification on [date/time formatting functions](http://www.w3.org/TR/xpath-functions-30/#rules-for-datetime-formatting) like `fn:format:date()`, [formatting numbers](http://www.w3.org/TR/xpath-functions-30/#formatting-numbers) like `fn:format-number()`, and [fn:analyze-string()](http://www.w3.org/TR/xpath-functions-30/#func-analyze-string).

-   Private functions and function annotations: Annotations declare properties associated with functions and variables. For example, functions can now be declared as %private or %public. See the [specification](http://www.w3.org/TR/xquery-30/#id-annotations).

-   Serialization Parameters: XQuery 3.0 version of the language provides a standard way to set serialization parameters. The old, non-standard approach in eXist-db was to use a single option with all parameters in the value: declare option exist:serialize "method=json media-type=application/json"; The standard way of doing this in XQuery 3.0 would be: declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization"; declare option output:method "json"; declare option output:media-type "application/json"; See the original [announcement](http://markmail.org/message/ojasso6drkpbxemz) on exist-open and the [specification](http://www.w3.org/TR/xslt-xquery-serialization-30/)

To make use of these features of XQuery 3.0, use the proper version declaration in the prolog of your queries:

xquery version "3.0";
### Missing XQuery 3.0 Features

eXist-db 2.0 does not support some of the less frequently used XQuery 3.0 constructs, mainly because we did not encounter many use cases for them yet. This may certainly change though:

-   "tumbling" and "sliding window" in FLWOR expressions

-   "count" clause in FLWOR expressions

-   "allowing empty" in FLWOR clause

The following functions from the XQuery 3.0 function specification are missing as well, but most of them are in fact just replacements for functions which have been available in eXist-db since a long time:

<table>
<caption>Unsupported XQuery 3.0 Functions</caption>
<colgroup>
<col width="50%" />
<col width="50%" />
</colgroup>
<thead>
<tr class="header">
<th>XQuery 3.0</th>
<th>eXist-db 2.0</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>unparsed-text</td>
<td>util:binary-to-string(util:binary-doc($doc))</td>
</tr>
<tr class="even">
<td>unparsed-text-available</td>
<td>util:binary-doc-available</td>
</tr>
<tr class="odd">
<td>unparsed-text-lines</td>
<td>na</td>
</tr>
<tr class="even">
<td>innermost/outermost</td>
<td>na</td>
</tr>
<tr class="odd">
<td>path</td>
<td>na</td>
</tr>
</tbody>
</table>

### XQuery 3.1

The specification for XQuery 3.1 is still subject to change. The main additions are maps and arrays.

#### Maps

Maps are fundamental for the templating module and other libraries in eXist 2.2, and are thus very well supported. Over time, the specification changed slightly and so did the implementation in eXist. For example, to keep backwards compatibility, eXist allows the older notation in map constructors: `key:=value` in addition to the new one, `key: value`. Also, some functions in eXist support collations, which are no longer in the specification.

Please refer to the [demo app]({demo}/examples/basic/maps.html) for basic examples.

#### Arrays

Support for arrays has been implemented, but it is not in the official codebase yet. We're waiting for the specification to stabilize before we'll merge the code into develop.

### Other Related Specifications

-   Full Text Search: eXist-db has an implementation-specific [Full Text Search facility](lucene.md), built on the Lucene library (among several methods of [indexing](indexing.md)). It does not currently support the syntax in the W3C [XQuery and XPath Full Text 1.0](http://www.w3.org/TR/xpath-full-text-10/) Recommendation.

-   XQuery Update: eXist-db has an implementation-specific [XQuery Update syntax](update_ext.md). It does not currently support the syntax in the W3C [XQuery Update Facility 1.0](http://www.w3.org/TR/xquery-update-10/) Recommendation. The main difference is that the eXist-db implementation supports in-place updates. Switching to the W3C recommendation would break backwards compatibility. We postponed this step to after 2.0.

## Function Library

A complete list of XQuery functions supported by eXist-db [XQuery Function Documentation](/exist/apps/fundocs). Each module's documentation is generated from a different sources, depending on whether the module is implemented in Java or XQuery. For modules implemented in Java, the documentation are taken directly from the signature provided by the class implementing the `Function` interface. For modules implemented in XQuery, the function descriptions are taken from [XQDoc-formatted comments and annotations](xqdoc.md).

## The Module System

With eXist-db, you can write [entire web applications in XQuery](development-starter.md). This may result in rather complex XQuery scripts, consisting of several thousand lines of code. Being able to package related functions into modules is thus an important feature. eXist-db allows modules to be imported from a variety of sources:

-   an URI

-   a collection in the database

-   a jar file, i.e. a Java archive

-   a Java class, if the module is itself implemented in Java

For example, a typical import statement in an XQuery will look like this:

import module namespace status="http://exist-db.org/xquery/admin-interface/status" at "http://exist-db.org/modules/test.xqm";
Provided that the module namespace does not point to one of the preloaded standard modules (see below), the query engine will try to locate the module source by looking at the URI given after the `at` keyword. In the example above, the module was specified using a full URI and the query engine will attempt to load the module source from the given URI. However, the module could also be stored in a database collection:

import module namespace status="http://exist-db.org/xquery/admin-interface/status" at "xmldb:exist:///db/modules/test.xqm";
The query engine recognizes that the module should be stored in the local database instance and tries to directly compile it from there.

If the XQuery module is part of a Java application, it might also be an option, to pack the module into a Java archive (.jar file) along with the Java classes and use the following import to load the module from a Java package:

import module namespace status="http://exist-db.org/xquery/admin-interface/status" at "resource:org/exist/xquery/lib/test.xqm";
Finally, XQuery modules can also be implemented in Java (see [below](#calling-java)), in which case you can import them by specifying the class path of the Module class:

import module namespace xdiff="http://exist-db.org/xquery/xmldiff" at "java:org.exist.xquery.modules.xmldiff.XmlDiffModule";
The `extensions/modules` directory in the eXist-db distribution contains a number of useful modules, which could also serve as examples for implementing your own.

### Using Relative URIs

If the location specified in an import statement is a relative URI, the query engine will try to load the module relatively to the current module load path. The module load path is determined as follows:

1.  if the main XQuery was retrieved from the file system, the module load path points to that directory. This applies to queries executed through the XQueryServlet, XQueryGenerator or the Java admin client.

2.  if the main XQuery was loaded from a database collection, the module load path is the URI of that collection.

    For example, if you access an XQuery via the REST server:

    http://localhost:8080/exist/servlet/db/modules/test.xq
    All relative module paths will be resolved relative to the `/db/modules` collection.

### Preloaded Modules

Preloaded modules do not need to be explicitly imported or declared in the prolog of queries. The builtin-modules element in `conf.xml` lists the namespaces and the corresponding Java class that implements the module of all modules to be preloaded:

                            <xquery enable-java-binding="no">
        <builtin-modules>
            <module uri="http://exist-db.org/xquery/util"
                class="org.exist.xquery.functions.util.UtilModule"/>
            <module uri="http://exist-db.org/xquery/transform"
                class="org.exist.xquery.functions.transform.TransformModule"/>
        </builtin-modules>
    </xquery>
                        

## XQuery Caching

XQuery modules executed via the REST interface, the XQueryServlet or XQueryGenerator are *automatically* cached: the compiled expression will be added to an internal pool of prepared queries. The next time a query or module is loaded from the same location, it will not be compiled again. Instead, the already compiled code is reused. The code will only be recompiled if eXist-db decides that the source was modified or it wasn't used for a longer period of time.

If a query is accessed by more than one thread concurrently, each new thread will create a new copy of the compiled query. The copies will be added to the query pool until it reaches a pre-defined limit.

Modules are cached along with the main query that imported them.

## eXist-db Extension Functions

eXist-db offers a number of additional functions. While the XQuery Function Documentation lists them all, several possess articles of their own discussing some of the essential uses in detail:

-   [xmldb](xmldb.md): A module for manipulating database contents

-   [util](util.md): A module containing several convenient utility functions

-   [kwic](kwic.md): A module that provides keyword in context (KWIC) highlighting functions

-   [ft](lucene.md): A module for accessing the full text index, built on the Lucene library

-   [contentextraction](contentextraction.md): A module for extracting content from binary files

## Calling Java Methods from XQuery

eXist-db supports calls to arbitrary Java methods from within XQuery. The binding mechanism follows the short-cut technique introduced by [Saxon](http://saxon.sf.net). The class where the external function will be found is identified by the namespace URI of the function call. The namespace URI should start with the prefix `java:` followed by the fully qualified class name of the class. For example, the following code snippet calls the static method sqrt (square-root function) of class `java.lang.Math`:

``` xquery
declare namespace math="java:java.lang.Math";
math:sqrt(2)
```

Note that if the function name contains a hyphen, the letter following the hyphen is converted to upper-case and the hyphen is removed (i.e. it applies the CamelCase naming convention), and so, `to-string()` will call the Java method `toString()`.

If more than one method in the class matches the given name and parameter count, eXist-db tries to select the method that best fits the passed parameter types at runtime. The result of the method call can be assigned to an XQuery variable. If possible, it will be mapped to the corresponding XML schema type. Otherwise, it's type is the built-in type `object`.

*Java constructors* are called using the function `new`. Again, a matching constructor is selected by looking at the parameter count and types. The returned value is a new Java object with the built-in type `object`.

*Instance methods* are called by supplying a valid Java object as first parameter. The Java object has to be an instance of the given class. For example, the following snippet lists all files and directories in the current directory:

``` xquery

declare namespace file="java:java.io.File";

<files>
    {
        for $f in file:list-files( file:new(".") )
        let $n := file:get-name($f)
        order by $n
        return
            if (file:is-directory($f)) then
                <directory name="{ $n }"/>
            else
                <file name="{ $n }" size="{ file:length($f) }"/>
    }
</files>
```

> **Note**
>
> For security reasons, the Java binding is disabled by default. To enable it, the attribute `enable-java-binding` in the central configuration file has to be set to `yes`:
>
> &lt;xquery enable-java-binding="yes"&gt;
> Enabling the Java binding bears some risks: if you allow users to directly pass XQuery code to the database, e.g. through the sandbox application, they might use Java methods to inspect your system or execute potentially destructive code on the server.

## Creating XQuery Modules

eXist-db supports XQuery library modules. These modules are simply collections of function definitions and global variable declarations, of which eXist-db knows two types: *External Modules*, which are themselves written in XQuery, and *Internal Modules*, which are implemented in Java. The standard XPath/XQuery functions and all extension functions described in the above sections are implemented as internal modules. This section describes how to create XQuery modules using XQuery and Java.

### Creating Modules in XQuery

You can declare an XQuery file as a module and import it using the `import module` directive. The XQuery engine imports each module only once during compilation. The compiled module is then made available through the static XQuery context.

### Creating Modules in Java

To register a Java-based XQuery modules, eXist-db requires a namespace URI by which the module is identified, and the list of functions it supplies. For this, you need only to pass a driver class to the XQuery engine, and this class should implement the interface `org.exist.xpath.InternalModule`.

> **Note**
>
> Besides the basic methods for creating a Java-based XQuery module as described here, eXist-db provides a pluggable module interface that allows extension modules to be easily developed in Java. See [XQuery Extension Modules](extensions.md) for the full documentation on this eXist-db development best practice.

Moreover, the class `org.exist.xpath.AbstractInternalModule` already provides an implementation skeleton. The class constructor expects an array of function definitions for all functions that should be registered. A function definition (class `FunctionDef`) has two properties: the static signature of the function (as an instance of `FunctionSignature`), and the Java Class that implements the function.

A function is a class extending `org.exist.xquery.Function` or `org.exist.xquery.BasicFunction`. Functions without special requirements (e.g. overloading) should subclass BasicFunction. To illustrate, the following is a simple function definition:

``` java

public class EchoFunction extends BasicFunction {

public final static FunctionSignature signature =
new FunctionSignature(
    new QName("echo", ExampleModule.NAMESPACE_URI, ExampleModule.PREFIX),
    "A useless example function. It just echoes the input parameters.",
    new SequenceType[] { 
        new FunctionParameterSequenceType("text", Type.STRING, Cardinality.ZERO_OR_MORE, "The text to echo")
    },
    new FunctionReturnSequenceType(Type.STRING, Cardinality.ZERO_OR_MORE, "the echoed text"));

public EchoFunction(XQueryContext context) {
    super(context, signature);
}

public Sequence eval(Sequence[] args, Sequence contextSequence)
throws XPathException {
    // is argument the empty sequence?
    if (args[0].getLength() == 0)
        return Sequence.EMPTY_SEQUENCE;
    // iterate through the argument sequence and echo each item
    ValueSequence result = new ValueSequence();
    for (SequenceIterator i = args[0].iterate(); i.hasNext();) {
        String str = i.nextItem().getStringValue();
        result.add(new StringValue("echo: " + str));
    }
    return result;
}
}
```

In looking at this sample, first note that every function class has to provide a function *signature*. The function signature defines the *QName* by which the function is identified, a documentation string, the sequence types of all arguments, and the sequence type of the returned value. In the example above, we accept a single argument named "text" of type `xs:string` and a cardinality of `ZERO_OR_MORE` with the description "The text to echo". In other words, we accept any sequence of strings containing zero or more items. The return value is of type `xs:string` and a cardinality of `ZERO_OR_MORE` with the description "the echoed text". **Note:** The parameter description should be normal sentence starting with a capital letter. The return value description is always prepended with "Returns ", so have the text to match.

Next, the subclass overwrites the `eval` method, which has two arguments: the first contains the values of all arguments passed to the function, the second passes the current context sequence (which might be null). Note that the argument values in the array `args` have already been checked to match the sequence types defined in the function signature. We therefore do not have to recheck the length of the array: if more or less than one argument were passed to the function, an exception would have been thrown before eval gets called.

In XQuery, all values are passed as sequences. A sequence consists of one or more items, and every item is either an atomic value or a node. Furthermore, a single item is also a sequence. The function signature specifies that any sequence containing zero or more strings is acceptable for our method. We therefore have to check if the empty sequence has been passed. In this case, the function call returns immediately. Otherwise, we iterate through each item in the sequence, prepend `echo:`" to its string value, and add it to the result sequence.

In the next step, we want to add the function to a new module, and therefore provide a driver class. The driver class defines a namespace URI and a default prefix for the module. Functions are registered by passing an array of `FunctionDef` to the constructor. The following is an example driver class definition:

``` java
public class ExampleModule extends AbstractInternalModule {

public final static String NAMESPACE_URI = 
    "http://exist-db.org/xquery/examples";
    
public final static String PREFIX = "example";
    
private final static FunctionDef[] functions = {
    new FunctionDef(EchoFunction.signature, EchoFunction.class)
};
    
public ExampleModule() {
    super(functions);
}

public String getNamespaceURI() {
    return NAMESPACE_URI;
}

public String getDefaultPrefix() {
    return PREFIX;
}

}
```

Finally, we are able to use this newly created module in an XQuery script:

``` xquery

xquery version "1.0";

import module namespace example="http://exist-db.org/xquery/examples"
at "java:org.exist.examples.xquery.ExampleModule";

example:echo(("Hello", "World!"))
```

The query engine recognizes the `java:` prefix in the location URI, and treats the remaining part (in this case, `org.exist.examples.xquery.ExampleModule`) as a fully qualified class name leading to the driver class of the module.

## Collations

Collations are used to compare strings in a *locale-sensitive* fashion. XQuery allows one to specify collations at several places by means of a collation URI. For example, a collation can be specified in the `order
                    by` clause of a XQuery FLWOR expression, as well as any string-related functions. However, the concrete form of the URI is defined by the eXist-db implementation. Specifically, eXist-db recognizes the following URIs:

1.  http://www.w3.org/2005/xpath-functions/collation/codepoint
    This URI selects the unicode codepoint collation. This is the default if no collation is specified. Basically, it means that only the standard Java implementations of the comparison and string search functions are used.

2.  http://exist-db.org/collation?lang=xxx&strength=xxx&decomposition=xxx
    or, in a simpler form:

    ?lang=xxx&strength=xxx&decomposition=xxx
    The `lang` parameter selects a locale, and should have the same form as in `xml:lang`. For example, we may specify "de" or "de-DE" to select a german locale.

    The `strength` parameter (optional) value should be one of "primary", "secondary", "tertiary" or "identical".

    The decomposition parameter (optional) has the value of "none", "full" or "standard".

The following example selects a german locale for sorting:

for $w in ("das", "daß", "Buch", "Bücher", "Bauer", "Bäuerin", "Jagen", "Jäger") order by $w collation "?lang=de-DE" return $w
And returns the following:

Bauer, Bäuerin, Buch, Bücher, das, daß, Jagen, Jäger
You can also change the default collation:

declare default collation "?lang=de-DE"; "Bäuerin" &lt; "Bier"
Which returns `true`. Note that if you use the default codepoint collation instead, the comparison would evaluate to `false`.

> **Note**
>
> eXist-db's range index is currently only usable with the default codepoint collation. This means that comparisons using a different collation will not be index-assisted and will thus be slow. Collation-aware indexes may be added in the future.

## Serialization Options

The serialization of query results into a binary stream is influenced by a number of parameters. These parameters can be set within the query itself, however the interpretation of the parameters depends on the context in which the query is called. Most output parameters are applicable only if the query is executed using the XQueryGenerator or XQueryServlet servlets, or the REST server.

In XQuery 1.0, serialization parameters were implementation defined, and eXist-db developed its own set of parameters. In XQuery 3.0, serialization is standardized in the [specification](http://www.w3.org/TR/xslt-xquery-serialization-30/).

### Serialization in XQuery 1.0

In XQuery 1.0, serialization parameters can be set by `declare
                        option` statement in the query prolog. In `declare
                        option`, the serialization parameters can be specified as follows:

declare option exist:serialize "method=xhtml media-type=application/xhtml+html";
Here, single options are specified within the string literal, separated by a whitespace. Note also that the option QName must be `exist:serialize`, where the `exist` prefix is bound to the namespace <http://exist.sourceforge.net/NS/exist>, which is declared by default and need not be specified explicitly.

Note that these same options can be passed using the XPathQueryService.setProperty() and XQueryService.setProperty() methods in Java. These methods are defined in `
                        javax.xml.transform.OutputKeys
                    ` and `
                        EXistOutputKeys
                    `. The latter eXist-specific options include the following:

`expand-xincludes= yes | no`  
should the serializer expand XInclude elements?

`highlight-matches= both | elements | attributes | none`  
when querying text with the full text or n-gram extensions, the query engine tracks the exact position of all matches inside text content. The serializer can later use this information to mark those matches by wrapping them into an element exist:match.

Setting `highlight-matches=both` will enable this feature for every kind of indexable node.

`process-xsl-pi= yes | no`  
if a document is serialized and it has an XSL processing instruction, eXist-db can try to load the referenced stylesheet and apply it to the document.

`add-exist-id= element | all | none`  
shows the internal node ids of an element by adding an attribute `exist:id="internal-node-id"`. Setting add-exist-id to "element" will only show the node id of the top-level element, "all" will show the ids of all elements.

The general options include the following:

`method= xml | xhtml | json | text`  
determines the serialization method. Should be one of "xml", "xhtml", "json", or "text". The "xhtml" method makes sure that XHTML elements with an empty content model are serialized in the minimized form, i.e. `img` will be output as img/.

`jsonp= myFunctionName`  
Only relevant when the serialization method is set to 'json'. Causes the JSON output to be wrapped in the named JSONP function.

`media-type`  
The MIME content type of the output. It will mainly be used to set the HTTP Content-Type header (if the query is running in an HTTP context).

`encoding`  
specifies the character encoding to be used for outputting the instance of the data model

`doctype-public`  
a doctype declaration will be output if doctype-public and/or doctype-system are set. The corresponding identifier is taken from the value of the parameter.

`doctype-system`  
a doctype declaration will be output if doctype-public and/or doctype-system are set. The corresponding identifier is taken from the value of the parameter.

`indent= yes | no`  
indent the document to make it easier to read. Indenting adds whitespace characters to element nodes, restricted by the rules given in the XQuery serialization spec.

`omit-xml-declaration= yes | no`  
output an XML declaration if the parameter is set to "no"

For example, to disable XInclude expansion, and indent the output, you can use the following syntax:

declare option exist:serialize "expand-xincludes=no";
For the output method parameter, eXist-db currently recognizes three methods: `xml`, `xhtml` and `text`. Note that unlike the xml method, the xhtml setting uses only the short form for elements that are declared empty in the xhtml DTD. For example, the `br` tag is always returned as &lt;br/&gt;. On the other hand, the text method only returns the contents of elements - for instance, &lt;A&gt;Content&lt;/A&gt; is returned as `Content`. However, attribute values, processing instructions, comments, etc. are all ignored.

### Serialization in XQuery 3.0

XQuery 3.0 version of the language provides a standard way to set serialization parameters. The old, non-standard approach in eXist-db was to use a single option with all parameters in the value: declare option exist:serialize "method=json media-type=application/json"; The standard way of doing this in XQuery 3.0 would be: declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization"; declare option output:method "json"; declare option output:media-type "application/json";

The old approach is still supported for backwards compatibility. The parameter names remain the same as well.

## Pragmas

XQuery pragmas are a way to pass implementation-specific information to the query engine from within a XQuery. The syntax for pragmas has changed between the different drafts of the XQuery specification. In earlier eXist-db releases, pragmas were used similar to what is now the "declare option" prolog expression. The new syntax is quite different: pragmas can now be wrapped around an arbitrary XQuery expression (see the [specification](http://www.w3.org/TR/xquery/#id-extension-expressions)).

Currently, eXist-db recognizes the following pragmas:

### exist:timer

Provides a simple way to measure the time for executing a given expression. For example:

(\# exist:timer \#) { //some/path/expression }
creates a timer for the expression enclosed in curly braces and prints timing information to the trace logger. Please note that trace needs to be enabled in `log4j.xml`:

                            <root>
        <priority value="trace"/>
        <appender-ref ref="console"/>
    </root>
                        

### exist:batch-transaction

*Currently only for XQuery Update Extensions.* Provides a method for batching updates on the database into a single Transaction, allowing a set of updates to be atomically guaranteed. Also for each affected document or collection, any configured Triggers will only be called once, the prepare() method will be fired before the first update to the configured resource and the finish() method fired after the last update to the configured resource.

(\# exist:batch-transaction \#) { update value //some/path/expressionA width "valueA", update value //some/path/expressionB width "valueB" }
Uses a single Transaction and Trigger events for the expressions enclosed in curly braces.

### exist:force-index-use

*For debugging purposes*. An expression that can be assisted by indexes: comparisons, `fn:matches()`... Will raise an error if, for any reason, this assistance can not be performed.

This can help to check whether the indexes are correctly defined or not.

(\# exist:force-index-use \#) { //group\[. = "dba"\] }
Raises an error (currently *XPDYxxxx* since this kind of dynamic error is not yet defined by the XQuery specifications) if the general comparison doesn't use a range or a QName index.

### exist:no-index

This prevents the query engine to use the index in expressions that can be assisted by indexes: comparisons, `fn:matches()`... Useful if the searched value isn't very selective or if it is cheaper to traverse the previous step of a path expression than querying the index.

(\# exist:no-index \#) { //group\[. = "dba"\] }
### exist:optimize

For testing only. This pragma is normally inserted automatically by the query rewriter (if enabled) to optimize an expression that implements the `org.exist.xquery.Optimizable` interface.

//((\#exist:optimize\#) { item\[stock = 10\] })
We will certainly add more pragma expressions in the near future. Among other things, pragmas are a good way to pass optimization hints to the query engine.

## Other Options

To prevent the server from being blocked by a badly formulated query, eXist-db watches all query threads. A blocking query can be killed if it takes longer than a specified amount of time or consumes too many memory resources on the server. There are two options to control this behaviour:

declare option exist:timeout "time-in-ms";
Specifies the maximum amount of query processing time (in ms) before it is cancelled by the XQuery engine.

declare option exist:output-size-limit "size-hint";
Defines a limit for the max. size of a document fragment created within an XQuery. The limit is just an estimation, specified in terms of the accumulated number of nodes contained in all generated fragments. This can be used to prevent users from consuming too much memory if they are allowed to pass in their own XQueries.

declare option exist:implicit-timezone "duration";
Specifies the [implicit timezone](http://www.w3.org/TR/xquery/#dt-timezone) for the XQuery context.

declare option exist:current-dateTime "dateTime";
Specifies the [current dateTime](http://www.w3.org/TR/xquery/#GLdt-date-time) for the XQuery context.

declare option exist:optimize "enable=yes|no";
Temporarily disables the query rewriting optimizer for the current query. Use for testing/debugging.
