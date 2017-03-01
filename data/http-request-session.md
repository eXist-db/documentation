# HTTP-Related Functions in the request and session Modules

## Introduction

The request module (in the <http://exist-db.org/xquery/request> function namespace) contains functions for handling HTTP request parameters. The session module (in the <http://exist-db.org/xquery/session> function namespace) contains functions for handling HTTP session variables. Functions in these namespaces are only usable if the query is executed through the XQueryGenerator or the XQueryServlet (for more information consult eXist-db's [Developer's Guide](devguide.md) ).

request:get-parameter(*name*, *default value*)  
This HTTP function expects two arguments: the first denotes the name of the parameter, the second specifies a default value, which is returned if the parameter is not set. This function returns a sequence containing the values for the parameter. The above script (Adding/Subtracting Two Numbers) offers an example of how `request:get-parameter` can be used to read HTTP request parameters.

request:get-uri()  
This function returns the URI of the current request. To encode this URI using the current session identifier, use the following function:

session:encode-url(request:get-uri())

session:create()  
This function creates a new HTTP session if none exists.

Other session functions read and set session attributes, among other operations. For example, an XQuery or Java object value can be stored in a session attribute, to cache query results. For more example scripts, please look at our [Examples]({demo}/examples/web/index.html) page, under the XQuery Examples section.
