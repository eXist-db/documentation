xquery version "3.1";

(:
    A simple XQuery for an XQueryTrigger that
    logs all trigger events for which it is executed
    in the file /db/triggers-log.xml
:)

module namespace trigger="http://exist-db.org/xquery/trigger";

import module namespace markdown="http://exist-db.org/xquery/markdown";
import module namespace mdh="http://exist-db.org/xquery/apps/markdown-helper" at "md-helper.xql";

declare namespace xmldb="http://exist-db.org/xquery/xmldb";

(: 
declare function trigger:before-create-collection($uri as xs:anyURI) {
    mdh:log-event("before", "create", "collection", $uri)
};

declare function trigger:after-create-collection($uri as xs:anyURI) {
    mdh:log-event("after", "create", "collection", $uri)
};

declare function trigger:before-copy-collection($uri as xs:anyURI, $new-uri as xs:anyURI) {
    mdh:log-event("before", "copy", "collection", concat("from: ", $uri, " to: ", $new-uri))
};

declare function trigger:after-copy-collection($new-uri as xs:anyURI, $uri as xs:anyURI) {
    mdh:log-event("after", "copy", "collection", concat("from: ", $uri, " to: ", $new-uri))
};

declare function trigger:before-move-collection($uri as xs:anyURI, $new-uri as xs:anyURI) {
    mdh:log-event("before", "move", "collection", concat("from: ", $uri, " to: ", $new-uri))
};

declare function trigger:after-move-collection($new-uri as xs:anyURI, $uri as xs:anyURI) {
    mdh:log-event("after", "move", "collection", concat("from: ", $uri, " to: ", $new-uri))
};

declare function trigger:before-delete-collection($uri as xs:anyURI) {
    mdh:log-event("before", "delete", "collection", $uri)
};

declare function trigger:after-delete-collection($uri as xs:anyURI) {
    mdh:log-event("after", "delete", "collection", $uri)
};

declare function trigger:before-create-document($uri as xs:anyURI) {
    mdh:log-event("before", "create", "document", $uri)
};
:)

declare function trigger:after-create-document($uri as xs:anyURI) {
    mdh:log-event("after", "create", "document", $uri),
    mdh:md-to-html($uri)
};

(:
declare function trigger:before-update-document($uri as xs:anyURI) {
    mdh:log-event("before", "update", "document", $uri)
};
:)

declare function trigger:after-update-document($uri as xs:anyURI) {
    mdh:log-event("after", "update", "document", $uri),
    mdh:md-to-html($uri)
};

(:
declare function trigger:before-copy-document($uri as xs:anyURI, $new-uri as xs:anyURI) {
    mdh:log-event("before", "copy", "document", concat("from: ", $uri, " to: ", $new-uri))
};

declare function trigger:after-copy-document($new-uri as xs:anyURI, $uri as xs:anyURI) {
    mdh:log-event("after", "copy", "document", concat("from: ", $uri, " to: ", $new-uri))
};

declare function trigger:before-move-document($uri as xs:anyURI, $new-uri as xs:anyURI) {
    mdh:log-event("before", "move", "document", concat("from: ", $uri, " to: ", $new-uri))
};

declare function trigger:after-move-document($new-uri as xs:anyURI, $uri as xs:anyURI) {
    mdh:log-event("after", "move", "document", concat("from: ", $uri, " to: ", $new-uri))
};

declare function trigger:before-delete-document($uri as xs:anyURI) {
    mdh:log-event("before", "delete", "document", $uri)
};

declare function trigger:after-delete-document($uri as xs:anyURI) {
    mdh:log-event("after", "delete", "document", $uri)
};
:)