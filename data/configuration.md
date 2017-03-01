# Application Server Configuration

## Overview

This section deals with the configuration of the eXist-db Application Server. The main configuration file for eXist-db is called `conf.xml`, which is loaded from different directories depending on the server set-up (see [Server Deployment](deployment.md) for more information).

Specifically, if you installed the standalone eXist-db distribution with the installer, the `conf.xml` file located in the root directory of the distribution (as specified by the system property `exist.home`) will be loaded by default. On the other hand, if eXist-db is installed as a web application (packaged in a `.war` file) in a servlet engine like tomcat, ` conf.xml` is read from the `WEB-INF` directory of the web application.

Why is the configuration file placed in two separate locations? The reason is that eXist-db normally has no access to files outside the context in which it is running when it is deployed as part of a web application. Therefore, when eXist is deployed in this way, the configuration is read from the `WEB-INF` directory.

## Services

The following table lists which services and modules ship with eXist; a description of each; the resources in the eXist installation where they are configured; and whether they are active by default in an out-of-the box configuration.

> **Note**
>
> This is a work in progress. It is being refined, but I want to get it into the repository to maintain history.

| Service                     | Description                                                                                                                                  |
|-----------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| debugger                    | This is an XQuery debugger.                                                                                                                  |
| fluent                      | This is an API for embedded access to eXist-db which is tightly integrated with java.                                                        |
| Desktop Application Support |                                                                                                                                              |
| LDAP                        | LDAP is an authentication mechanism by binding.                                                                                              |
| OpenID                      | OpenID is an authentication mechanism where the identity of the user is maintained by trusted external providers.                            |
| OAuth                       | OAuth is an authentication mechanism where the identity of the user is maintained by trusted external providers.                             |
| Versioning                  | Versioning extension                                                                                                                         |
| XQDoc                       | xqDoc provides a simple vendor neutral solution for documenting XQuery library and main modules that is similar to JavaDoc.                  |
| XSLT                        | XSLT extension                                                                                                                               |
| Cache                       | Cache module                                                                                                                                 |
| Compression                 | Provides functions to manipulate archives, tar/zip/gzip                                                                                      |
| Context                     | Context module                                                                                                                               |
| Counter                     | Persistent counter module                                                                                                                    |
| Datetime                    | Date/DateTime/Time utility functions module                                                                                                  |
| Example                     | This is an example Java based function module. It is a template for creating other Java based function modules.                              |
| File                        | Provides functions to manipulate files in the local file system.                                                                             |
| Http Client                 | This provides functions to call other web servers as if eXist were a web browser.                                                            |
| Image                       | Generate thumbnails of images.                                                                                                               |
| JFreechart                  | Provides functions to generate graphs using JFreechart                                                                                       |
| JNDI                        | Provides functions to query a JNDI Directory                                                                                                 |
| Mail                        | Send emails from XQuery                                                                                                                      |
| Math                        | Math function module                                                                                                                         |
| Scheduler                   | The Quartz scheduler                                                                                                                         |
| SimpleQL                    | Implements a simple query language which is translated into XQuery                                                                           |
| SQL                         | A set of functions to query a SQL database.                                                                                                  |
| Subversion                  | Provides functions to query a subversion repository                                                                                          |
| XMLDiff                     | Utility module to compare XML fragments                                                                                                      |
| XMPP                        | XMPP client; based on smack                                                                                                                  |
| XSL FO                      | XSL FO transformations (Uses Apache FOP)                                                                                                     |
| XML RPC                     | RpcServlet provides XML-RPC access to eXist                                                                                                  |
| DatabaseAdminServlet        | This servlet can be used to ensure that eXist-db is running in the background. Just set the start-parameter to true and load-on-startup to 1 |
| webDAV                      | Servlet that enables webDAV                                                                                                                  |
| XQueryServlet               | This generates HTML from an XQuery file                                                                                                      |
| XQueryURLRewrite            |                                                                                                                                              |
| Axis/SOAP                   | Axis provides eXist's web-services via SOAP                                                                                                  |
| Atom                        | Atom Publishing Protocol                                                                                                                     |
| Webstart (jnlp)             |                                                                                                                                              |
| Indexing                    |                                                                                                                                              |
| Scheduler                   | This module executes scheduled system tasks.                                                                                                 |
| Serializer                  |                                                                                                                                              |
| XSLT Transformer            | Default settings for the XSLT Transformer. Allow's for a choice of implementation.                                                           |

## eXist-db Configuration: Editing conf.xml

The configuration file `conf.xml` can be divided into four sections with the following elements:

&lt;db-connection&gt;  
Configures the storage back-end.

&lt;serializer&gt;  
Default settings for the serializer (external data representation).

&lt;indexer&gt;  
Controls the indexing process.

&lt;xupdate&gt;  
Configuration options related to XUpdate processing.

The following sections describe the attributes and child elements of the above elements.

### &lt;db-connection&gt;

This element contains basic default storage settings for eXist-db, including memory and system limits. Only one db-connection should be specified. An example configuration for the native back-end is shown below:

                            <db-connection cacheSize="48M" collectionCache="24M" database="native"
            files="webapp/WEB-INF/data" pageSize="4096" nodesBuffer="-1">
          <pool min="1" max="15" sync-period="240000" wait-before-shutdown="60000"/>
          <!--default-permissions collection="0775" resource="0775" /-->
          <recovery enabled="yes" sync-on-commit="no" group-commit="no" size="100M" 
                journal-dir="webapp/WEB-INF/data"/>
          <watchdog query-timeout="-1" output-size-limit="10000"/>
          <default-permissions collection="0775" resource="0775"/>
    </db-connection>
                        

#### &lt;db-connection&gt; Attributes

database  
This attribute selects a database system type. Since relational database back-ends are no longer supported by the current release of eXist, only "`native`" is available.

files  
This attribute specifies the directory where the native back-end will keep its database files, and so it is necessary that this directory exists. If a relative path is specified, it will be based on the root directory as defined in the `exist.home` system property. If this data directory does not have write permissions (see [User Authentication and Access Control](security.md)), eXist will internally switch to *read-only mode* such that any attempt to change the database will throw an exception.

cacheSize  
This attribute sets the maximum amount of main memory used by all page buffers (i.e. assuming all page buffers are at full capacity). The database uses this parameter to calculate the maximum size of each internal cache. You can increase this value if your system allows for greater memory use.

While indexing documents, eXist will reserve the amount of memory specified in cacheSize - even if not all caches are filled - and will not use it for temporary data.

The cacheSize should not be more than half of the size of the JVM heap size (set by the JVM -Xmx parameter). If the JVM heap is less than 512 megabyte, the cacheSize should even be smaller, e.g. 1/3.

collectionCache  
Determines the size of the collection cache, which is a separate caching space. Usually this setting does not need to be changed unless you really have more than a few thousand collections in the db. Increase it carefully, maybe up to 128M.

pageSize  
This specifies the number of bytes used for internal data and B-tree pages. This should be equal to or a multiple of the page size used by the filesystem (usually a multiple of 4096).

nodesBuffer  
Size of the temporary buffer used by eXist for caching index data while indexing a document. If set to -1, eXist will use the entire free memory to buffer index entries and will flush the cache once the memory is full.

If set to a value &gt; 0, the buffer will be fixed to the given size. The specified number corresponds to the number of nodes the buffer can hold, in thousands. Usually, a good default could be nodesBuffer="1000".

The default setting, nodesBuffer="-1", can be problematic if you frequently need to store large documents in a multi-user environment. In this case, the index operation may consume most of the memory resources, which means that concurrent threads will be slowed down or may even come to a halt.

#### pool

These settings control the internal database connection pool.

min | max  
These options specify the minimum and maximum size of the connection pool. This pool restricts the number of parallel (basic) operations that can be executed by the database. Settings should be somewhere between 1 and 20. (Please note that this has nothing to do with the HTTP and XMLRPC server settings - these servers have their own connection pools.)

sync-period  
This option defines how often the database will flush its internal buffers to disk (in milliseconds). The sync-thread will interrupt normal database operation after the specified time and write all dirty pages to disk. It also writes a checkpoint to the transaction log. In case of a database crash, only transactions which started after the last checkpoint have to be redone or rolled back. The sync-period should thus not be set too long.

wait-before-shutdown  
This option specifies the maximum amount of time (in milliseconds) that the database will allow for any running processes to complete upon database shutdown. After that, eXist will try to kill the remaining processes.

If wait-before-shutdown is set to a positive number, eXist will stop the db after the specified timeout, even if there were still running database operations. In this case, no checkpoint will be written to the transaction log. If there were any open transactions, eXist will trigger a recovery run after restart.

If wait-before-shutdown is set to -1, eXist will not shut down before all active database operations returned. This is a safe setting, but it may require a manual intervention to stop the jvm.

#### &lt;recovery&gt;

This element configures the journaling and recovery of the database. With recovery enabled, the database is able to recover from an unclean database shutdown due to, for example, power failures, OS reboots, and hanging processes. For this to work correctly, all database operations must be logged to a journal file. The location, size and other parameters for this file can be set using the recovery element.

enabled  
If this attribute is set to `yes`, automatic recovery is enabled.

size  
This attributes sets the maximum allowed size of the journal file. Once the journal reaches this limit, a checkpoint will be triggered and the journal will be cleaned. However, the database waits for running transactions to return before processing this checkpoint. In the event one of these transactions writes a lot of data to the journal file, the file will grow until the transaction has completed. Hence, the size limit is not enforced in all cases.

journal-dir  
This attribute sets the directory where journal files are to be written. If no directory is specified, the default path is to the `data` directory.

sync-on-commit  
This attribute determines whether or not to protect the journal during operating system failures. That is, it determines whether the database forces a file-sync on the journal after every commit. If this attribute is set to "`yes`", the journal is protected against operating system failures. However, this will slow performance - especially on Windows systems. If set to "`no`", eXist will rely on the operating system to flush out the journal contents to disk. In the worst case scenario, in which there is a complete system failure, some committed transactions might not have yet been written to the journal, and so will be rolled back.

group-commit  
If set to "yes", eXist will not sync the journal file immediately after every transaction commit. Instead, it will wait until the current file buffer (32kb) is really full. This can speed up eXist on some systems where a file sync is an expensive operation (mainly windows XP; not necessary on Linux).

However, `group-comit="yes"` will increase the chance that an already committed operation is rolled back after a database crash.

force-restart  
Try to restart the db even if crash recovery failed. This is dangerous because there might be corruptions inside the data files. The transaction log will be cleared, all locks removed and the db reindexed.

Set this option to "yes" if you need to make sure that the db is online, even after a fatal crash. Errors encountered during recovery are written to the log files. Scan the log files to see if any problems occurred.

consistency-check  
If set to "yes", a consistency check will be run on the database if an error was detected during crash recovery. This option requires force-restart to be set to "yes", otherwise it has no effect.

The consistency check outputs a report to the directory {files}/sanity and if inconsistencies are found in the db, it writes an emergency backup to the same directory.

#### &lt;watchdog&gt;

This is the global configuration for the *query watchdog*. The watchdog monitors all query processes, and can terminate any long-running queries if they exceed one of the predefined limits. These limits are as follows:

query-timeout  
This attribute sets the maximum amount of time (expressed in milliseconds) that the query can take before it is killed. The setting can be overwritten in an XQuery by specifiying the option `exist:timeout`:

declare option exist:timeout "time-in-ms";

Please check the documentation on [XQuery options](xquery.md#xqopts).

output-size-limit  
This attribute limits the size of XML fragments constructed using XQuery, and thus sets the maximum amount of main memory a query is allowed to use. This limit is expressed as the maximum number of nodes allowed for an in-memory DOM tree. The purpose of this option is to avoid memory shortages on the server in cases where users are allowed to run queries that produce very large output fragments. The setting can be overwritten in an XQuery by specifying the option `exist:output-size-limit`:

declare option exist:output-size-limit "size-hint";

#### &lt;default-permissions&gt;

Specifies the default permissions for all resources and collections in eXist (see [User Authentication and Access Control](security.md)). When this is not configured, the default "`mod`" (similar to the Unix "chmod" command) is set to `0775` in the `resources` and `collections` attributes. A different default value may be set for a database instance, and local overrides are also possible.

### &lt;indexer&gt;

This element sets parameters on how XML files are to be indexed by eXist. An example configuration is shown below:

                            <indexer caseSensitive="no"
        suppress-whitespace="both" index-depth="1"
        tokenizer="org.exist.storage.analysis.SimpleTokenizer"
        validation="no">
        
        <modules>
            <module id="ngram-index" class="org.exist.indexing.ngram.NGramIndex"
                file="ngram.dbx" n="3"/>
            <!--
            <module id="spatial-index" class="org.exist.indexing.spatial.GMLHSQLIndex"
                connectionTimeout="10000" flushAfter="300" />            
            -->
            <!-- The full text index is always required and should
                 not be disabled. We still have some dependencies on
                 this index in the database core. These will be removed
                 once the redesign has been completed. -->
            <module id="ft-legacy-index" class="org.exist.fulltext.FTIndex"/>
        </modules>
            
        <stopwords file="stopword"/>
        
        <!-- Default index configuration -->
        <index>
            <fulltext default="all" attributes="false">
                <exclude path="/auth"/>
            </fulltext>
        </index>

        <entity-resolver>
            <catalog file="samples/xcatalog.xml"/>
        </entity-resolver>
    </indexer>
                        

#### &lt;indexer&gt; Attributes

caseSensitive  
Specifies whether string comparisons are to be case-sensitive. This option applies to XPath equality tests (i.e. "`=`" operator), as well as functions such as `contains()`, `starts-with()` and `ends-with()`. This setting does not apply to operators or functions of the fulltext index (e.g. "`&=`", "`|=`", "`near()`") or the n-gram index, which are *never* case-sensitive

Setting `caseSensitive="yes"` violates the XQuery specs! The option should be regarded as a dirty workaround, which will be removed in the future. Please use the n-gram or full-text indexes for case-insensitive queries or - if that is impossible - specify a [collation](xquery.md#collations).

suppress-whitespace  
Specifies how the &lt;indexer&gt; is to treat whitespace at the start or end of a character sequence. This option *ONLY* applies to newly stored files, and therefore changing it has no effect on previously stored documents. Possible values for this attribute are:

1.  `leading` - Suppresses leading whitespace.

2.  `trailing` - Suppresses trailing whitespace.

3.  `both` - Suppresses leading and trailing whitespace.

4.  `none` - Preserves all whitespace.

Note that suppressing whitespace at the start or end of character sequences does effectively change the document!

preserve-whitespace-mixed-content  
controls how ignorable whitespace is handled. If set to `no`, ignorable whitespace, e.g. between the end tag of an element and the start tag of another, will not be stored into the persistent DOM. This leads to a smaller DOM and usually increases the readability of the XML. Ignorable whitespace is not considered as a part of the logical document model, so removing it doesn't change the document.

tokenizer  
This attribute invokes the Java class used to tokenize a string into a sequence of single words or tokens, which are stored to the fulltext index. Currently only the `SimpleTokenizer` is available.

index-depth  
This attribute specifies the depth of the DOM index, or the tree level up to which elements will be added to the index. For example, a value of "`2`" results in the document root node and all its child elements being indexed; a value of "`1`" only indexes the root node.

The DOM index maps unique node identifiers to the nodes' storage locations in the DOM file. Generating this index is time- and memory-consuming. It is furthermore primarily needed to access nodes by their unique node identifier - for example, when serializing XML data for query results or XUpdate - which are operations not normally considered time-critical. Moreover, most XPath expressions can do without this index since they use short-cuts to access the node directly.

Beginning with version 0.9, only top-level elements are added to the DOM index, whereas attributes and text nodes are always excluded. This results in much smaller index sizes and, consequently, a smaller `dom.dbx` file size. Usually, setting the `index-depth` to a value of "`2`" offers a reasonable compromise of index size and performance. However, if your documents are *deeply-structured*, you might consider increasing this setting to a level of 3, 4 or 5. For example, if the longest path from the document root to an element node has greater than ten node levels, an `index-depth` setting of `4` or `5` would probably help to increase overall query performance for some types of queries.

validation  
This attribute defines the default setting for the validation of documents by the XML parser. If it is set to "`no`", documents will never be validated against an existing DTD or schema. A value of "`auto`" will leave document validation to the SAX parser (i.e. the *Xerces* parser).

#### modules

This section configures optional indexing modules. Beginning with version 1.2, eXist features a modularized indexing architecture, which allows new indexes to be plugged into the indexing pipeline. The modules section lists and configures the indexes that will be available to the database:

                                <modules>
        <module id="ngram-index" class="org.exist.indexing.ngram.NGramIndex"
            file="ngram.dbx" n="3"/>
        <!--
        <module id="spatial-index" class="org.exist.indexing.spatial.GMLHSQLIndex"
            connectionTimeout="10000" flushAfter="300" />            
        -->
        <!-- The full text index is always required and should
             not be disabled. We still have some dependencies on
             this index in the database core. These will be removed
             once the redesign has been completed. -->
        <module id="ft-legacy-index" class="org.exist.fulltext.FTIndex"/>
    </modules>
                            

The only common attributes for each module element are `class` and `id`. The other attributes as well as any nested elements are specific to the index implementation. Detailed information is available in the document on [Configuring Database Indexes](indexing.md#moduleconf).

#### stopwords

The `file` for this element points to a file containing a list of *stopwords*. Note that stopwords are *NOT* added to the fullext index.

#### index

This configuration element specifies the default index settings. These settings are applied if neither the collection nor any of its ancestors provide a collection configuration. Configuring indexes via the default settings is not recommended. If you need a global collection configuration, store one for the root collection `/db`. For more information, read the [Configuring Indexes](indexing.md) documentation.

### scheduler

This section is used to configure asynchronous jobs with eXist's internal scheduler. Three types of jobs are supported:

startup jobs  
Startup jobs are executed once during database startup, but before the database becomes available. These jobs are synchronous. The database is blocked to outside requests and no other operations will run at the same time.

system jobs  
System jobs require the database to be in a consistent state. The scheduler will run them in an exclusive environment. Once the job is triggered, the database will block all new requests and wait for running operations to complete. It then executes the job. All other database operations will be stopped until the job returns or throws an exception. Any exception will be caught and a warning written to the log.

user jobs  
User jobs may be scheduled at any time and may be mutually exclusive or non-exclusive

Below is an example which configures a [BackupSystemTask](backup.md#backuptask):

                            <scheduler>
        <job type="system" class="org.exist.storage.BackupSystemTask" cron-trigger="0 0 */6 * * ?">
            <parameter name="dir" value="backup"/>
            <parameter name="suffix" value=".zip"/>
            <parameter name="prefix" value="backup-"/>
            <parameter name="collection" value="/db"/>
            <parameter name="user" value="admin"/>
            <parameter name="password" value=""/>
            <parameter name="zip-files-max" value="28"/>
        </job>
    </scheduler>
                        

Each job is configured in a job element which accepts a number of standard attributes:

#### job attributes

type  
The type of the job to schedule. Must be either "startup", "system" or "user".

class  
If the job is written in Java then this should be the name of the class that extends either

-   org.exist.scheduler.StartupJob

-   org.exist.storage.SystemTask

-   org.exist.scheduler.UserJavaJob

xquery  
If the job is written in XQuery (not suitable for system jobs) then this should be a path to an XQuery stored in the database. e.g. `/db/myCollection/myJob.xql` XQuery job's will be launched under the guest account initially, although the running XQuery may switch permissions through calls to xmldb:login().

cron-trigger  
To define a firing pattern for the Job using Cron style syntax use this attribute otherwise for a periodic job use the period attribute. Not applicable to startup jobs.

unschedule-on-exception  
Boolean: yes/true, no/false. Default: true. If true and an exception is encountered then the job is unscheduled for further execution until a restart; otherwise, the exception is ignored.

period  
Can be used to define an explicit period for firing the job instead of a Cron style syntax. The period should be in milliseconds. Not applicable to startup jobs.

delay  
Can be used with a period to delay the start of a job. If unspecified jobs will start as soon as the database and scheduler are initialised.

repeat  
Can be used with a period to define for how many periods a job should be executed. If unspecified jobs will repeat for every period indefinitely.

Every job can take additional parameters, which are passed as name/value pairs (see example above).

### &lt;serializer&gt;

The serializer is responsible for serializing XML documents or document fragments back into XML. This configuration element defines default settings for various parameters, which can also be specified programmatically. All settings can be overwritten by XQuery [serialization options](xquery.md#serialization).

#### &lt;serializer&gt; Attributes

enable-xinclude  
This attribute determines whether xinclude tags are to be expanded during serialization. Setting the value to "`false`" will leave xinclude tags unexpanded.

enable-xsl  
This attribute (when set to "`true`") tells the serializer to pass its output to an XSL stylesheet when it encounters an XSL processing-instruction at the start of the document.

add-exist-id  
This attribute tells the serializer to add debug information to each element expressed as additional attributes. This information includes the internal identifier of the node and source document. These are the accepted values:

1.  `all` - Adds debug information to every node in the output.

2.  `element` - Adds debug information to top-level elements only.

3.  `none` (default) - Disables debugging feature.

indent  
The serializer defaults to pretty-print the resulting XML source code. Set this option to "`no`" to disable pretty-printing.

match-tagging-elements  
The database can highlight matches in the text content of a node by tagging the matching text string with exist:match. Clearly, this only works for XPath expressions using the fulltext index. Set the parameter to "`yes`" to *disable* this feature.

### transformer

This section determines which XSLT processor will be used by eXist. By default, eXist relies on Xalan, which is an XSLT 1.0 engine. Please refer to [this howto](http://atomic.exist-db.org/wiki/HowTo/XSLT2/) to switch to an XSLT 2.0 processor like saxon.

### validation

Defines the default validation settings that will be active when parsing XML and links to catalog files. Catalog files are used to locate DTDs, schemas and resolve external entities in general.

Please refer to the corresponding documentation on [XML Validation](validation.md).

### &lt;xupdate&gt;

Inserting new nodes into a document can lead to fragmentation in the DOM storage file. eXist will thus trigger a defragmentation run if the fragmentation exceeds a certain limit. The frequency of such defragmentation runs can be configured in the xupdate section. The main parameter is called `allowed-fragmentation`:

                            <xupdate allowed-fragmentation="20" enable-consistency-checks="no" />
                        

#### &lt;xupdate&gt; Attributes

allowed-fragmentation  
This attribute defines the maximum number of page splits allowed within a document before a defragmentation run is triggered.

enable-consistency-checks  
This attribute is for or debugging purposes only. If the parameter is set to "`yes`", a *consistency check* will be run on modified documents after every XUpdate request. This checks whether the persistent DOM is complete, and all pointers in the structural index point to valid storage addresses that contain valid nodes.

### xquery

                            <xquery enable-java-binding="no" enable-query-rewriting="no" enforce-index-use="always" disable-deprecated-functions="no" raise-error-on-failed-retrieval="no" backwardCompatible="no">
        <builtin-modules>
            <!-- Default Modules -->
            <module class="org.exist.xquery.functions.util.UtilModule"
                uri="http://exist-db.org/xquery/util" />
            <!-- ... more modules ... -->
        </builtin-modules>
    </xquery>
                        

The xquery section is used to enable/disable certain core features of the XQuery engine. It also lists the XQuery modules that will be known to the query engine by default.

#### xquery attributes

enable-java-binding=yes|no  
enables or disables the [java binding](xquery.md#javamods). Giving users full access to all Java classes should be considered a security risk and the feature is thus disabled by default. If you enable it, you should think about configuring [XACML](xacml.md) to restrict Java access from XQuery.

disable-deprecated-functions=yes|no  
enables or disables XQuery functions marked as deprecated.

enforce-index-use=strict|always  
controls if available range indexes should be used if only some collections in the context set define a matching index. Available settings are: "always" to always use an index, even if it does not apply to the entire set of collections being queried; "strict" to only use indexes if they are defined for the entire collection set.

For example, if you have two collections: /db/one and /db/two, and you define a range index on a certain element node in /db/one, but not in /db/two, the query engine would not use the index with setting "strict" if you query both collections. At compile time, eXist doesn't know if node exists in both collections and will not use the index if it determines that an index definition does only apply to a part of the collection set being queried. To use the index, you would need to start your XPath expression with a call to collection(), selecting the correct collection with the index defined.

On the other hand, if enforce-index-use is set to "always", the query engine only checks if one collection in the collection set has a matching index defined on it. This may lead to an incomplete query result if one forgets certain collections.

In other words, when enforce-index-use is set to "always", it is the query writers responsibility to make sure indexes are defined properly. But experience has shown it is easier for users to understand that a certain result is incomplete because an index is missing, whereas they have problems to see that a performance issue is caused by inconsistent indexing.

raise-error-on-failed-retrieval=yes|no  
set to `"yes"` if a call to `doc()`, `xmldb:document()`, `collection()` or `xmldb:xcollection()` should raise an error (FODC0002) when an XML resource can not be retrieved.

set to `"no"` if a call to `doc()`, `xmldb:document()`, `collection()` or `xmldb:xcollection()` should return an empty sequence when an XML resource can not be retrieved.

enable-query-rewriting=yes|no  
the query engine can often achieve considerable performance improvements by rewriting an XQuery expression into a more efficient form (see the documentation about [indexing](indexing.md#pathvsqname)). However, these features are relatively new. If you have doubts about the correctness of a query result, you may temporarily set `enable-query-rewriting` to `"no"` and see if the result changes in any way. If it does, you have hit a bug which should be reported.

backwardCompatible=yes|no  
enables or disables XPath 1.0 backwards compatibility. The setting mainly effects automatic type conversions, which were less strict in XPath 1.0 than in XQuery/XPath 2.0.

#### builtin-modules

This section lists the XQuery modules which will be known to the query engine. The modules in this list can be imported into a query without specifying a location. For example, the following entry:

&lt;module class="org.exist.xquery.modules.file.FileModule" uri="http://exist-db.org/xquery/file" /&gt;
establishes a static mapping between the module URI for the file module and the Java class which implements it. When using that module, it is sufficient to provide the correct URI in the import. Specifying a location is not needed:

import module namespace file="http://exist-db.org/xquery/file";
Instead of providing a Java class, one can also specify a src URI which must point to the XQuery source code of the module, e.g.:

&lt;module src="resource:org/exist/xquery/lib/json.xq" uri="http://www.json.org"/&gt;
For the src attribute, eXist understands the [same types of URIs](http://localhost:8080/exist/xquery.xml#N10195) as in an ordinary XQuery import statement.
