xquery version "3.0";

module namespace diag="http://exist-db.org/xquery/diagnostics";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare function diag:prepare($node as node(), $model as map(*)) {
    let $ulinks := collection($config:data-root)//ulink
    return
        map { "ulinks" := $ulinks } 
};

declare function diag:countulinks($node as node(), $model as map(*)) {
  let $ulinks := $model("ulinks")
  return count($ulinks)
};


declare %private function diag:filterlocallinks($ulinks as node()*){

    for $ulink in $ulinks
    let $url :=  normalize-space(string(data($ulink/@url)))
    return
        if( starts-with($url, "http:") or starts-with($url, "https:") or starts-with($url, "mailto:") or
        starts-with($url, "/")   or starts-with($url, "#") or $url eq "" or  starts-with($url, "{") 
        or  starts-with($url, "api") or starts-with($url, "irc:"))
        then
        ()
        else
        $ulink

};

declare %private function diag:cleanUrl($url as xs:string) as xs:string {

    let $rawurl :=  normalize-space($url)
    return if (contains($rawurl, "#"))
        then
            substring-before($rawurl, "#")
        else
            $rawurl
        
};

declare function diag:deadlinks($node as node(), $model as map(*)) {
  let $ulinks := $model("ulinks")
  let $filtered := diag:filterlocallinks($ulinks)
  return
  <table>
  <tr><th>In document</th><th>Linked document</th></tr>
  {
     for $row in $filtered
     let $url := data($row/@url)
     return
     if(doc-available($config:data-root || "/" || $url))
     then
     ()
     else
     <tr><td>{document-uri(root($row))}</td><td>{data($row/@url) }</td></tr>
  }
  </table>
};

declare function diag:unreferenced($node as node(), $model as map(*)) {
  let $ulinks := $model("ulinks")
  
  let $alldocs := xmldb:get-child-resources($config:data-root)
  return
  <table>
  <tr><th>Document</th></tr>
  {
  for $doc in $alldocs
  return 
    if($ulinks/@url = $doc)
    then
        ()
    else
        <tr><td><a href="{$doc}">{$doc}</a></td></tr>
  }
  </table>
  
  };
  
  
