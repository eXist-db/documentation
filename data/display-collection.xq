xquery version "1.0";
(:Used as example in xinclude.xml:)
let $current-doc := $xinclude:current-doc
let $current-collection := $xinclude:current-collection
return
('This document, ', $current-doc, ', is in the ', $current-collection, ' collection')