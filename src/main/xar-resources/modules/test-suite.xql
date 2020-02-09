xquery version "3.1";

(:~ This library module contains XQSuite tests for the documentation app.
 :
 : @author eXist-db
 : @version 1.0.0
 :)

module namespace tests = "http://exist-db.org/xquery/documentation/tests";

import module namespace docbook = "http://docbook.org/ns/docbook" at "docbook.xql";
import module namespace config = "http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace diag = "http://exist-db.org/xquery/diagnostics" at "diagnostics.xql";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace db5 = "http://docbook.org/ns/docbook";
declare namespace xlink = "http://www.w3.org/1999/xlink";

(:~ Minimal article from the docs with inline element in next title
 : @see  author-reference.xml :)
declare variable $tests:article := document {
<article xmlns="http://docbook.org/ns/docbook" xmlns:xlink="http://www.w3.org/1999/xlink" version="5.0">
    <info>
        <title>Document title</title>
        <date>1Q18</date>
        <keywordset>
          <keyword>blah</keyword>
        </keywordset>
    </info>
    <para>Introductory paragraph(s)</para>
    <sect1 xml:id="main-id">
        <title>Title of first main section</title>
        <para>Lorem ipsum main</para>
        <sect2 xml:id="sub-id">
            <title>Title of first sub-section</title>
            <para>Lorem ipsum sub</para>
            <sect3 xml:id="subsub-id">
                <title>Title of first subsub-section</title>
                <para>Lorem ipsum subsub</para>
            </sect3>
        </sect2>
    </sect1>
    <sect1 xml:id="next-id">
        <title>Title of <tag>second</tag> main section</title>
        <para>Lorem ipsum next</para>
    </sect1>
</article>

};

(:~ see if all sections have an ID (now inforced via schema)
 : @return empty-sequence otherwise name of document with faulty section
 :)
declare
%test:name('section-headings')
%test:assertEmpty
function tests:missing-id() {

    let $no-id := distinct-values(
    for $n in collection($config:data-root)//db5:article/db5:sect1 | collection($config:data-root)//db5:article//db5:sect2 | collection($config:data-root)//db5:article//db5:sect3
    return
        if ($n/@xml:id) then
            ()
        else
            (util:document-name($n))
    )

    for $m in $no-id
        order by $m
    return
        $m
};

(:~ Run the diagnose listings page and see if there are new Errors
 : @return empty-sequence, otherwise name of listing and parent collection
 :)
declare
%test:name('diagnose listings')
%test:assertEmpty
function tests:orphan-listing() {
  let $report := diag:diagnose(<root/>, map{1: 1})
  let $error := $report//ul//span[. eq '*ERROR* ']
  let $error-msg := count($error)
  let $list :=  $error/ancestor::tr//code[1]
  return
    if ($error-msg > 0)
    then (
      for $l in $list
      return
        $l || ' is missing in ' || $l/ancestor::li/h3/code)
    else ()
};

(:~ See if ToC rendering is WAI  :)
declare
%test:name('ToC rendering')
%test:assertTrue
function tests:toc-inline() {
  let $output := <ul class="toc">
      <li>
          <a href="#main-id">Title of first main section</a>
          <ul>
              <li>
                  <a href="#sub-id">Title of first sub-section</a>
              </li>
          </ul>
      </li>
      <li>
          <a href="#next-id">Title of second main section</a>
      </li>
      <button class="btn btn-outline-primary btn-sm btn-block">
          <a href="https://github.com/eXist-db/documentation/issues/new?title=error on Document title">Improve this article</a>
      </button>
  </ul>
return
    docbook:toc-db5($tests:article) eq $output
};

(:~ Check if two listings that should be identical actually are.
 : Txt and xml listings cannot be easily displayed via <xref> or xinclude
 : so unfortunately this is necessary, to avoid conflicting information.
 :
 : @see author-reference
 : @return true (hopefully)
 :)
declare
%test:name('Listing consistency')
%test:args('backup/listings/listing-3.xml.','configuration/listings/listing-6.xml')
%test:assertTrue
function tests:equal-listing($path1 as xs:string, $path2 as xs:string) as xs:boolean {
    let $a := $config:data-root || $path1
    let $b := $config:data-root || $path2
    return
    deep-equal(doc($a), doc($b))
};

(:~ Make sure that programlistings for xml do not contain string contents
 : use <tag> for short snippets, listing-x.xml files for trees.
 : @see author-reference
 : @return empty-sequence or name of document with faulty listing
 :)
declare
%test:name('Pro angular brackets')
%test:assertEmpty
function tests:no-ecaped-listings() {
  let $target := collection($config:data-root)//db5:programlisting[@language='xml']

let $cdata := for $n in $target
                let $title := $n/ancestor::db5:article/db5:info/db5:title
                return
                    if ($n/string() eq '')
                    then ()
                    else (util:document-name($title))

return
    distinct-values($cdata)
};

(:~ Check if listings marked as xml are well-formed and stored as xml.
 : While it is sometimes necessary to store xml as txt that is not well : formed, limiting this to when necessary helps us keep examples valid.
 :)
declare
%test:name('wellformed xml')
%test:assertEmpty
%test:pending
function tests:no-txt-xmls() {
  (: TODO check saxOpts to prevent unescaping of &amp; and use parse-xml to check if text files are well-formed :)
let $target := collection($config:data-root)//db5:programlisting[@language='xml']

let $txtxml := for $n in $target
                let $title := $n/ancestor::db5:article/db5:info/db5:title
                let $format := data($n/@xlink:href)
                return
                    if (ends-with($format, '.xml'))
                    then ()
                    else (util:document-name($title) || ' in ' || substring-after($format, 'listings/'))
return
    $txtxml
};
