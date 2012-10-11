xquery version "3.0";

module namespace review = "http://exist-db.org/xquery/documentation/review";

declare %public function review:editorial-view($node as node()*, $model as map(*)) {
    let $articles-collection := '/db/doc/data'
    let $articles := collection($articles-collection)[*]
    (:
    let $resources-collection := '/db/doc/resources'
    let $resources := 
        (
        xmldb:get-child-resources($resources-collection)
        , 
        for $subcol in xmldb:get-child-collections($resources-collection) 
        return 
            for $x in xmldb:get-child-resources(concat($resources-collection, '/',$subcol)) 
            return 
                concat($subcol, '/', $x)
        )
    :)
    let $landing-page-links := doc(concat($articles-collection, '/', 'documentation.xml'))//ulink
    let $order := request:get-parameter('order', 'filename')
    let $sorted-articles :=
        if ($order = 'title') then
            for $article in $articles
            let $title := $article/book/bookinfo/title
            let $filename := util:document-name($article)
            order by $title, $filename
            return $article
        else if ($order = 'dated') then 
            for $article in $articles
            let $dated := $article/book/bookinfo/date
            let $year-month := 
                if ($dated ne '') then
                    let $year := substring-after($dated, ' ')
                    let $month := substring-before($dated, ' ')
                    let $months := ('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')
                    let $month-num := index-of($months, $month)
                    let $padded-month-num := if (string-length($month-num) = 1) then 0 || $month-num else $month-num
                    let $year-month := $year || '-' || $padded-month-num
                    return ($year-month, util:log-system-out($order || $dated || ' > ' || $year-month))
                else ()
            order by $year-month empty greatest
            return $article
        else if ($order = 'in-toc') then
            for $article in $articles
            let $filename := util:document-name($article)
            let $in-toc := $filename = $landing-page-links/@url
            order by $in-toc, $filename
            return $article
        else if ($order = 'size') then
            for $article in $articles
            let $filename := util:document-name($article)
            let $size := xmldb:size($articles-collection, $filename)
            order by $size, $filename
            return $article
        else if ($order = 'svn-rev') then
            for $article in $articles
            let $filename := util:document-name($article)
            let $in-toc := $filename = $landing-page-links/@url
            order by $in-toc
            return $article
        else (: if ($order = 'filename') then :)
            for $article in $articles
            let $filename := util:document-name($article)
            order by $filename
            return $article
    return
        <div>
            <p>{count($articles)} articles in {$articles-collection}, ordered by "{$order}"</p>
            <table class="table table-striped table-bordered table-hover">
                <thead>
                    <tr>
                        <th>{if ($order = 'filename') then <span class="hi">Filename</span> else <a href="?order=filename">Filename</a>} / 
                            {if ($order = 'title') then <span class="hi">Title</span> else <a href="?order=title">Title</a>}</th>
                        <th>{if ($order = 'dated') then <span class="hi">Dated</span> else <a href="?order=dated">Dated</a>}</th>
                        <th>{if ($order = 'in-toc') then <span class="hi">In TOC</span> else <a href="?order=in-toc">In TOC</a>}</th>
                        <th>Is xref'd by</th>
                        <th>{if ($order = 'size') then <span class="hi">Size</span> else <a href="?order=size">Size</a>}</th>
                        <!--<th>Profile</th>-->
                        <th>{if ($order = 'svn-rev') then <span class="hi">SVN Rev.</span> else <a href="?order=svn-rev">SVN Rev.</a>}</th>
                    </tr>
                </thead>
                <tbody>
                    {
                    for $article in $sorted-articles
                    let $filename := util:document-name($article)
                    let $title := $article/book/bookinfo/title/string()
                    let $dated := $article/book/bookinfo/date/string()
                    let $in-toc := $filename = $landing-page-links/@url
                    let $in-toc-img := 
                        <img title="{$in-toc}" style="height:12px;" src="{
                            if ($in-toc) then 
                                'http://upload.wikimedia.org/wikipedia/commons/a/a4/SemiTransBlack_v.svg'
                            else 
                                'http://upload.wikimedia.org/wikipedia/commons/b/b2/SemiTransBlack_x.svg'
                        }"/>
                    let $xreffed-by := distinct-values($articles[not(util:document-name(.) = 'documentation.xml')]//ulink[@url = $filename]!util:document-name(.))
                    let $size := round(xmldb:size($articles-collection, $filename) div 1024) || ' kb'
                    (:
                    let $element-profile := 
                        (
                        name($article/*),
                        <br/>,
                        ' > ',
                        string-join(
                            for $e in distinct-values($article/*/*[2]!name()) 
                            return 
                                concat(count($article/*/*[2][name() = $e]), ' ', $e)
                            , ', ')
                        ,
                        <br/>,
                        ' >> ',
                        string-join(
                            for $e in distinct-values($article/*/*[2]/*!name()) 
                            return 
                                concat(count($article/*/*[2]/*[name() = $e]), ' ', $e)
                            , ', ')
                        )
                    :)
                    let $svn-id := $article/comment()/string()[starts-with(., ' $Id')]
                    let $svn-id-groups := text:groups($svn-id, '^ \$Id: .*?\.xml (\d+) (\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2}Z) (.*?) \$ $')
                    let $svn-user := $svn-id-groups[5]
                    let $svn-rev := $svn-id-groups[2]
                    let $svn-dateTime := concat($svn-id-groups[3], 'T', $svn-id-groups[4])
                    return
                        <tr>
                            <td>
                                <a href="{$filename}">{$filename}</a>
                                <br/>
                                {if (empty($title) or $title = '') then '-' else $title}
                            </td>
                            <td>{if (empty($dated) or $dated = '') then '-' else $dated}</td>
                            <td>{$in-toc-img}</td>
                            <td>{
                                if (exists($xreffed-by)) then
                                    let $count := count($xreffed-by)
                                    let $ordered-xreffed-by := for $x in $xreffed-by order by $x return $x
                                    for $x at $n in $ordered-xreffed-by
                                    return
                                        (
                                        <a href="{$x}">{$x}</a>,
                                        if ($n = $count) then () else <br/>
                                        )
                                else '-'
                            }</td>
                            <td>{$size}</td>
                            <!--<td>{$element-profile}</td>-->
                            <td>
                                <a href="http://sourceforge.net/p/exist/code/{$svn-rev}" 
                                    title="Revision {$svn-rev} by {$svn-user} on {$svn-dateTime}">{$svn-rev}</a>
                                <br/>
                                {format-dateTime($svn-dateTime, '[MNn] [D1], [Y0001]')}
                            </td>
                        </tr>
                    }
                </tbody>
            </table>
        </div>
};