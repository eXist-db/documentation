xquery version "1.0";
(:Used as example in xinclude.xml:)
declare namespace xdb="http://exist-db.org/xquery/xmldb";
declare namespace util="http://exist-db.org/xquery/util";

declare namespace display="display-collection";

declare variable $var1 external;
declare variable $var2 external;

<p>{$var1, $var2}</p>