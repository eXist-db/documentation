xquery version "3.1";

(:~ This library module contains XQSuite tests for the documentation app.
 :
 : @author eXist-db
 : @version 1.0.0
 :)

module namespace tests = "http://exist-db.org/xquery/documentation/tests";
declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace docbook = "http://docbook.org/ns/docbook" at "docbook.xql";
import module namespace config = "http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace diag = "http://exist-db.org/xquery/diagnostics" at "diagnostics.xql";

declare namespace db5 = "http://docbook.org/ns/docbook";

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
