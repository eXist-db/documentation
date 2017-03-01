# The util module

## Introduction

The util module (function namespace <http://exist-db.org/xquery/util>) contains a number of common utility functions, such as `util:md5`, which can generate md5 hashes. The full list of functions and their documentation is in the [Function Documentation Library](/exist/apps/xqfdocs). This article discusses some of the highlights and main uses for this module.

## util:eval()

util:eval()  
This function is used to dynamically execute a constructed XQuery expression inside a running XQuery script. This can be very handy in some cases - for example, web-based applications that dynamically generate queries based on HTTP request parameters the user has passed.

By default, the dynamically executed query inherits most of the current context, including local variables:

let $a := "Hello" return util:eval("$a")

Consider the following simple example script in which any two numbers submitted by a user are added or subtracted:

``` xquery
xquery version "1.0";

declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";

declare function local:do-query() as element() {
    let $n1 := request:get-parameter("n1", "")
    let $n2 := request:get-parameter("n2", "")
    let $op := request:get-parameter("op", "")
    return
        if($n1 = "" or $n2 = "") then
            <p>Please enter two operands.</p>
        else
            let $query := concat($n1, " ", $op, " ", $n2)
            return
                <p>{$query} = {util:eval($query)}</p>
};

<html>
    <body>
        <h1>Enter two numbers</h1>

        <form action="{request:get-uri()}" method="get">
            <table border="0" cellpadding="5">
            <tr>
                <td>First number:</td>
                <td><input name="n1" size="4"/></td>
            </tr>
            <tr>
                <td>Operator:</td>
                <td>
                    <select name="op">
                        <option name="+">+</option>
                        <option name="-">-</option>
                    </select>
                </td>
            </tr>
            <tr>
                <td>Second number:</td>
                <td><input name="n2" size="4"/></td>
            </tr>
            <tr>
                <td colspan="2"><input type="submit"/></td>
            </tr>
            </table>
        </form>

        { local:do-query() }
        
    </body>
</html>
```

In this example, there is one XQuery script responsible for evaluating the user-supplied parameters, which uses the parameters from the HTTP request to construct another XQuery expression, which it then passes to `util:eval` for evaluation. The application would then post-process the returned results, and display them to the user. (For more information on how to write web applications using XQuery, go to our [Developer's Guide](devguide.md).)
