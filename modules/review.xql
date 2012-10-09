xquery version "3.0";

module namespace review = "http://exist-db.org/xquery/documentation/review";

declare %public function review:editorial-view($node as node()*, $model as map(*)) {
    let $articles-collection := '/db/doc/data'
    let $resources-collection := '/db/doc/resources'
    let $articles := collection($articles-collection)[*]
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
    let $landing-page-links := doc(concat($articles-collection, '/', 'documentation.xml'))//ulink
    return
        <div>
            <p>{count($articles)} articles in {$articles-collection}</p>
            <table>
                <thead>
                    <tr>
                        <th>Filename</th>
                        <th>Title</th>
                        <th>In TOC</th>
                        <th>Is xref'd</th>
                        <th>Rev. ID</th>
                        <th>Rev. Date</th>
                        <th>Rev. User</th>
                    </tr>
                </thead>
                <tbody>
                    {
                    for $article in $articles
                    let $filename := util:document-name($article)
                    let $title := $article/book/bookinfo/title/string()
                    let $on-landing-page := $filename = $landing-page-links/@url
                    let $xreffed-by := $articles[not(util:document-name(.) = 'documentation.xml')]//ulink[@url = $filename]!util:document-name(.)
                    let $svn-id := $article/comment()/string()[starts-with(., ' $Id')]
                    let $svn-id-groups := text:groups($svn-id, '^ \$Id: .*?\.xml (\d+) (\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2}Z) (.*?) \$ $')
                    let $svn-user := $svn-id-groups[5]
                    let $svn-rev := $svn-id-groups[2]
                    let $svn-dateTime := concat($svn-id-groups[3], 'T', $svn-id-groups[4])
                    order by $filename
                    return
                        <tr>
                            <td><a href="{$filename}">{$filename}</a></td>
                            <td>{$title}</td>
                            <td>{$on-landing-page}</td>
                            <td>{if (count($xreffed-by) > 0) then <table border="1"><tr>{for $x in $xreffed-by return <td><a href="{$x}">{$x}</a></td>}</tr></table> else ()}</td>
                            <td>{$svn-rev}</td>
                            <td>{format-dateTime($svn-dateTime, '[MNn] [D1] [Y0001], [H01]:[m01]')}</td>
                            <td>{$svn-user}</td>
                        </tr>
                    }
                </tbody>
            </table>
        </div>
};