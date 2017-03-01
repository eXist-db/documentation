# xqDoc

## Introduction

xqDoc comments are used to document XQuery library and main modules in a manner similar to how Javadoc comments are used to document Java classes and packages. With the documentation close to the source, it increases the chances that the documentation will be kept current and with tools provided by xqDoc, useful documentation can be quickly and easily generated. It should be noted that a XQuery module does not need to contain xqDoc style comments in order for the xqDoc tools to produce useful output. Without any xqDoc documentation style comments, a very useful cross reference (for modules, functions, and variables) and XQuery code browser (for modules and functions) will be created by the xqDoc tools.

xqDoc comments are extracted when eXist parses an XQuery and keeps them with the FunctionSignature. To not slow down the parsing, comments are stored as plain strings. The comments can be parsed and merged into the function signature later, if they are needed. This would allow tools like eXide to display up to date documentation while you are working on a module.

## Comment Style

xqDoc style comments begin with a  '(:~'  and end with a  ':)' . Of course,  '(::'  would have been preferable to indicate the beginning of an xqDoc style comment (since it mimics the JavaDoc style of  '/\*\*' ) but we didn't want to cause confusion with an XQuery pragma (since this decision was made, the definition for XQuery pragma has been changed). The choice for the begin pattern is really quite arbitrary. In any case, one xqDoc style comment can be specified before each of the following rules (based on the W3C XQuery 1.0 BNF) for library modules and main modules.

Library Modules

-   Module Declaration

-   Module Import

-   Variable Definition

-   Function Definition

Main Modules

-   Main Module

-   Module Import

-   Variable Definition

-   Function Definition

Like Javadoc, the following tags have special meaning within an xqDoc comment. In addition, the values provided for each of the tags can contain embedded XHTML markup to enhance or emphasize the xqDoc XHTML presentation. However, make sure the content is well formed and that entities are used (i.e. &amp; instead of &). The beginning text (up to the first tag) is assumed to be description text for the component being documented.

### @author

The @author tag identifies the author for the documented component. Zero or more @author tags can be specified (one per author)

``` xquery
(:~
@author Darin McBeath
:)
```

### @version

The @version tag identifies the version of the documented component. Zero or more @version tags can be specified (one per version) but in reality only a single @version tag would normally make sense. The value for the @version tag can be an arbitrary string.

``` xquery
(:~
@version 1.0
:)
```

### @since

The @since tag identifies the version when a documented component was supported. Zero or many @since tags can be specified, but in reality only a single @since tag would normally make sense. The value for the @since tag can be an arbitrary string but should likely match an appropriate version value.

``` xquery
(:~
@since 1.0
:)
```

### @see

The @see tag provides the ability to hypertext link to an external web site, a library or main module contained in xqDoc, a specific function (or variable) defined in a library or main module contained in xqDoc, or arbitrary text. To link to an external site, use a complete URL such as http://www.xquery.com. To link to a library or main module contained in xqDoc, simply provide the URI for the library or main module. To link to a specific function (or variable) defined in an xqDoc library or main module, simply provide the URI for the library or main module followed by a ';' and finally the function or variable name. To provide a *name* for a link, simply include a second ';' followed by the name. To provide text, simply include the 'text'. Multiple @see tags can be specified (one per link or string of text).

``` xquery
(:~
@see http://www.xquery.com
@see xqdoc/xqdoc-display
@see xqdoc/xqdoc-display;build-link
@see xqdoc/xqdoc-display;$months
@see xqdoc/xqdoc-display;$months;month variable
@see http://www.xquery.com;;xquery
@see some text
:)
```

### @param

The @param tag identifies the parameters associated with a function. For each parameter in a function, there should be a @param tag. The @param tag should be followed by the parameter name (as indicated in the function signature) and then the parameter description.

``` xquery
(:~
@param $name The username
:)
```

### @return

The @return tag describes what is returned from a function. Zero or one @return tags can be specified.

``` xquery
(:~
@return Sequence of names matching the search criteria
:)
```

### @deprecated

The @deprecated tag identifies the identifies the documented component as being deprecated. The string of text associated with the @deprecated tag should indicate when the item was deprecated and what to use as a replacement.

``` xquery
(:~
@deprecated As of 1.0 and replaced with add-user
:)
```

### @error

The @error tag identifies the types of errors that can be generated by the function. Zero or more @error tags can be specified. An arbitrary string of text can be provided for a value.

``` xquery
(:~
@error The requested URI does not exist
:)
```

## A representative library module comment

This comment would precede the module declaration statement for the library module.

``` xquery
  (:~ 
 : This module provides the functions that control the Web presentation
 : of xqDoc. The logic contained in this module is not specific to any
 : XQuery implementation and is written to the May 2003 XQuery working
 : draft specification. It would be a trivial exercise to convert this
 : code to either the Nov 2003 or Oct 2004 XQuery working draft.
 :
 : It should also be noted that these functions not only support the 
 : real-time presentation of the xqDoc information but are also used
 : for the static offline presentation mode as well. The static offline
 : presentation mode has advantages because access to a native XML
 : database is not needed when viewing the xqDoc information ... it is
 : only needed when generating the offline materials. 
 :
 : @author Darin McBeath
 : @version 1.0
 :)
module "xqdoc/display"
```

## A representative library module function comment

This comment would precede the function declaration statement in the library module.

``` xquery
  (:~ 
 : The controller for constructing the xqDoc HTML information for
 : the specified library module. The following information for
 : each library module will be generated.
 : <ul>
 : <li> Module introductory information</li>
 : <li> Global variables declared in this module</li>
 : <li> Modules imported by this module</li>
 : <li> Summary information for each function defined in the module</li>
 : <li> Detailed information for each function defined in the module</li>
 : </ul>
 :
 : @param $uri the URI for the library module
 : @param $local indicates whether to build static HTML link for offline
 : viewing or dynamic links for real-time viewing.
 : @return XHTML.
 :)
define function print-module($uri as xs:string, $local as xs:boolean) as element()*
```
