xquery version "3.0";

import module namespace mdh="http://exist-db.org/xquery/apps/markdown-helper" at "modules/md-helper.xql";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

let $data-dir := $target || '/data/'
for $uri in xmldb:get-child-resources($data-dir) ! ($data-dir || .)
return
    mdh:md-to-html($uri) 