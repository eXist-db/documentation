xquery version "3.1";

module namespace mdh="http://exist-db.org/xquery/apps/markdown-helper";

import module namespace console="http://exist-db.org/xquery/console";
import module namespace markdown="http://exist-db.org/xquery/markdown";

declare function mdh:log-event($type as xs:string, $event as xs:string, $object-type as xs:string, $uri as xs:string) {
    console:log(<trigger event="{string-join(($type, $event, $object-type), "-")}" uri="{$uri}"/>)
};

declare function mdh:md-to-html($uri as xs:string) {
    let $mode := "html"
    let $config := 
        (
            $markdown:HTML-CONFIG, 
            map {
                "code-block": function($language as xs:string, $code as xs:string) {
                    <div class="code" data-language="{$language}">{$code}</div>
                },
                "heading": function($level as xs:int, $content) {
                    element { "h" || $level } {
                        attribute id { lower-case(replace($content, "[\W]+", "-")) },
                        $content
                    }
                }
            }
        )
    let $inputDoc := util:binary-doc($uri)
    let $input := util:binary-to-string($inputDoc)
    return
        try {
            let $pages := xmldb:create-collection("/db/apps/doc", "pages")
            let $content := markdown:parse($input, $config)
            let $filename := replace(replace($uri, "^.+?/([^/]+)$", "$1"), ".md", ".xml")
            let $store := xmldb:store($pages, $filename, $content)
            return
                console:log("parsed " || $uri || " and converted to " || $store)
        } catch * {
            console:log(concat("failed to parse " || $uri || ": " || $err:code, ": ", $err:description, ' (', $err:module, ' ', $err:line-number, ':', $err:column-number, ')'))
        }
};