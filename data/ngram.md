# N-Gram Index

## Index Configuration

To create an n-gram index, add a ngram element directly below the root index node. The n-gram index only supports index definitions by `qname`. The `path` attribute is not supported (we currently don't see many real use cases for it). Right now, the n-gram index has no additional parameters to be specified; the default settings should just be ok for most cases (we may add extra parameters in the future, e.g. for collapsing/normalizing whitespace).

                        <?xml version="1.0" encoding="UTF-8"?>
    <collection xmlns="http://exist-db.org/collection-config/1.0">
        <index>
            <lucene>
                <text qname="SPEECH">
                    <ignore qname="SPEAKER"/>
                </text>
                <text qname="TITLE"/>
            </lucene>
            <ngram qname="SPEAKER"/>
        </index>
    </collection>
