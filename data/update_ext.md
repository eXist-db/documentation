# XQuery Update Extension

## Introduction

eXist-db provides an extension to XQuery for updating nodes in the database. The extension makes the following operations possible using a simple syntax: insert, delete, replace, update value, and rename.

## Important Considerations

### Relationship to W3C Recommendation

This extension was created well before the W3C working group created the [XQuery Update Facility 1.0](http://www.w3.org/TR/xquery-update-10/) recommendation, and it differs substantially from the recommendation. However, it remains perfectly functional and is still the primary method (besides [XUpdate](http://xmldb-org.sourceforge.net/xupdate/)) for updating nodes.

### Persistent Document Updates

The XQuery update extension has been designed around updating *persistent* documents stored in the database. It is not suitable for updating temporary document fragments constructed within an query, i.e., you can't use it to modify the results returned by a query. For example, the following query has no visible effect because it operates on an XML node constructed in-memory:

let $node := &lt;root&gt;&lt;a/&gt;&lt;/root&gt; return update insert &lt;b/&gt; into $node/a
Since $node is an in-memory constructed element, rather than a node stored in the database, the query has no effect and simply returns the empty element.

## Update Syntax

All update statements start with the keyword "update", followed by an update action. Available actions are: "insert", "delete", "replace", "value" and "rename". The return type of the expression is `empty()`.

An update statement may occur at any position within the XQuery main code or a function body.

> **Warning**
>
> When using an update within the return clause of a FLWOR expression, be cautious when deleting or replacing nodes that are still being used by enclosing code. This is because a delete or replace will be processed immediately, and the deleted or replaced node will no longer be available to the query. Such actions can corrupt the database. For example, the following expression will throw the database into an inconsistent state if //address returns more than one node:
>
> ``` xquery
> for $address in //address
> return
>     update delete //address
> ```
>
> However, an expression like the following is safe as it only modifies the current iteration variable (note that the following example deletes $address (the current iteration variable) rather than //address (all addresses in the database, including others that have not been deleted yet):
>
> ``` xquery
> for $address in //address
> return
>     update delete $address
> ```
>
> Aside from this caveat, eXist-db's XQuery update extension is safe to use.

### Insert

update insert expr ( into | following | preceding ) exprSingle
Inserts the content sequence specified in expr into the element node passed via exprSingle. exprSingle and expr should evaluate to a node set. If exprSingle contains more than one element node, the modification will be applied to each of the nodes. The position of the insertion is determined by the keywords "into", "following" or "preceding":

into  
The content is appended after the last child node of the specified elements.

following  
The content is inserted immediately after the node specified in exprSingle.

preceding  
The content is inserted before the node specified in exprSingle.

``` xquery
update insert <email type="office">andrew@gmail.com</email> into //address[fname="Andrew"]
```

``` xquery
update insert attribute type {'permanent'} into //address[fname="Andrew"]
```

### Replace

update replace expr with exprSingle
Replaces the nodes returned by expr with the nodes in exprSingle. expr may evaluate to a single element, attribute or text node. If it is an element, exprSingle should contain a single element node as well. If it is an attribute or text node, the value of the attribute or the text node is set to the concatenated string values of all nodes in exprSingle. expr cannot be the root element of a document.

``` xquery
update replace //fname[. = "Andrew"] with <fname>Andy</fname>
```

### Value

update value expr with exprSingle
Updates the content of all nodes in expr with the items in exprSingle. If expr is an attribute or text node, its value will be set to the concatenated string value of all items in exprSingle.

``` xquery
update value //fname[. = "Andrew"] with 'Andy'
```

### Delete

update delete expr
Removes all nodes in expr from their document. expr cannot be the root element of a document.

``` xquery
for $city in //address/city 
return
    update delete $city
```

### Rename

update rename expr as exprSingle
Renames the nodes in expr using the string value of the first item in exprSingle as the new name of the node. expr should evaluate to a set of elements or attributes. expr cannot be the root element of a document.

``` xquery
for $city in //address/city 
return
    update rename $city as 'locale'
```
