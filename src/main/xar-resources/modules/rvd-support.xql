xquery version "3.0";
(:============================================================================:)
(:==
  Module with support functions for the review and diagnostics.
==:)
(:============================================================================:)
(:== PROLOG: ==:)

module namespace rvds="http://exist-db.org/xquery/rvd-support";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare variable $rvds:link-article as xs:string := 'Article' ;
declare variable $rvds:link-external as xs:string := 'External' ;
declare variable $rvds:link-resource as xs:string := 'Resource' ;
declare variable $rvds:link-computed as xs:string := 'Computed' ;
declare variable $rvds:link-unknown as xs:string := 'Unknown' ;

(:============================================================================:)
(:== PUBLIC FUNCTIONS: ==:)

declare function rvds:get-link-type($link as xs:string) as xs:string
{
  let $link-no-anchor := rvds:link-no-anchor($link)
  return
    if (starts-with($link, '/'))
      then $rvds:link-unknown
    else if (contains($link, '{'))
      then $rvds:link-computed
    else if (starts-with($link, 'http://') or starts-with($link, 'https://') or starts-with($link, 'mailto:'))
      then $rvds:link-external
    else if (contains($link-no-anchor, '/'))
      then $rvds:link-resource
    else if (ends-with($link, '.xml') or not(contains($link, '.')))
      then $rvds:link-article
    else
      $rvds:link-unknown
};

(:----------------------------------------------------------------------------:)

declare function rvds:link-no-anchor($link as xs:string) as xs:string
{
  if (contains($link, '#'))
    then substring-before($link, '#')
    else $link
};

(:----------------------------------------------------------------------------:)

declare function rvds:link-anchor($link as xs:string) as xs:string
{
  if (contains($link, '#'))
    then substring-after($link, '#')
    else ''
};

(:----------------------------------------------------------------------------:)

declare function rvds:get-path-component($link as xs:string) as xs:string
{
  if (contains($link, '/'))
    then replace($link, '(.*)/[^/]+$', '$1')
    else ''
};

(:----------------------------------------------------------------------------:)

declare function rvds:get-name-component($link as xs:string) as xs:string
{
  tokenize($link, '/')[last()]
};

(:----------------------------------------------------------------------------:)

declare function rvds:anchor-exists($doc as document-node(), $anchor as xs:string) as xs:boolean
{
  $anchor = data($doc//@xml:id)
};

(:============================================================================:)
