# Developer's Guide to Modularized Indexes

## Note

This document has been reviewed for eXist-db 1.2.

## The new modularized indexes

### Brief overview

Since around SVN revision 6000, spring 2007, i.e. *after* the 1.1 release, eXist-db provides a new mechanism to index XML data. This mechanism is modular and should ease index development as well as the development of related (possibly not so) custom functions. As a proof of concept, eXist currently ships with two index types :

-   NGram index
    An NGram index will store the N-grams contained in the data's characters, i.e. if the index is configured to index 3-grams, `<data>abcde</data>` will generate these index entries :

    -   abc

    -   bcd

    -   cde

    -   de␣

    -   e␣␣

-   Spatial index
    A spatial index will store some of the geometric characteristics of [Geography Markup Language](http://www.opengeospatial.org/standards/gml) geometries (currently only tested with GML version 2.1.2).

                                        
                  <gml:Polygon xmlns:gml = 'http://www.opengis.net/gml' srsName='osgb:BNG'>
                    <gml:outerBoundaryIs>
                      <gml:LinearRing>
                        <gml:coordinates>
                      278515.400,187060.450 278515.150,187057.950 278516.350,187057.150
                      278546.700,187054.000 278580.550,187050.900 278609.500,187048.100
                      278609.750,187051.250 278574.750,187054.650 278544.950,187057.450
                      278515.400,187060.450 
                        </gml:coordinates>
                      </gml:LinearRing>
                    </gml:outerBoundaryIs>
                  </gml:Polygon>
                  
                                    

    will generate index entries among which most important are :

    -   the [spatial referencing system](http://en.wikipedia.org/wiki/Spatial_referencing_systems) (osgb:BNG for this polygon)

    -   the polygon itself, stored in a binary form ([Well-Known Binary](http://en.wikipedia.org/wiki/Well-known_text))

    -   the coordinates of its [bounding box](http://en.wikipedia.org/wiki/Minimum_bounding_rectangle)

    The spatial index will we discussed in details further below.

So, the new architecture introduces a new package, `org.exist.indexing` which contains a class that we will immediately study, `IndexManager`.

### `org.exist.indexing.IndexManager`

As its name suggests, this is the class which is responsible for index management. It is created by `org.exist.storage.BrokerPool` which allocates `org.exist.storage.DBBroker`s to each process accessing each DB instance. Each time a DB instance is created (most installations generally have only one, most often called exist), the initialize() method contructs an `IndexManager` that will be available through the getIndexManager() method of `org.exist.storage.BrokerPool`.

public IndexManager(BrokerPool pool, Configuration config)
This constructor keeps track of the `BrokerPool` that has created the instance and receives the database's configuration object, usually defined in an XML file called `conf.xml`. This new entry is expected in the configuration file :

                            
        <modules>
        <module id="ngram-index" class="org.exist.indexing.ngram.NGramIndex" file="ngram.dbx" n="3"/>            
        <module id="spatial-index" class="org.exist.indexing.spatial.GMLHSQLIndex" connectionTimeout="100000" flushAfter="300" />                     
        </modules>
        
                        

... which defines 2 indexes, backed-up by their specific classes (class attribute ; these classes implement the `org.exist.indexing.Index` interface as will be seen below), eventually assigns them a human-readable (writable even) identifier and passes them custom parameters which are implementation-dependant. Then, it configures (by calling their configure() method), opens (by calling their open() method) and keeps track of each of them.

`org.exist.indexing.IndexManager` also provides these public methods :

public BrokerPool getBrokerPool()
... which returns the `org.exist.storage.BrokerPool` for which this `IndexManager` was created.

public synchronized Index getIndexById(String indexId)
A method that returns an `Index` given its class identifier (see below). Allows custom functions to access `Index`es whatever their human-defined name is. This is probably the only method in this class that will be really needed by a developer.

public synchronized Index getIndexByName(String indexName)
The counterpart of the previous method. Pass the human-readable name of the `Index` as defined in the configuration.

public void shutdown()
This method is called when eXist shuts down. close() will be called for every registered `Index`. That allows them to free the resources they have allocated.

public void removeIndexes()
This method is called when repair() is called from `org.exist.storage.NativeBroker`.

> **Note**
>
> repair() reconstructs every index (including the structural one) from what is contained in the persistent DOM (usually `dom.dbx`).

remove() will be called for every registered `Index`. That allows each index to destroy its persistent storage if it wants to do so (but it is probably suitable given that repair() is called when the DB and/or its indexes are corrupted).

public void reopenIndexes()
This method is called when repair() is called from `org.exist.storage.NativeBroker`.

> **Note**
>
> repair() reconstructs every index (including the structural one) from what is contained in the persistent DOM (usually `dom.dbx`).

open() will be called for every registered `Index`. That allows each index to (re)allocate the resources it needs for its persistent storage.

### `org.exist.indexing.IndexController`

Another important class is `org.exist.indexing.IndexController` which, as its name suggests, controls the way data to be indexed are dispatched to the registered indexes, using `org.exist.indexing.IndexWorker`s that will be described below. Each `org.exist.storage.DBBroker` constructs such an `IndexController` when it is itself constructed, using this constructor :

public IndexController(DBBroker broker)
... that registers the `broker`'s `IndexWorker`s, one for each registered `Index`. These `IndexWorker`s, that will be described below, are returned by the getWorker() method in `org.exist.indexing.Index`, which is usually a good place to create such an `IndexWorker`, at least the first time it is called.

This `IndexController` will be available through the getIndexController() method of `org.exist.storage.DBBroker`.

Here are the other public methods :

public Map configure(NodeList configNodes, Map namespaces)
This method receives the database's configuration object, usually defined in an XML file called `conf.xml`. Both configuration nodes and namespaces (remember that some configuration settings including e.g. pathes need namespaces to be defined) will be passed to the configure() method of each `IndexWorker`. The returned object is a `java.util.Map` that will be available from collection.getIndexConfiguration(broker).getCustomIndexSpec(INDEX\_CLASS\_IDENTIFIER).

public IndexWorker getWorkerByIndexId(String indexId)
A method that returns an `IndexWorker` given the class identifier of its associated `Index` identifier. Very useful to the developer since it allows custom functions to access `IndexWorker`s whatever the human-defined name of their `Index` is. This is probably the only method in this class that will be really needed by a developer.

public IndexWorker getWorkerByIndexName(String indexName)
The counterpart of the previous method. For the human-readable name of the `Index` as defined in the configuration.

public void setDocument(DocumentImpl doc)
This method sets the `org.exist.dom.DocumentImpl` on which the `IndexWorker`s shall work. Calls setDocument(doc) on each registered `IndexWorker`.

public void setMode(int mode)
This method sets the operating mode in which the `IndexWorker`s shall work. See below for further details on operating modes. Calls setMode(mode) on each registered `IndexWorker`.

public void setDocument(DocumentImpl doc, int mode)
A convenience method that sets both the `org.exist.dom.DocumentImpl` and the operating mode. Calls setDocument(doc, mode) on each registered `IndexWorker`.

public DocumentImpl getDocument()
Returns the `org.exist.dom.DocumentImpl` on which the `IndexWorker`s will have to work.

public int getMode()
Returns the operating mode in which the `IndexWorker`s will have to work.

public void flush()
Called in various places when pending operations, obviously data insertion, update or removal, have to be completed. Calls flush() on each registered `IndexWorker`.

public void removeCollection(Collection collection, DBBroker broker)
Called when a collection is to be removed. That allows to delete index entries for this collection in a single operation. Calls removeCollection() on each registered `IndexWorker`.

public void reindex(Txn transaction, StoredNode reindexRoot, int mode)
Called when a document is to be reindexed. Only the `reindexRoot` node and its descendants will have their index entries updated or removed depending of the `mode` parameter.

public StoredNode getReindexRoot(StoredNode node, NodePath path)
Determines the node which should be reindexed together with its descendants. Calls getReindexRoot() on each registered `IndexWorker`. The top-most node will be the actual node from which the `DBBroker` will start reindexing.

public StoredNode getReindexRoot(StoredNode node, NodePath path, boolean includeSelf)
Same as above, with more parameters.

public StreamListener getStreamListener()
Returns the first `org.exist.indexing.StreamListener` in the `StreamListener`s pipeline. There is at most one `StreamListener` per `IndexWorker` that will intercept the (re)indexed nodes stream. `IndexWorker`s that are not interested in the data (depending of e.g. the document and/or the operating mode) may return `null` through their getListener() method and thus not participate in the (re)indexing process. In other terms, they will not listen to the indexed nodes.

public void indexNode(Txn transaction, StoredNode node, NodePath path, StreamListener listener)
Index any kind of indexable node (currently elements, attributes and text nodes ; comments and especially processing instructions might be considered in the future).

public void startElement(Txn transaction, ElementImpl node, NodePath path, StreamListener listener)
More specific than indexNode(). For an element. Will call startElement() on `listener` if it is not `null`. Hence the analogy with [STAX events](http://www.xml.com/pub/a/2003/09/17/stax.html) is obvious.

public void attribute(Txn transaction, AttrImpl node, NodePath path, StreamListener listener)
More specific than indexNode(). For an attribute. Will call attribute() on `listener` if it is not `null`.

public void characters(Txn transaction, TextImpl node, NodePath path, StreamListener listener)
More specific than indexNode(). For a text node. Will call characters() on `listener` if it is not `null`.

public void endElement(Txn transaction, ElementImpl node, NodePath path, StreamListener listener)
Signals end of indexing for an element node. Will call endElement() on `listener` if it is not `null`

public MatchListener getMatchListener(NodeProxy proxy)
Returns a `org.exist.indexing.MatchListener` for the given node.

The two classes aim to be essentially used by eXist itself. As a programmer you will probably need to use just one or two of the above methods.

### `org.exist.indexing.Index` and `org.exist.indexing.AbstractIndex`

Now let's get into the interfaces and classes that will need to be extended by the index programmer. The first of them is the interface `org.exist.indexing.Index` which will maintain the index itself.

As described above, a new instance of the interface will be created by the constructor of `org.exist.indexing.IndexManager` which calls the interface's newInstance() method. No need for a constructor then.

Here are the methods that have to be implemented in an implementation:

String getIndexId()
Returns the class identifier of the index.

String getIndexName()
Returns the human-defined name of the index, if one was defined in the configuration file.

BrokerPool getBrokerPool()
Returns the `org.exist.storage.BrokerPool` that has created the index.

void configure(BrokerPool pool, String dataDir, Element config)
Notifies the `Index` a data directory (normally `${EXIST_HOME}/webapp/WEB-INF/data`) and the configuration element in which it is declared.

void open()
Method that is executed when the `Index` is opened, whatever it means. Consider this method as an initialization and allocate the necessary resources here.

void close()
Method that is executed when the `Index` is closed, whatever it means. Consider this method as a finalization and free the allocated resources here.

void sync()
Unused.

void remove()
Method that is executed when eXist requires the index content to be entitrely deleted, e.g. before repairing a corrupted database.

IndexWorker getWorker(DBBroker broker)
Returns the `IndexWorker` that operates on this `Index` on behalf of `broker`. One may want to create a new `IndexWorker` here or pick one form a pool.

boolean checkIndex(DBBroker broker)
To be called by applications that want to implement a consistency check on the `Index`.

There is also an abstract class that implements `org.exist.indexing.Index`, `org.exist.indexing.AbstractIndex` that can be used a a basis for most `Index` implementations. Most of its methods are abstract and still have to be implemented in the concrete classes. These are the few concrete methods:

public String getDataDir()
Returns the directory in which this `Index` operates. Usually defined by configure() which itself receives eXist's configuration settings. NB! There might be some `Index`es for which the concept of data directory isn't accurate.

public void configure(BrokerPool pool, String dataDir, Element config)
Its minimal implementation retains the `org.exist.storage.BrokerPool`, the data directory and the human-defined name, if defined in the configuration file (in an attribute called id). Sub-classes may call super.configure() to retain this default behaviour.

This member is protected :

protected static String ID = "Give me an ID !"
This is where the class identifier of the `Index` is defined. Override this member with, say, MyClass.class.getName() to provide a reasonably unique identifier within your system.

### `org.exist.indexing.IndexWorker`

The next important interface that will need to be implemented is `org.exist.indexing.IndexWorker` which is responsible for managing the data in the index. Remember that each `org.exist.storage.DBBroker` will have such an `IndexWorker` at its disposal and that their `IndexController` will know what method of `IndexWorker` to call and when to call it.

Here are the methods that have to be implemented in the concrete implementations :

public String getIndexId()
Returns the class identifier of the index.

public String getIndexName()
Returns the human-defined name of the index, if one was defined in the configuration file.

Object configure(IndexController controller, NodeList configNodes, Map namespaces)
This method receives the database's configuration object, usually defined in an XML file called `conf.xml`. Both configuration nodes and namespaces (remember that some configuration settings including e.g. pathes need namespaces to be defined) will be passed to the configure() method of the `IndexWorker`'s `IndexController`. The `IndexWorker` can use this method to retain custom configuration options in a custom object that will be available in the `java.util.Map` returned by collection.getIndexConfiguration(broker).getCustomIndexSpec(INDEX\_CLASS\_IDENTIFIER). The return type is free but will probably generally be an implementation of `java.util.Collection` in order to retain several parameters.

void setDocument(DocumentImpl doc)
This method sets the `org.exist.dom.DocumentImpl` on which this `IndexWorker` will have to work.

void setMode(int mode)
This method sets the operating mode in which this `IndexWorker` will have to work. See below for further details on operating modes.

void setDocument(DocumentImpl doc, int mode)
A convenience method that sets both the `org.exist.dom.DocumentImpl` and the operating mode.

DocumentImpl getDocument()
Returns the `org.exist.dom.DocumentImpl` on which this `IndexWorker` will have to work.

int getMode()
Returns the operating mode in which this `IndexWorker` will have to work.

void flush()
Called periodically by the `IndexController` or by any other process. That is where data insertion, update or removal should actually take place.

void removeCollection(Collection collection, DBBroker broker)
Called when a collection is to be removed. That allows to delete index entries for this collection in a single operation without a need for a `StreamListener` (see below) or a call to setMode() nor setDocument().

StoredNode getReindexRoot(StoredNode node, NodePath path, boolean includeSelf)
Determines the node which should be reindexed together with its descendants. This will give a hint to the `IndexController` to determine from which node reindexing should start.

StreamListener getListener()
Returns a `StreamListener` that will intercept the (re)indexed nodes stream. `IndexWorker`s that are not interested in the data (depending of e.g. the document and/or the operating mode) may return `null` here.

MatchListener getMatchListener(NodeProxy proxy)
Returns a `org.exist.indexing.MatchListener` for the given node.

boolean checkIndex(DBBroker broker)
To be called by applications that want to implement a consistency check on the index.

Occurrences\[\] scanIndex(DocumentSet docs)
Returns an array of `org.exist.dom.DocumentImpl.Occurrences` that is an *ordered* list of the index entries, in a textual form, associated with the number of occurences for the entries and a list of the documents containing them. NB! For some indexes, the concept of ordered or textual occurrences might not be meaningful.

### `org.exist.indexing.StreamListener` and `org.exist.indexing.AbstractStreamListener`

The interface `org.exist.indexing.StreamListener` has these public members :

public final static int UNKNOWN = -1;
public final static int STORE = 0;
public final static int REMOVE\_ALL\_NODES = 1;
public final static int REMOVE\_SOME\_NODES = 2;
Obviously, they are used by the setMode() method in `org.exist.indexing.IndexController` which is istself called by the different `org.exist.storage.DBBroker`s when they have to (re)index a node and its descendants. As their name suggests, there is a mode for storing nodes and two modes for removing them from the indexes. The difference between `StreamListener.REMOVE_ALL_NODES` and `StreamListener.REMOVE_SOME_NODES` is that the former removes all the nodes from a document whereas the latter removes only some nodes from a document, usually the descendants of the node returned by getReindexRoot(). We thus have the opportunity to trigger a process that will directly remove all the nodes from a given document without having to listen to each of them. Such a technique is described below.

Here are the methods that must be implement by an implemetation:

IndexWorker getWorker()
Returns the `IndexWorker` that owns this `StreamListener`.

void setNextInChain(StreamListener listener);
Should not be used. Used to specify which is the next `StreamListener` in the `IndexController`'s `StreamListener`s pipeline.

StreamListener getNextInChain();
Returns the next `StreamListener` in the `IndexController`'s `StreamListener`s pipeline. Very important because it is the responsability of the `StreamListener` to forward the event stream to the next `StreamListener` in the pipeline.

void startElement(Txn transaction, ElementImpl element, NodePath path)
Signals the start of an element to the listener.

void attribute(Txn transaction, AttrImpl attrib, NodePath path)
Passes an attribute to the listener.

void characters(Txn transaction, TextImpl text, NodePath path)
Passes some character data to the listener.

void endElement(Txn transaction, ElementImpl element, NodePath path)
Signals the end of an element to the listener. Allow to free any temporary resource created since the matching startElement() has been called.

Beside the `StreamListener` interface, each custom listener should extend `org.exist.indexing.AbstractStreamListener`.

This abstract class provides concrete implementations for setNextInChain() and getNextInChain() that should normally never be overridden.

It also provides dummy startElement(), attribute(), characters(), endElement() methods that do nothing but forwarding the node to the next `StreamListener` in the `IndexController`'s `StreamListener`s pipeline.

public abstract IndexWorker getWorker()
remains abstract though, since we still can not know what `IndexWorker` will own the `Listener` until we haven't a concrete implementation.

## A use case : developing an indexing architecture for GML geometries

### Introduction

To demonstrate how modular eXist `Index`es are, we have decided to show how a spatial `Index` could be implemented. What makes its design interesting is that this kind of `Index` doesn't store character data from the document, nor does it use a `org.exist.storage.index.BFile` to store the index entries. Instead, we will store WKB index entries in a JDBC database, namely a [HSQLDB](http://hsqldb.org/) to keep the distribution as light as possible and reduce the number of external dependencies, but it wouldn't be too difficult to use another one like [PostGIS](http://postgis.refractions.net/) given that the implementation has itself been designed in a quite modular way.

In eXist's SVN repository, the modularized `Index`es code is in `extensions/indexes` and the file system's architecture is designed to follow eXist's core architecture, i.e. `org.exist.indexing.*` for the `Index`es and `org.exist.xquery.*` for their associated `Module`s. There is also a dedicated location for required external libraries and for the test cases. The build system should normally be able to download the required libraries from the WWW (do no forget to adjust your proxy server's properties in `build.properties` if required) build the all the files automatically, in particular the `extension-modules` Ant target, and even launch the tests provided that the DB's configuration file declares the `Index`es (see above) and their associated `Module`s (see below).

The described spatial `Index` heavily relies on the excellent open source librairies provided by the [Geotools](http://geotools.codehaus.org/) project. We have experienced a few problems that will be mentioned further, but since feedback has been provided, the situation will unquestionably improve in the future, making current workarounds redundant.

The `Index` has been tested with only one file which is available from the [Ordnance Survey of Great-Britain](http://www.ordnancesurvey.co.uk/oswebsite/), a topography layer of Port-Talbot, which is available as [sample data](http://www.ordnancesurvey.co.uk/oswebsite/products/try-now/sample-data.html). Shall we mention that obtaining *valid* and sizeable GML data is still extremely difficult?

### Writing the concrete implementation of `org.exist.indexing.AbstractIndex`

Well, in fact we will start by writing an abstract implementation first. As said above, we have planned a modular JDBC spatial `Index`, which will be abstract, and that will be extended by a concrete HSQLDB `Index`.

Let's start with this :

        package org.exist.indexing.spatial;         
        
        public abstract class AbstractGMLJDBCIndex extends AbstractIndex {

        public final static String ID = AbstractGMLJDBCIndex.class.getName();   
        private final static Logger LOG = Logger.getLogger(AbstractGMLJDBCIndex.class);
        protected HashMap workers = new HashMap();
        protected Connection conn = null;
        
        }
        

... where we define an abstract class that extends `org.exist.indexing.AbstractIndex` and thus implements `org.exist.indexing.Index`. We also define a few members like `ID` that will be returned by the unoverriden getIndexId() from `org.exist.indexing.AbstractIndex`, a `Logger`, a `java.util.HashMap` that will be a "pool" of `IndexWorker`s (one for each `org.exist.storage.DBBroker`) and a `java.sql.Connection` that will handle the database operations at the index level.

Let' now introduce this general purpose interface :

        public interface SpatialOperator { 
          public static int UNKNOWN = -1;
          public static int EQUALS = 1;
          public static int DISJOINT = 2;
          public static int INTERSECTS = 3;
          public static int TOUCHES = 4;
          public static int CROSSES = 5;
          public static int WITHIN = 6;
          public static int CONTAINS = 7;
          public static int OVERLAPS = 8;
        }           
        

... that defines the spatial operators that will be used by spatial queries (what would be worth a spatial index that doesn't support spatial queries?). For more information about the semantics, see the [JTS documentation](http://www.vividsolutions.com/jts/bin/JTS%20Technical%20Specs.pdf) (chapter 11). We will use this wonderful library everytime a spatial computation is required. So does the Geotools project by the way.

Here are a few concrete methods that should be usable by any JDBC-enabled database:

              
        public AbstractGMLJDBCIndex() {     
        }  
        
        public void configure(BrokerPool pool, String dataDir, Element config) throws DatabaseConfigurationException {        
          super.configure(pool, dataDir, config);
          try {
            checkDatabase();
          } catch (ClassNotFoundException e) {
          throw new DatabaseConfigurationException(e.getMessage()); 
          } catch (SQLException e) {
          throw new DatabaseConfigurationException(e.getMessage()); 
          }
        }

        public void open() throws DatabaseConfigurationException {     
        }

        public void close() throws DBException {
          Iterator i = workers.values().iterator();
          while (i.hasNext()) {
            AbstractGMLJDBCIndexWorker worker = (AbstractGMLJDBCIndexWorker)i.next();       
            worker.flush();     
            worker.setDocument(null, StreamListener.UNKNOWN);
          }
          shutdownDatabase();
        }

        public void sync() throws DBException {
        }
        
        public void remove() throws DBException {
          Iterator i = workers.values().iterator();
          while (i.hasNext()) {
            AbstractGMLJDBCIndexWorker worker = (AbstractGMLJDBCIndexWorker)i.next();       
            worker.flush();     
            worker.setDocument(null, StreamListener.UNKNOWN);
          }
          removeIndexContent();
          shutdownDatabase();
          deleteDatabase(); 
        }           

        public boolean checkIndex(DBBroker broker) {
          return getWorker(broker).checkIndex(broker);
        } 
        

First, an empty constructor, not even necessary since the `Index` is created through the newInstance() method of its interface (see above).

Then, a configuration method that calls its ancestor, whose behaviour fullfills our needs. This method calls a checkDatabase() method whose semantics will be dependant of the underlying DB. The basic idea is to prevent eXist to continue its initialization if there is a problem with the DB.

Then we will do nothing during open(). No need to open a database, which is costly, if we dont need it.

The close() will flush any pending operation currently queued by the `IndexWorker`s and resets their state in order to prevent them to start any further operation, which should never be possible if eXist is their only user. Then it will call a shutdownDatabase() method whose semantics will be dependant of the underlying DB. They can be fairly simple for DBs that shut down automatically when the virtual machine shuts down.

The sync() is never called by eXist. It's here to make the interface happy.

The remove() method is similar to close(). It then calls two database-dependant methods that are pretty redundant. deleteDatabase() will probably not be able to do what its name suggests if eXist doesn't own the admin rights. Conversely, removeIndexContent() wiould probably have nothing to do if eXist owns the admin rights since physically destroying the DB would probably be more efficient than deleteing table contents.

checkIndex() will delegate the task to the `broker`'s `IndexWorker`.

The remaining methods are DB-dependant and thus abstract :

                 
        public abstract IndexWorker getWorker(DBBroker broker);
        protected abstract void checkDatabase() throws ClassNotFoundException, SQLException;
        protected abstract void shutdownDatabase() throws DBException;
        protected abstract void deleteDatabase() throws DBException;
        protected abstract void removeIndexContent() throws DBException;
        protected abstract Connection acquireConnection(DBBroker broker) throws SQLException;   
        protected abstract void releaseConnection(DBBroker broker) throws SQLException;         
        

Let's see now how a HSQL-dependant implementation would be going by describing the concrete class :

                 
        package org.exist.indexing.spatial;

        public class GMLHSQLIndex extends AbstractGMLJDBCIndex {
        
          private final static Logger LOG = Logger.getLogger(GMLHSQLIndex.class);
          public static String db_file_name_prefix = "spatial_index";
          public static String TABLE_NAME = "SPATIAL_INDEX_V1";
          private DBBroker connectionOwner = null;
          private long connectionTimeout = 100000L;
        
          public GMLHSQLIndex() {       
          } 
        
        }
        

Of course, we extend `org.exist.indexing.spatial.AbstractGMLJDBCIndex`, then a few members are defined : a `Logger`, a file prefix (which will be required by the files required by HSQLDB storage, namely `spatial_index.lck`, `spatial_index.log`, `spatial_index.script` and `spatial_index.properties`), then a table name in which the spatial index data will be stored, then a variable that will hold the `org.exist.storage.DBBroker` that currently holds a connection to the DB (we could have used an `IndexWorker` here, given their 1:1 relationship). The problem is that we run HSQLDB in embedded mode and that only one connection is available at a given time.

A more elaborated DBMS, or HSQLDB running in server mode would permit the allocation of one connection per `IndexWorker`, but we have chosen to keep things simple for now. Indeed, if `IndexWorker`s are thread-safe (because each `org.exist.storage.DBBroker` operates within its own thread), a single connection will have to be controlled by the `Index` which is controlled by the `org.exist.storage.BrokerPool`. See below how we will handle concurrency, given such perequisites.

The last member is the timeout when a `Connection` to the DB is requested.

As we can see, we have an empty constructor again.

The next method calls its ancestor's configure() method and just retains the content of the connectionTimeout attribute as defined in the configuration file.

                 
        public void configure(BrokerPool pool, String dataDir, Element config) 
          throws DatabaseConfigurationException {
          super.configure(pool, dataDir, config);
          String param = ((Element)config).getAttribute("connectionTimeout");
          if (param != null) {
            try {
            connectionTimeout = Long.parseLong(param);
            } catch (NumberFormatException e) {
            LOG.error("Invalid value for 'connectionTimeout'", e);
            }
          }     
        }
        

The next method is also quite straightforward :

                 
        public IndexWorker getWorker(DBBroker broker) {
          GMLHSQLIndexWorker worker = (GMLHSQLIndexWorker)workers.get(broker);
          if (worker == null) {
            worker = new GMLHSQLIndexWorker(this, broker);
            workers.put(broker, worker);
          }
          return worker;
        }   
        

It picks an `IndexWorker` (more precisely a `org.exist.indexing.spatial.GMLHSQLIndexWorker` that will be described below) for the given `broker` from the "pool". If needed, namely the first time the method is called with with parameter, it creates one. Notice that this `IndexWorker` is DB-dependant. It will be described below.

Then come a few general-purpose methods:

                 
        protected void checkDatabase() 
          throws ClassNotFoundException, SQLException { 
          Class.forName("org.hsqldb.jdbcDriver");       
        }
        
        protected void shutdownDatabase()
          throws DBException {
          try {
            if (conn != null) {
            Statement stmt = conn.createStatement();                
            stmt.executeQuery("SHUTDOWN");
            stmt.close();
            conn.close();               
            if (LOG.isDebugEnabled()) 
              LOG.debug("GML index: " + getDataDir() + "/" + db_file_name_prefix + " closed");
            }
          } catch (SQLException e) {
            throw new DBException(e.getMessage()); 
          } finally {
          conn = null;
          }
        }
        
        protected void deleteDatabase()
          throws DBException {
          File directory = new File(getDataDir());
          File[] files = directory.listFiles( 
            new FilenameFilter() {
                  public boolean accept(File dir, String name) {
                return name.startsWith(db_file_name_prefix);
              }
            }
          );
          boolean deleted = true;
          for (int i = 0; i < files.length ; i++) {
            deleted &= files[i].delete();
          }
        }
        
        protected void removeIndexContent()
              throws DBException {
          try {
            //Let's be lazy here : we only delete th index content if we have a connection
            if (conn != null) {
            Statement stmt = conn.createStatement(); 
            int nodeCount = stmt.executeUpdate("DELETE FROM " + GMLHSQLIndex.TABLE_NAME + ";");       
            stmt.close();
            if (LOG.isDebugEnabled()) 
              LOG.debug("GML index: " + getDataDir() + "/" + db_file_name_prefix + ". " + 
              nodeCount + " nodes removed");
            }       
          } catch (SQLException e) {
            throw new DBException(e.getMessage()); 
          }
        }       
        

checkDatabase() just checks that we have a suitable driver in the CLASSPATH. We don't want to open the database right now. It costs too much.

shutdownDatabase() is just one of the many ways to shutdown a HSQLDB.

deleteDatabase() is just a file system management problem ; remember that the database should be closed at that moment : no file locking issues.

removeIndexContent() deletes the table that contains spatial data. Less efficient than deleteing the whole databse though ;-), as explained above.

The 2 next methods are totally JDBC-specific and, given the way they are implemented, are totally embedded HSQLDB-specific. The *current* code is directly adapted from `org.exist.storage.lock.ReentrantReadWriteLock` to show that connection management should be severely controlled given the concurrency context induced by using many `org.exist.storage.DBBroker`. Despite the fact `DBBroker`s are thread-safe, access to *shared* storage must be concurrential, in particular when flush() is called.

`org.exist.storage.index.BFile` users would call getLock() to acquire and release locks on the index files. Our solution is thus very similar.

However, since most JDBC databases are able to work in a concurrential context, it would then be better to never call these `Index`-level methods from the `IndexWorker`s and let each `IndexWorker` handle its connection to the underlying DB.

                 
        protected Connection acquireConnection(DBBroker broker)
          throws SQLException {
          synchronized (this) { 
            if (connectionOwner == null) {
              connectionOwner = broker;
              if (conn == null)
                initializeConnection();
              return conn;
            } else {    
              long waitTime = connectionTimeout;
              long waitTime = timeOut_;
              long start = System.currentTimeMillis();
              try {
                for (;;) {
              wait(waitTime);  
              if (connectionOwner == null) {
                connectionOwner = broker;                   
                if (conn == null)
                  //We should never get there since the connection should have been initialized
                  //by the first request from a worker
                initializeConnection();
                return conn;            
              } else {
                waitTime = timeOut_ - (System.currentTimeMillis() - start);
                if (waitTime <= 0) {
                  LOG.error("Time out while trying to get connection");
                }
              }
              }
            } catch (InterruptedException ex) {
              notify();
              throw new RuntimeException("interrupted while waiting for lock");
            }
          }
          }
        }

        protected synchronized void releaseConnection(DBBroker broker)
          throws SQLException {   
          if (connectionOwner == null)
            throw new SQLException("Attempted to release a connection that wasn't acquired");
          connectionOwner = null;
        }           
        

acquireConnection() acquires an *exclusive* JDBC `Connection` to the storage engine for an `IndexWorker` (or a `org.exist.storage.DBBroker`, which roughly means the same thing). This is where a `Connection` is created if necessary (see below) and makes the first connection's performance cost due only when needed.

releaseConnection() marks the connection as being unused. It will thus become available when requested again.

The last method concentrates the index-level DB-dependant code in just one place (removeIndexContent() is relatively DB-independant).

                 
        private void initializeConnection()
          throws SQLException {
          System.setProperty("hsqldb.cache_scale", "11");
          System.setProperty("hsqldb.cache_size_scale", "12");
          System.setProperty("hsqldb.default_table_type", "cached");
          //Get a connection to the DB... and keep it
          this.conn = DriverManager.getConnection("jdbc:hsqldb:" + getDataDir() + "/" + db_file_name_prefix, "sa", "");
          try { 
            ResultSet rs = this.conn.getMetaData().getTables(null, null, TABLE_NAME, new String[] { "TABLE" });
            rs.last(); 
            if (rs.getRow() == 1) {
              if (LOG.isDebugEnabled()) 
                LOG.debug("Opened GML index: " + getDataDir() + "/" + db_file_name_prefix); 
              //Create the data structure if it doesn't exist
            } else if (rs.getRow() == 0) {
              Statement stmt = conn.createStatement();
              stmt.executeUpdate("CREATE TABLE " + TABLE_NAME + "(" +
              /*1*/ "DOCUMENT_URI VARCHAR, " +              
              /*2*/ "NODE_ID_UNITS INTEGER, " + 
              /*3*/ "NODE_ID BINARY, " +                    
              ...               
              /*26*/ "IS_VALID BOOLEAN, " +
              //Enforce uniqueness
              "UNIQUE (" +
              "DOCUMENT_URI, NODE_ID_UNITS, NODE_ID" +
              ")" +
              ")"
              );
              stmt.executeUpdate("CREATE INDEX DOCUMENT_URI ON " + TABLE_NAME + " (DOCUMENT_URI);");
              ...
              stmt.close();         
              if (LOG.isDebugEnabled()) 
                LOG.debug("Created GML index: " + getDataDir() + "/" + db_file_name_prefix);  
            } else {
              throw new SQLException("2 tables with the same name ?"); 
            }
          } finally {
            if (rs != null)
            rs.close();                 
          }        
        }           
        

This method opens a `Connection` and, if it is a new one (*the* new one since we only have one), checks that we have a SQL table for the spatial data. If not, i.e. if the spatial index doesn't exist yet, a table is created with the following structure :

|                       |            |                                                                                                    |                                                                                                                                    |
|-----------------------|------------|----------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| Field name            | Field type | Description                                                                                        | Comments                                                                                                                           |
| DOCUMENT\_URI         | VARCHAR    | The document's URI                                                                                 |                                                                                                                                    |
| NODE\_ID\_UNITS       | INTEGER    | The number of useful *bits* in NODE\_ID                                                            | See below                                                                                                                          |
| NODE\_ID              | BINARY     | The node ID, as a byte array                                                                       | See above. Only *some* bits might be considered due to obvious data alignment requirements                                         |
| GEOMETRY\_TYPE        | VARCHAR    | The geometry type                                                                                  | As returned by the JTS                                                                                                             |
| SRS\_NAME             | VARCHAR    | The SRS of the geometry                                                                            | srsName attribute in the GML element                                                                                               |
| WKT                   | VARCHAR    | The [Well-Known Text](http://de.wikipedia.org/wiki/Well_Known_Text) representation of the geometry |                                                                                                                                    |
| WKB                   | BINARY     | The WKB representation of the geometry                                                             |                                                                                                                                    |
| MINX                  | DOUBLE     | The minimal X of the geometry                                                                      |                                                                                                                                    |
| MAXX                  | DOUBLE     | The maximal X of the geometry                                                                      |                                                                                                                                    |
| MINY                  | DOUBLE     | The minimal Y of the geometry                                                                      |                                                                                                                                    |
| MAXY                  | DOUBLE     | The maximal Y of the geometry                                                                      |                                                                                                                                    |
| CENTROID\_X           | DOUBLE     | The X of the geometry's centroid                                                                   |                                                                                                                                    |
| CENTROID\_Y           | DOUBLE     | The Y of the geometry's centroid                                                                   |                                                                                                                                    |
| AREA                  | DOUBLE     | The area of the geometry                                                                           | Expressed in the measure defined in its SRS                                                                                        |
| EPSG4326\_WKT         | VARCHAR    | The WKT representation of the geometry                                                             | In the [epsg:4326](http://en.wikipedia.org/wiki/EPSG:4326) SRS                                                                     |
| EPSG4326\_WKB         | BINARY     | The WKB representation of the geometry                                                             | In the epsg:4326 SRS                                                                                                               |
| EPSG4326\_MINX        | DOUBLE     | The minimal X of the geometry                                                                      | In the epsg:4326 SRS                                                                                                               |
| EPSG4326\_MAXX        | DOUBLE     | The maximal X of the geometry                                                                      | In the epsg:4326 SRS                                                                                                               |
| EPSG4326\_MINY        | DOUBLE     | The minimal Y of the geometry                                                                      | In the epsg:4326 SRS                                                                                                               |
| EPSG4326\_MAXY        | DOUBLE     | The maximal Y of the geometry                                                                      | In the epsg:4326 SRS                                                                                                               |
| EPSG4326\_CENTROID\_X | DOUBLE     | The X of the geometry's centroid                                                                   | In the epsg:4326 SRS                                                                                                               |
| EPSG4326\_CENTROID\_Y | DOUBLE     | The Y of the geometry's centroid                                                                   | In the epsg:4326 SRS                                                                                                               |
| EPSG4326\_AREA        | DOUBLE     | The area of the geometry                                                                           | In the epsg:4326 SRS (measure unknown, to be clarified)                                                                            |
| IS\_CLOSED            | BOOLEAN    | Whether or not this geometry is "closed"                                                           | See the [JTS documentation](http://www.vividsolutions.com/jts/bin/JTS%20Technical%20Specs.pdf) (chapter 13)                        |
| IS\_SIMPLE            | BOOLEAN    | Whether or not this geometry is "simple"                                                           | See the [JTS documentation](http://www.vividsolutions.com/jts/bin/JTS%20Technical%20Specs.pdf) (chapter 13)                        |
| IS\_VALID             | BOOLEAN    | Whether or not this geometry is "valid"                                                            | See the [JTS documentation](http://www.vividsolutions.com/jts/bin/JTS%20Technical%20Specs.pdf) (chapter 13). Should always be TRUE |

Uniqueness will be enforced on a `(DOCUMENT_URI, NODE_ID_UNITS, NODE_ID)` basis. Indeed, we can have at most one index entry for a given node in a given document.

Also, indexes are created on these fields to help queries :

-   DOCUMENT\_URI

-   NODE\_ID

-   GEOMETRY\_TYPE

-   WKB

-   EPSG4326\_WKB

-   EPSG4326\_MINX

-   EPSG4326\_MAXX

-   EPSG4326\_MINY

-   EPSG4326\_MAXY

-   EPSG4326\_CENTROID\_X

-   EPSG4326\_CENTROID\_Y

Every geometry will be internally stored in *both* its original SRS and in the epsg:4326 SRS. Having this kind of common, world-wide applicable, SRS for *all* geometries in the index allows to make operations on them even if they are originally defined in different SRSes.

> **Important**
>
> By default, eXist's build will download the lightweight `gt2-epsg-wkt-XXX.jar` library which lacks some parameters, the [Bursa-Wolf](http://udig.refractions.net/docs/api-geotools/org/geotools/referencing/datum/BursaWolfParameters.html) ones. A better accuracy for geographic transformations might be obtained by using a heavier library like [`gt2-epsg-hsql-XXX.jar`](http://lists.refractions.net/m2/org/geotools/gt2-epsg-hsql/) which is documented [here](http://javadoc.geotools.fr/snapshot/org/geotools/referencing/factory/epsg/FactoryOnHSQL.html).

### Writing the concrete implementation of `org.exist.indexing.IndexWorker`

Just like for `org.exist.indexing.spatial.AbstractGMLJDBCIndex`, we will start to design a database-independant abstract class. This class should normally be the basis of every JDBC spatial index. It will handle most of the hard work.

Let's start by a few members and a few general-purpose public methods :

     
          package org.exist.indexing.spatial;
          
          public abstract class AbstractGMLJDBCIndexWorker implements IndexWorker {
          
            public static String GML_NS = "http://www.opengis.net/gml";    
            protected final static String INDEX_ELEMENT = "gml";   
          
        private static final Logger LOG = Logger.getLogger(AbstractGMLJDBCIndexWorker.class);
          
        protected IndexController controller;
        protected AbstractGMLJDBCIndex index;
        protected DBBroker broker;
        protected int currentMode = StreamListener.UNKNOWN;    
        protected DocumentImpl currentDoc = null;  
        private boolean isDocumentGMLAware = false;
        protected Map geometries = new TreeMap();    
        NodeId currentNodeId = null;    
        Geometry streamedGeometry = null;
        boolean documentDeleted = false;
        int flushAfter = -1;
        protected GMLHandlerJTS geometryHandler = new GeometryHandler(); 
        protected GMLFilterGeometry geometryFilter = new GMLFilterGeometry(geometryHandler); 
        protected GMLFilterDocument geometryDocument = new GMLFilterDocument(geometryFilter);
        protected TreeMap transformations = new TreeMap();
        protected boolean useLenientMode = false;   
        protected GMLStreamListener gmlStreamListener = new GMLStreamListener(); 
        protected GeometryCoordinateSequenceTransformer coordinateTransformer = new GeometryCoordinateSequenceTransformer();
        protected GeometryTransformer gmlTransformer = new GeometryTransformer();       
        protected WKBWriter wkbWriter = new WKBWriter();
        protected WKBReader wkbReader = new WKBReader();
        protected WKTWriter wktWriter = new WKTWriter();
        protected WKTReader wktReader = new WKTReader();
        protected Base64Encoder base64Encoder = new Base64Encoder();
        protected Base64Decoder base64Decoder = new Base64Decoder();  
          
        public AbstractGMLJDBCIndexWorker(AbstractGMLJDBCIndex index, DBBroker broker) {
          this.index = index;
          this.broker = broker;
        }
          
        public String getIndexId() {
          return AbstractGMLJDBCIndex.ID;
        }        
          
        public String getIndexName() {
          return index.getIndexName();
        }
          
        public Index getIndex() {
          return index;
            }
          
          }         
          

Of course, `org.exist.indexing.spatial.AbstractGMLJDBCIndexWorker` implements `org.exist.indexing.IndexWorker`.

`GML_NS` is the GML namespace for which the spatial index is specially designed. Use this public member to avoid redundancy and, worse, inconsistencies.

`INDEX_ELEMENT` is the configuration's element name which is accurate for our `Index` configuration. To configure a collection in order to index its GML data, define such a configuration :

                 
          <collection xmlns="http://exist-db.org/collection-config/1.0">
            <index>
              <gml flushAfter="200"/>
            </index>
          </collection>     
          

Got the gml element? We will shortly see how this information is able to configure our `IndexWorker`.

`controller`, `index` and `broker` should now be quite straightforward.

`currentMode` and `currentDoc` should also be straightforward.

`geometries` is a collection of `com.vividsolutions.jts.geom.Geometry` instances that are currently held in memory, waiting for being "flushed" to the database. Depending of `currentMode`, they're pending for insertion or removal.

`currentNodeId` is used to share the ID of the node currently being processed between the different inner classes.

`streamedGeometry` is the last `com.vividsolutions.jts.geom.Geometry` that has been generated by GML parsing. It is `null` if the geometry is topologically not well formed. This latter case is maybe a too restrictive feature of Geotools parser which also throws `NullPointerException`s (!) if the GML is somehow not well-formed. See [GEOT-742](http://jira.codehaus.org/browse/GEOT-742) for more information on this issue.

`documentDeleted` is a flag indicating that the current document has been deleted and that we don't have to process it any more. Remember that `StreamListener.REMOVE_ALL_NODES` send some events for *all* nodes.

`flushAfter ` will hold our configuration's setting.

`geometryHandler` is our GML geometries SAX handler that will convert GML to a `com.vividsolutions.jts.geom.Geometry` instance. It is included in a handler chain composed of `geometryFilter` and `geometryDocument`.

`transforms` will cache a list a transformations between a source and a target SRS.

`useLenientMode` will be set to `true` is the transformation libraries that are in the CLASSPATH don't have the Bursa-Wolf parameters. Transformations will be attempted, but with a precision loss (see above).

`gmlStreamListener` is our own implementation of `org.exist.indexing.StreamListener`. Since there is a 1:1 (or even 1:0) relationship with the `IndexWorker`, it will be implemented as an inner class and will be described below.

`coordinateTransformer` will be needed during `Geometry` transformations to other SRSes.

`gmlTransformer` will be needed during `Geometry` transformations to XML.

`wkbWriter` and `wkbReader` will be needed during `Geometry` serialization and deserialization to and from the database.

`wktWriter` and `wktReader` will be needed during `Geometry` WKT serialization and deserialization to and from the database. WKT could be dynamically generated from `Geometry` but we have chosen to store it in the HSQLDB.

`base64Encoder` and `base64Decoder` will be needed to convert binary date, namely WKB, to XML types, namely `xs:base64Binary`.

No need to comment the methods, expect maybe getIndexId() that will return the *static* ID of the `Index`. No chance to be wrong with such a design.

The next method is a bit specific :

                 
          public Object configure(IndexController controller, NodeList configNodes, Map namespaces) 
            throws DatabaseConfigurationException {
        this.controller = controller;
        Map map = null;      
        for(int i = 0; i < configNodes.getLength(); i++) {
          Node node = configNodes.item(i);
          if (node.getNodeType() == Node.ELEMENT_NODE && INDEX_ELEMENT.equals(node.getLocalName())) { 
            map = new TreeMap();
            GMLIndexConfig config = new GMLIndexConfig(namespaces, (Element)node);
            map.put(AbstractGMLJDBCIndex.ID, config);
          }
            }
        return map;
          } 
          

It is only interested in the gml element of the configuration. If it finds one, it creates a `org.exist.indexing.spatial.GMLIndexConfig` instance wich is a very simple class :

                 
          package org.exist.indexing.spatial;

          public class GMLIndexConfig {

            private static final Logger LOG = Logger.getLogger(GMLIndexConfig.class);
          
        private final static String FLUSH_AFTER = "flushAfter"; 
        private int flushAfter = -1;
          
        public GMLIndexConfig(Map namespaces, Element node)
          throws DatabaseConfigurationException {       
          String param = ((Element)node).getAttribute(FLUSH_AFTER);
          if (param != null && !"".equals(param)) {) {
            try {
              flushAfter = Integer.parseInt(param);
            } catch (NumberFormatException e) {
              LOG.info("Invalid value for '" + FLUSH_AFTER + "'", e);
            }
          }         
            }
          
        public int getFlushAfter() {
          return flushAfter;
            }
          }         
          

... that retains the configuration attribute and provides a getter for it.

This configuration object is saved in a Map with the `Index` ID and will be available as shown in the next method :

                 
          public void setDocument(DocumentImpl document) {  
            isDocumentGMLAware = false;
        documentDeleted= false;
        if (document != null) {
          IndexSpec idxConf = document.getCollection().getIndexConfiguration(document.getBroker());
          if (idxConf != null) {
            Map collectionConfig = (Map) idxConf.getCustomIndexSpec(AbstractGMLJDBCIndex.ID);
            if (collectionConfig != null) {
              isDocumentGMLAware = true;
              if (collectionConfig.get(AbstractGMLJDBCIndex.ID) != null)
                flushAfter = ((GMLIndexConfig)collectionConfig.
              get(AbstractGMLJDBCIndex.ID)).getFlushAfter();
            }
              }
            }
        if (isDocumentGMLAware) {
          currentDoc = document;            
        } else {
          currentDoc = null;
          currentMode = StreamListener.UNKNOWN;         
            }
          }         
          

The objective is to determine if `document` should be indexed by the spatial `Index`.

For this, we look up its collection configuration and try to find a "custom" index specification for our `Index`. If one is found, our `document` will be processed by the `IndexWorker`. We also take advantage of this process to set one of our members. If `document` doesn't interest our `IndexWorker`, we reset some members to avoid having an inconsistent sticky state.

The next methods don't require any particular comment :

         
          public void setDocument(DocumentImpl doc, int mode) {
            setDocument(doc);
        setMode(mode);
          }

          public DocumentImpl getDocument() {
            return currentDoc;
          }

          public int getMode() {
            return currentMode;
          }             
          

The next method is somehow tricky :

                 
          public StreamListener getListener() {      
            if (currentDoc == null || currentMode == StreamListener.REMOVE_ALL_NODES)
          return null;
        return gmlStreamListener;
          }         
          

It doesn't return any `StreamListener` in the `StreamListner.REMOVE_ALL_NODES`. It would be totally unnecessary to listen at every node whereas a JDBC database will be able to delete all the document's nodes in one single statement.

The next method is a place holder that needs more thinking. How to highlight a geometric information smartly?

                 
          public MatchListener getMatchListener(NodeProxy proxy) {
            return null;
          }         
          

The next method computes the reindexing root. We will go bottom-up form the not to be modified until the top-most element in the GML namespace. Indeed, GML allows "nested" or "multi" geometries. If a single part of such `Geometry` is modified, the whole geometry has to be recomputed.

                 
          public StoredNode getReindexRoot(StoredNode node, NodePath path, boolean includeSelf) {
            if (!isDocumentGMLAware)
          //Not concerned
          return null;
        StoredNode topMost = node;
        StoredNode currentNode = node;
        for (int i = path.length() ; i > 0; i--) {
          currentNode = (StoredNode)currentNode.getParentNode();
          if (GML_NS.equals(currentNode.getNamespaceURI()))     
            topMost = currentNode;
            }
        return topMost;     
          }             
          

The next method delegates the write operations :

                 
          public void flush() {
            if (!isDocumentGMLAware)
          //Not concerned
          return;
        //Is the job already done ?
        if (currentMode == StreamListener.REMOVE_ALL_NODES && documentDeleted)
          return;
        Connection conn = null;
        try {
          conn = acquireConnection();
          conn.setAutoCommit(false);
          switch (currentMode) {
            case StreamListener.STORE :
              saveDocumentNodes(conn);
              break;
            case StreamListener.REMOVE_SOME_NODES :
              dropDocumentNode(conn);
              break;
            case StreamListener.REMOVE_ALL_NODES:
              removeDocument(conn);
              documentDeleted = true;
              break;
          }
          conn.commit();      
        } catch (SQLException e) {
          LOG.error("Document: " + currentDoc + " NodeID: " + currentNodeId, e);
          try {
            conn.rollback();
          } catch (SQLException ee) {
            LOG.error(ee);
          }
        } finally {
          try {
            if (conn != null) {
              conn.setAutoCommit(true);
              releaseConnection(conn);
            }
          } catch (SQLException e) {
            LOG.error(e);
          }             
        }
          } 
          

Even though its code looks thick, it proves to be a good way to acquire (then release) a `Connection` whatever the way it is provided by the `IndexWorker` (see above for these aspects, concurrency in particular). It then delegates the write operations to dedicated methods, which do not have to care about the `Connection`. Write operations are embedded in a transaction. Should an exception occur, it would be logged and swallowed: eXist doesn't like exceptions when it flushes its data.

The next method delegates node storage:

                 
          private void saveDocumentNodes(Connection conn) throws SQLException {
            if (geometries.size() == 0)
          return;  
        try {           
          for (Iterator iterator = geometries.entrySet().iterator(); iterator.hasNext();) {
            Map.Entry entry = (Map.Entry) iterator.next();
            NodeId nodeId = (NodeId)entry.getKey();
            SRSGeometry srsGeometry = (SRSGeometry)entry.getValue();        
            try {
              saveGeometryNode(srsGeometry.getGeometry(), srsGeometry.getSRSName(), 
              currentDoc, nodeId, conn);
            } finally {
              //Help the garbage collector
              srsGeometry = null;
            }
          }
        } finally {
          geometries.clear();
        }
          }         
          

It will call saveGeometryNode() (see below) passing a container inner class that will not be described given its simplicity.

The next two methods are built with the same design. The first one destroys the index entry for the currently processed node and the second one removes the index entries for the whole document.

                 
          private void dropDocumentNode(Connection conn)
            throws SQLException {       
        if (currentNodeId == null)
          return;        
        try {         
          boolean removed = removeDocumentNode(currentDoc, currentNodeId, conn);
          if (!removed)
            LOG.error("No data dropped for node " + currentNodeId.toString() + " from GML index");
          else {
            if (LOG.isDebugEnabled())               
              LOG.debug("Dropped data for node " + currentNodeId.toString() + " from GML index");
          }
        } finally {        
        currentNodeId = null;
        }
          }

          private void removeDocument(Connection conn)
            throws SQLException {
        if (LOG.isDebugEnabled())
          LOG.debug("Dropping GML index for document " + currentDoc.getURI());
        int nodeCount = removeDocument(currentDoc, conn);
        if (LOG.isDebugEnabled())
          LOG.debug("Dropped " + nodeCount + " nodes from GML index");
          } 
          

The next method is a mix of the designs described above. It also previously makes a check:

     
          public void removeCollection(Collection collection, DBBroker broker) {
            boolean isCollectionGMLAware = false;
        IndexSpec idxConf = collection.getIndexConfiguration(broker);
        if (idxConf != null) {
          Map collectionConfig = (Map) idxConf.getCustomIndexSpec(AbstractGMLJDBCIndex.ID);
          if (collectionConfig != null) {
            isCollectionGMLAware = (collectionConfig != null);
          }
        }
        if (!isCollectionGMLAware)
          return;  
          
        Connection conn = null;
        try {
          conn = acquireConnection();
          if (LOG.isDebugEnabled())
            LOG.debug("Dropping GML index for collection " + collection.getURI());
          int nodeCount = removeCollection(collection, conn);
          if (LOG.isDebugEnabled())
            LOG.debug("Dropped " + nodeCount + " nodes from GML index");
        } catch (SQLException e) {
          LOG.error(e);
        } finally {
          try {
            if (conn != null)
              releaseConnection(conn);
          } catch (SQLException e) {
            LOG.error(e);
          }         
        }
          }                         
          

Indeed, we have to check if the collection is indexable by the `Index` before trying to delete its index entries.

The next methods are built on the same design (`Collection` and exception management) and will thus not be described.

          public NodeSet search(DBBroker broker, NodeSet contextSet, Geometry EPSG4326_geometry, int spatialOp)
            ...     
          }

          public Geometry getGeometryForNode(DBBroker broker, NodeProxy p, boolean getEPSG4326) throws  SpatialIndexException {
            ...
          }

          protected Geometry[] getGeometriesForNodes(DBBroker broker, NodeSet contextSet, boolean getEPSG4326) throws SpatialIndexException {
            ...
          }

          public AtomicValue getGeometricPropertyForNode(DBBroker broker, NodeProxy p, String propertyName) 
          throws  SpatialIndexException {
            ...
          }    

          public ValueSequence getGeometricPropertyForNodes(DBBroker broker, NodeSet contextSet, String propertyName) 
          throws  SpatialIndexException {
            ...
          }         
          

... because all these methods delegate to the following abstract methods that will have to be implemented by the DB-dependant concrete classes :

         
          protected abstract boolean saveGeometryNode(Geometry geometry, String srsName, DocumentImpl doc, NodeId nodeId, Connection conn)
            throws SQLException;

          protected abstract boolean removeDocumentNode(DocumentImpl doc, NodeId nodeID, Connection conn)
            throws SQLException;

          protected abstract int removeDocument(DocumentImpl doc, Connection conn)
            throws SQLException;

          protected abstract int removeCollection(Collection collection, Connection conn)
            throws SQLException;
          
          protected abstract Connection acquireConnection() throws SQLException;

          protected abstract void releaseConnection(Connection conn) throws SQLException;    
          
          protected abstract NodeSet search(DBBroker broker, NodeSet contextSet, Geometry EPSG4326_geometry, int spatialOp, Connection conn)
            throws SQLException;         

          protected abstract Map getGeometriesForDocument(DocumentImpl doc, Connection conn)
            throws SQLException;

          protected abstract AtomicValue getGeometricPropertyForNode(DBBroker broker, NodeProxy p, Connection conn, 
          String propertyName) throws SQLException, XPathException;

          protected abstract ValueSequence getGeometricPropertyForNodes(DBBroker broker, NodeSet contextSet, Connection conn, String propertyName)
            throws SQLException, XPathException;

          protected abstract Geometry getGeometryForNode(DBBroker broker, NodeProxy p, boolean getEPSG4326, Connection conn)
            throws SQLException;

          protected abstract Geometry[] getGeometriesForNodes(DBBroker broker, NodeSet contextSet, boolean getEPSG4326, Connection conn)
            throws SQLException;

          protected abstract boolean checkIndex(DBBroker broker, Connection conn)
            throws SQLException, SpatialIndexException;  
          
          

Let's have a look however at this method that doesn't need a DB-dependant implementation :

     
          public Occurrences[] scanIndex(DocumentSet docs) {        
            Map occurences = new TreeMap();
        Connection conn = null;
        try { 
          conn = acquireConnection();
              //Collect the (normalized) geometries for each document
          for (Iterator iDoc = docs.iterator(); iDoc.hasNext();) {
            DocumentImpl doc = (DocumentImpl)iDoc.next();
            //TODO : check if document is GML-aware ?
            //Aggregate the occurences between different documents
            for (Iterator iGeom = getGeometriesForDocument(doc, conn).entrySet().iterator(); iGeom.hasNext();) {
              Map.Entry entry = (Map.Entry) iGeom.next();
              Geometry key = (Geometry)entry.getKey();
              //Do we already have an occurence for this geometry ?
              Occurrences oc = (Occurrences)occurences.get(key);
              if (oc != null) {
                //Yes : increment occurence count
            oc.addOccurrences(oc.getOccurrences() + 1);
            //...and reference the document
            oc.addDocument(doc);
                  } else {
                //No : create a new occurence with EPSG4326_WKT as "term"
            oc = new Occurrences((String)entry.getValue());
            //... with a count set to 1
            oc.addOccurrences(1);
            //... and reference the document
            oc.addDocument(doc);
            occurences.put(key, oc);
              }
            }
          }
        } catch (SQLException e) {
          LOG.error(e);
          return null;
        } finally {
          try {
            if (conn != null)
              releaseConnection(conn);
          } catch (SQLException e) {
            LOG.error(e);
            return null;
          } 
            }
        Occurrences[] result = new Occurrences[occurences.size()];
        occurences.values().toArray(result);
        return result;
          }                     
          

Same design (`Collection` and exception management, delegation mechanism). We probably will add more like this in the future.

The following methods are utility methods to stream `Geometry` instances to XML and vice-versa.

                 
          public Geometry streamNodeToGeometry(XQueryContext context, NodeValue node)
            throws SpatialIndexException {
        try {
          context.pushDocumentContext();
          try {         
            node.toSAX(context.getBroker(), geometryDocument, null);
          } finally {
            context.popDocumentContext();
          }
        } catch (SAXException e) {
          throw new SpatialIndexException(e);
        }
        return streamedGeometry;
          } 

          public Element streamGeometryToElement(Geometry geometry, String srsName, Receiver receiver)
            throws SpatialIndexException {           
        String gmlString = null;
        try {
          gmlString = gmlTransformer.transform(geometry);
        } catch (TransformerException e) {
          throw new SpatialIndexException(e);
        }
        try {
          SAXParserFactory factory = SAXParserFactory.newInstance();
          factory.setNamespaceAware(true);
          InputSource src = new InputSource(new StringReader(gmlString));
          SAXParser parser = factory.newSAXParser();
          XMLReader reader = parser.getXMLReader();
          reader.setContentHandler((ContentHandler)receiver);
          reader.parse(src);
          Document doc = receiver.getDocument();
          return doc.getDocumentElement(); 
        } catch (ParserConfigurationException e) {              
          throw new SpatialIndexException(e);
        } catch (SAXException e) {
          throw new SpatialIndexException(e);
        } catch (IOException e) {
          throw new SpatialIndexException(e);   
        }
          }         
          

The first one uses a `org.geotools.gml.GMLFilterDocument` (see below) and the second one uses a `org.geotools.gml.producer.GeometryTransformer` which needs some polishing because, despite it is called a transformer, it doesn't cope easily with a `Handler` and returns a... `String` ! See [GEOT-1315](http://codehaus01a.managed.contegix.com/browse/GEOT-1315).

The last method is also a utility method :

     
          public Geometry transformGeometry(Geometry geometry, String sourceCRS, String targetCRS)
            throws SpatialIndexException {
        if ("osgb:BNG".equalsIgnoreCase(sourceCRS.trim()))
          sourceCRS = "EPSG:27700";         
        if ("osgb:BNG".equalsIgnoreCase(targetCRS.trim()))
          targetCRS = "EPSG:27700"; 
        MathTransform transform = (MathTransform)transformations.get(sourceCRS + "_" + targetCRS);
        if (transform == null) {
          try {
            try {           
              transform = CRS.findMathTransform(CRS.decode(sourceCRS), CRS.decode(targetCRS), useLenientMode);
            } catch (OperationNotFoundException e) {
              LOG.info(e);
              LOG.info("Switching to lenient mode... beware of precision loss !");
              useLenientMode = true;
              transform = CRS.findMathTransform(CRS.decode(sourceCRS), CRS.decode(targetCRS), useLenientMode);  
            }
            transformations.put(sourceCRS + "_" + targetCRS, transform);
            LOG.debug("Instantiated transformation from '" + sourceCRS + "' to '" + targetCRS + "'");
          } catch (NoSuchAuthorityCodeException e) {
            LOG.error(e);
          } catch (FactoryException e) {
            LOG.error(e);
          }
        }
        if (transform == null) {
          throw new SpatialIndexException("Unable to get a transformation from '" + sourceCRS + "' to '" + targetCRS +"'");                         
        }
        coordinateTransformer.setMathTransform(transform);
        try {
          return coordinateTransformer.transform(geometry);
        } catch (TransformException e) {
          throw new SpatialIndexException(e);
            }
          }                 
          

It implements a workaround for our test file SRS which isn't yet known by Geotools libraries (see [GEOT-1307](http://codehaus01a.managed.contegix.com/browse/GEOT-1307)), then it tries to get the transformation from our cache. If it doesn't succeed, it tries to find one in the libraries that are in the CLASSPATH. Should those libraries lack the Bursa-Wolf parameters, it will make another attempt in lenient mode, which will induce a loss of accuracy. Then, it transforms the `Geometry` from its `sourceCRS` to the required `targetCRS`.

Now, let's study how the abstract methods are implement by the HSQLDB-dependant class :

     
          package org.exist.indexing.spatial;

          public class GMLHSQLIndexWorker extends AbstractGMLJDBCIndexWorker {

            private static final Logger LOG = Logger.getLogger(GMLHSQLIndexWorker.class);
          
        public GMLHSQLIndexWorker(GMLHSQLIndex index, DBBroker broker) {
          super(index, broker);
        }
          }                     
          

The only noticeable point is that we indeed extend our `org.exist.indexing.spatial.AbstractGMLJDBCIndexWorker`

Now, this method will do something more interesting, store the `Geometry` associated to a node :

                 
          protected boolean saveGeometryNode(Geometry geometry, String srsName, DocumentImpl doc, NodeId nodeId, Connection conn)
            throws SQLException {
        PreparedStatement ps = conn.prepareStatement("INSERT INTO " + GMLHSQLIndex.TABLE_NAME + "(" +
        /*1*/ "DOCUMENT_URI, " +                    
        /*2*/ "NODE_ID_UNITS, " + 
        /*3*/ "NODE_ID, " +                 
        /*4*/ "GEOMETRY_TYPE, " +
        /*5*/ "SRS_NAME, " +
        /*6*/ "WKT, " +
        /*7*/ "WKB, " +
        /*8*/ "MINX, " +
        /*9*/ "MAXX, " +
        /*10*/ "MINY, " +
        /*11*/ "MAXY, " +
        /*12*/ "CENTROID_X, " +
        /*13*/ "CENTROID_Y, " +
        /*14*/ "AREA, " +
        //Boundary ?                
        /*15*/ "EPSG4326_WKT, " +
        /*16*/ "EPSG4326_WKB, " +
        /*17*/ "EPSG4326_MINX, " +
        /*18*/ "EPSG4326_MAXX, " +
        /*19*/ "EPSG4326_MINY, " +
        /*20*/ "EPSG4326_MAXY, " +
        /*21*/ "EPSG4326_CENTROID_X, " +
        /*22*/ "EPSG4326_CENTROID_Y, " +
        /*23*/ "EPSG4326_AREA," +
        //Boundary ?
        /*24*/ "IS_CLOSED, " +
        /*25*/ "IS_SIMPLE, " +
        /*26*/ "IS_VALID" +             
        ") VALUES (" +
        "?, ?, ?, ?, ?, " +
        "?, ?, ?, ?, ?, " +
        "?, ?, ?, ?, ?, " +
        "?, ?, ?, ?, ?, " +
        "?, ?, ?, ?, ?, " +
        "?"
        + ")"
        );       
        try {
          Geometry EPSG4326_geometry = null;
          try {
            EPSG4326_geometry = transformGeometry(geometry, srsName, "EPSG:4326");
          } catch (SpatialIndexException e) {
            //Transforms the exception into an SQLException.
            SQLException ee = new SQLException(e.getMessage());
            ee.initCause(e);
            throw ee;
          }
          /*DOCUMENT_URI*/ ps.setString(1, doc.getURI().toString());    
          /*NODE_ID_UNITS*/ ps.setInt(2, nodeId.units());
          byte[] bytes = new byte[nodeId.size()];
          nodeId.serialize(bytes, 0);
          /*NODE_ID*/ ps.setBytes(3, bytes);
          /*GEOMETRY_TYPE*/ ps.setString(4, geometry.getGeometryType());
          /*SRS_NAME*/ ps.setString(5, srsName);
          /*WKT*/ ps.setString(6, wktWriter.write(geometry));
          /*WKB*/ ps.setBytes(7, wkbWriter.write(geometry));
          /*MINX*/ ps.setDouble(8, geometry.getEnvelopeInternal().getMinX());
          /*MAXX*/ ps.setDouble(9, geometry.getEnvelopeInternal().getMaxX());
          /*MINY*/ ps.setDouble(10, geometry.getEnvelopeInternal().getMinY());
          /*MAXY*/ ps.setDouble(11, geometry.getEnvelopeInternal().getMaxY());
          /*CENTROID_X*/ ps.setDouble(12, geometry.getCentroid().getCoordinate().x);   
          /*CENTROID_Y*/ ps.setDouble(13, geometry.getCentroid().getCoordinate().y);        
          /*AREA*/ ps.setDouble(14, geometry.getArea());        
          /*EPSG4326_WKT*/ ps.setString(15, wktWriter.write(EPSG4326_geometry));
          /*EPSG4326_WKB*/ ps.setBytes(16, wkbWriter.write(EPSG4326_geometry));     
          /*EPSG4326_MINX*/ ps.setDouble(17, EPSG4326_geometry.getEnvelopeInternal().getMinX());
          /*EPSG4326_MAXX*/ ps.setDouble(18, EPSG4326_geometry.getEnvelopeInternal().getMaxX());
          /*EPSG4326_MINY*/ ps.setDouble(19, EPSG4326_geometry.getEnvelopeInternal().getMinY());
          /*EPSG4326_MAXY*/ ps.setDouble(20, EPSG4326_geometry.getEnvelopeInternal().getMaxY());
          /*EPSG4326_CENTROID_X*/ ps.setDouble(21, EPSG4326_geometry.getCentroid().getCoordinate().x);   
          /*EPSG4326_CENTROID_Y*/ ps.setDouble(22, EPSG4326_geometry.getCentroid().getCoordinate().y);
          //EPSG4326_geometry.getRepresentativePoint()
          /*EPSG4326_AREA*/ ps.setDouble(23, EPSG4326_geometry.getArea());
          //For empty Curves, isClosed is defined to have the value false.
          /*IS_CLOSED*/ ps.setBoolean(24, !geometry.isEmpty());
          /*IS_SIMPLE*/ ps.setBoolean(25, geometry.isSimple());
          //Should always be true (the GML SAX parser makes a too severe check)
          /*IS_VALID*/ ps.setBoolean(26, geometry.isValid());
          return (ps.executeUpdate() == 1);
        } finally {
        if (ps != null)
          ps.close();
        //Let's help the garbage collector...
        geometry = null;
        }       
          }         
          

The generated SQL statement should be straightforward. We make a heavy use of the methods provided by `com.vividsolutions.jts.geom.Geometry`, both on the "native" `Geometry` and on its EPSG:4326 transformation. Would could probably store other properties here (like, e.g. the geometry's boundary). Other `IndexWorker`s, especially those accessing a spatially-enabled DBMS, might prefer to store fewer properties if they can be computed dynamically at a cheap price.

The next method is even much easier to understand :

                 
          protected boolean removeDocumentNode(DocumentImpl doc, NodeId nodeId, Connection conn)
            throws SQLException {
        PreparedStatement ps = conn.prepareStatement(
        "DELETE FROM " + GMLHSQLIndex.TABLE_NAME + 
        " WHERE DOCUMENT_URI = ? AND NODE_ID_UNITS = ? AND NODE_ID = ?;"
        ); 
        ps.setString(1, doc.getURI().toString());
        ps.setInt(2, nodeId.units());
        byte[] bytes = new byte[nodeId.size()];
        nodeId.serialize(bytes, 0);        
        ps.setBytes(3, bytes);
        try {    
          return (ps.executeUpdate() == 1);
        } finally {
          if (ps != null)
            ps.close();
            }
          }
          

... and this one even more :

                 
          protected int removeDocument(DocumentImpl doc, Connection conn)
            throws SQLException {       
        PreparedStatement ps = conn.prepareStatement(
        "DELETE FROM " + GMLHSQLIndex.TABLE_NAME + " WHERE DOCUMENT_URI = ?;"
        ); 
        ps.setString(1, doc.getURI().toString());
        try {
          return ps.executeUpdate();     
        } finally {
          if (ps != null)
            ps.close();
        }
          }             
          

This one however, is a little bit trickier :

         
          protected int removeCollection(Collection collection, Connection conn)
            throws SQLException {
        PreparedStatement ps = conn.prepareStatement(
        "DELETE FROM " + GMLHSQLIndex.TABLE_NAME + " WHERE SUBSTRING(DOCUMENT_URI, 1, ?) = ?;"
        ); 
        ps.setInt(1, collection.getURI().toString().length());
        ps.setString(2, collection.getURI().toString());
        try {
          return ps.executeUpdate();
        } finally {
          if (ps != null)
          ps.close();
        }
          } 
          

... maybe because it makes use of a SQL function to filter the right documents ?

The two next methods are straightforward, now that we have explained that `Connection`s had to be requested from the `Index` to avoid concurrency problems on an embedded HSQLDB instance.

     
          protected Connection acquireConnection()
            throws SQLException {   
        return index.acquireConnection(this.broker);
          }

          protected void releaseConnection(Connection conn)
            throws SQLException {   
        index.releaseConnection(this.broker);
          }
          

The next method is much more interesting. This is where is the core of the spatial index is:

                 
          protected NodeSet search(DBBroker broker, NodeSet contextSet, Geometry EPSG4326_geometry, int spatialOp, Connection conn)
            throws SQLException {
        String extraSelection = null;
        String bboxConstraint = null;       
        switch (spatialOp) {
          //BBoxes are equal
          case SpatialOperator.EQUALS:
            bboxConstraint = "(EPSG4326_MINX = ? AND EPSG4326_MAXX = ?)" +
            " AND (EPSG4326_MINY = ? AND EPSG4326_MAXY = ?)";
            break;
          //Nothing much we can do with the BBox at this stage
          case SpatialOperator.DISJOINT:
            //Retrieve the BBox though...
            extraSelection = ", EPSG4326_MINX, EPSG4326_MAXX, EPSG4326_MINY, EPSG4326_MAXY";
            break;
          //BBoxes intersect themselves
          case SpatialOperator.INTERSECTS:              
          case SpatialOperator.TOUCHES:                     
          case SpatialOperator.CROSSES:                         
          case SpatialOperator.OVERLAPS: 
            bboxConstraint = "(EPSG4326_MAXX >= ? AND EPSG4326_MINX <= ?)" +
            " AND (EPSG4326_MAXY >= ? AND EPSG4326_MINY <= ?)";
            break;
          //BBox is fully within
          case SpatialOperator.WITHIN:   
            bboxConstraint = "(EPSG4326_MINX >= ? AND EPSG4326_MAXX <= ?)" +
            " AND (EPSG4326_MINY >= ? AND EPSG4326_MAXY <= ?)";
            break;
          //BBox fully contains
          case SpatialOperator.CONTAINS: 
            bboxConstraint = "(EPSG4326_MINX <= ? AND EPSG4326_MAXX >= ?)" +
            " AND (EPSG4326_MINY <= ? AND EPSG4326_MAXY >= ?)";
            break;              
          default:
            throw new IllegalArgumentException("Unsupported spatial operator:" + spatialOp);
            }
        PreparedStatement ps = conn.prepareStatement(
        "SELECT EPSG4326_WKB, DOCUMENT_URI, NODE_ID_UNITS, NODE_ID" + (extraSelection == null ? "" : extraSelection) +
        " FROM " + GMLHSQLIndex.TABLE_NAME + 
        (bboxConstraint == null ? "" : " WHERE " + bboxConstraint) + ";"
        );
        if (bboxConstraint != null) {
          ps.setDouble(1, EPSG4326_geometry.getEnvelopeInternal().getMinX());
          ps.setDouble(2, EPSG4326_geometry.getEnvelopeInternal().getMaxX());
          ps.setDouble(3, EPSG4326_geometry.getEnvelopeInternal().getMinY());
          ps.setDouble(4, EPSG4326_geometry.getEnvelopeInternal().getMaxY());
        }
        ResultSet rs = null;
        NodeSet result = null;
        try { 
          int disjointPostFiltered = 0;
          rs = ps.executeQuery();
          result = new ExtArrayNodeSet(); //new ExtArrayNodeSet(docs.getLength(), 250)
          while (rs.next()) {
            DocumentImpl doc = null;
            try {
              doc = (DocumentImpl)broker.getXMLResource(XmldbURI.create(rs.getString("DOCUMENT_URI")));                 
            } catch (PermissionDeniedException e) {
              LOG.debug(e);
              //Ignore since the broker has no right on the document
              continue;
            }
            //contextSet == null should be use to scan the whole index
            if (contextSet == null || contextSet.getDocumentSet().contains(doc.getDocId())) {
              NodeId nodeId = new DLN(rs.getInt("NODE_ID_UNITS"), rs.getBytes("NODE_ID"), 0); 
              NodeProxy p = new NodeProxy((DocumentImpl)doc, nodeId);
              if (contextSet == null || contextSet.get(p) != null) {
                boolean geometryMatches = false;
            if (spatialOp == SpatialOperator.DISJOINT) {
              //No BBox intersection : obviously disjoint
              if (rs.getDouble("EPSG4326_MAXX") < EPSG4326_geometry.getEnvelopeInternal().getMinX() ||                      
              rs.getDouble("EPSG4326_MINX") > EPSG4326_geometry.getEnvelopeInternal().getMaxX() ||                      
              rs.getDouble("EPSG4326_MAXY") < EPSG4326_geometry.getEnvelopeInternal().getMinY() ||                      
              rs.getDouble("EPSG4326_MINY") > EPSG4326_geometry.getEnvelopeInternal().getMaxY()) {
                geometryMatches = true;
                disjointPostFiltered++;
              }
            }
            //Possible match : check the geometry
            if (!geometryMatches) { 
              try {             
                Geometry geometry = wkbReader.read(rs.getBytes("EPSG4326_WKB"));
                switch (spatialOp) {
                  case SpatialOperator.EQUALS:
                    geometryMatches = geometry.equals(EPSG4326_geometry);
                break;
                  case SpatialOperator.DISJOINT:                
                    geometryMatches = geometry.disjoint(EPSG4326_geometry);
                    break;          
                  case SpatialOperator.INTERSECTS:              
                    geometryMatches = geometry.intersects(EPSG4326_geometry);
                    break;
                  case SpatialOperator.TOUCHES:
                    geometryMatches = geometry.touches(EPSG4326_geometry);
                    break;      
                  case SpatialOperator.CROSSES:
                    geometryMatches = geometry.crosses(EPSG4326_geometry);
                    break;
                  case SpatialOperator.WITHIN:              
                    geometryMatches = geometry.within(EPSG4326_geometry);
                    break;      
                  case SpatialOperator.CONTAINS:                    
                    geometryMatches = geometry.contains(EPSG4326_geometry);
                    break;
                  case SpatialOperator.OVERLAPS:                    
                    geometryMatches = geometry.overlaps(EPSG4326_geometry);
                    break;
                }
              } catch (ParseException e) {
                //Transforms the exception into an SQLException.
                //Very unlikely to happen though...
                SQLException ee = new SQLException(e.getMessage());
                ee.initCause(e);
                throw ee;
              }
            }
            if (geometryMatches)            
              result.add(p);
              }
            }
          }
          if (LOG.isDebugEnabled()) {
            LOG.debug(rs.getRow() + " eligible geometries, " + result.getItemCount() + "selected" +
            (spatialOp == SpatialOperator.DISJOINT ? "(" + disjointPostFiltered + " post filtered)" : ""));
            }
            return result;          
            } finally { 
              if (rs != null)
            rs.close();
          if (ps != null)
            ps.close();             
            }
          }     
          

The trick is to filter the geometries on (fast) BBox operations first (intersecting geometries have BBox intersecting as well) which is possible in every case but for the Spatial.DISJOINT operator. For the latter case, we will have to fetch the BBox coordinates in order to apply a further filtering. Then, we examine the results and filter out the documents that are not in the `contextSet`. Spatial.DISJOINT filtering is then applied to avoid the next step in case the BBoxes are themselves disjoint. Only then, we perform the costly operations, namely `Geometry` deserialization from the DB then performing spatial operations on it. Matching nodes are then returned.

The next method is quite straightforward:

         
          protected Map getGeometriesForDocument(DocumentImpl doc, Connection conn)
            throws SQLException {
        PreparedStatement ps = conn.prepareStatement(
        "SELECT EPSG4326_WKB, EPSG4326_WKT FROM " + GMLHSQLIndex.TABLE_NAME + " WHERE DOCUMENT_URI = ?;"
        ); 
        ps.setString(1, doc.getURI().toString());
        ResultSet rs = null;
        try {
          rs = ps.executeQuery();
          Map map = new TreeMap();
          while (rs.next()) {
            Geometry EPSG4326_geometry = wkbReader.read(rs.getBytes("EPSG4326_WKB"));
            //Returns the EPSG:4326 WKT for every geometry to make occurrence aggregation consistent
            map.put(EPSG4326_geometry, rs.getString("EPSG4326_WKT"));
          }
          return map;
        } catch (ParseException e) {
          //Transforms the exception into an SQLException.
          //Very unlikely to happen though...
          SQLException ee = new SQLException(e.getMessage());
          ee.initCause(e);
          throw ee;
        } finally {   
          if (rs != null)
            rs.close();
          if (ps != null)
            ps.close();
        }
          }
          

Notice that it will return EPSG:4326 `Geometry`ies and that it will rethrow a `com.vividsolutions.jts.io.ParseException` as a `java.sql.SQLException`.

The next method is a bit more restrictive and modular :

          protected Geometry getGeometryForNode(DBBroker broker, NodeProxy p, boolean getEPSG4326, Connection conn)
            throws SQLException {
        PreparedStatement ps = conn.prepareStatement(
        "SELECT " + (getEPSG4326 ? "EPSG4326_WKB" : "WKB") +
        " FROM " + GMLHSQLIndex.TABLE_NAME + 
        " WHERE DOCUMENT_URI = ? AND NODE_ID_UNITS = ? AND NODE_ID = ?;"
        );
        ps.setString(1, p.getDocument().getURI().toString());
        ps.setInt(2, p.getNodeId().units());
        byte[] bytes = new byte[p.getNodeId().size()];
        p.getNodeId().serialize(bytes, 0);
        ps.setBytes(3, bytes);   
        ResultSet rs = null;        
        try {
          rs = ps.executeQuery();
          if (!rs.next())
            //Nothing returned
            return null;            
          Geometry geometry = wkbReader.read(rs.getBytes(1));                   
          if (rs.next()) {      
            //Should be impossible          
            throw new SQLException("More than one geometry for node " + p);
          }
          return geometry;    
        } catch (ParseException e) {
          //Transforms the exception into an SQLException.
          //Very unlikely to happen though...
          SQLException ee = new SQLException(e.getMessage());
          ee.initCause(e);
          throw ee;
        } finally {
          if (rs != null)
            rs.close();
          if (ps != null)
            ps.close();
            }
          }
          

... because if directly selects the right node and allows to return either the original `Geometry`, either its EPSG:4326 transformation.

The next method is a generalization of the previous one:

          protected Geometry[] getGeometriesForNodes(DBBroker broker, NodeSet contextSet, boolean getEPSG4326, Connection conn)
            throws SQLException {
        PreparedStatement ps = conn.prepareStatement(
        "SELECT " + (getEPSG4326 ? "EPSG4326_WKB" : "WKB") + ", DOCUMENT_URI, NODE_ID_UNITS, NODE_ID" +
        " FROM " + GMLHSQLIndex.TABLE_NAME 
        );
        ResultSet rs = null;        
        try {
          rs = ps.executeQuery();
          Geometry[] result = new Geometry[contextSet.getLength()];
          int index= 0;
          while (rs.next()) {
            DocumentImpl doc = null;
            try {
              doc = (DocumentImpl)broker.getXMLResource(XmldbURI.create(rs.getString("DOCUMENT_URI")));                 
            } catch (PermissionDeniedException e) {
              LOG.debug(e);
              result[index++] = null;
              //Ignore since the broker has no right on the document
              continue;
            }
            if (contextSet.getDocumentSet().contains(doc.getDocId())) {
              NodeId nodeId = new DLN(rs.getInt("NODE_ID_UNITS"), rs.getBytes("NODE_ID"), 0); 
              NodeProxy p = new NodeProxy((DocumentImpl)doc, nodeId);
              if (contextSet.get(p) != null) {
                Geometry geometry = wkbReader.read(rs.getBytes(1));
            result[index++] = geometry;
              }
                }
              }
          return result;
        } catch (ParseException e) {
            //Transforms the exception into an SQLException.
        //Very unlikely to happen though...
        SQLException ee = new SQLException(e.getMessage());
        ee.initCause(e);
        throw ee;
            } finally {   
              if (rs != null)
            rs.close();
          if (ps != null)
            ps.close();
        }
          }
          

It queries the whole index for the requested `Geometry`, ignoring the documents that are not in the `contextSet`, and it also ignores the nodes that are not in the `contextSet`. After that the `Geometry` is deserialized.

> **Note**
>
> This method is not yet used by the spatial functions but it is planned to use it in a future optimization effort.

This is the next method, designed like getGeometryForNode():

     
          protected AtomicValue getGeometricPropertyForNode(DBBroker broker, NodeProxy p, Connection conn, String propertyName)
            throws SQLException, XPathException {
        PreparedStatement ps = conn.prepareStatement(
        "SELECT " + propertyName + 
        " FROM " + GMLHSQLIndex.TABLE_NAME + 
        " WHERE DOCUMENT_URI = ? AND NODE_ID_UNITS = ? AND NODE_ID = ?"
        );
        ps.setString(1, p.getDocument().getURI().toString());
        ps.setInt(2, p.getNodeId().units());
        byte[] bytes = new byte[p.getNodeId().size()];
        p.getNodeId().serialize(bytes, 0);
        ps.setBytes(3, bytes);      
        ResultSet rs = null;        
        try {
          rs = ps.executeQuery();
          if (!rs.next())
            //Nothing returned
            return AtomicValue.EMPTY_VALUE;
              AtomicValue result = null;
          if (rs.getMetaData().getColumnClassName(1).equals(Boolean.class.getName())) {
            result = new BooleanValue(rs.getBoolean(1));
          } else if (rs.getMetaData().getColumnClassName(1).equals(Double.class.getName())) {
            result = new DoubleValue(rs.getDouble(1));
          } else if (rs.getMetaData().getColumnClassName(1).equals(String.class.getName())) {
            result = new StringValue(rs.getString(1));
          } else if (rs.getMetaData().getColumnType(1) == java.sql.Types.BINARY) {
            result = new Base64Binary(rs.getBytes(1));
          } else 
            throw new SQLException("Unable to make an atomic value from '" + rs.getMetaData().getColumnClassName(1) + "'");     
          if (rs.next()) {      
            //Should be impossible          
            throw new SQLException("More than one geometry for node " + p);
          }
          return result;    
        } finally {   
          if (rs != null)
            rs.close();
          if (ps != null)
            ps.close();
        }
          }
          

It directly requests the required property from the DB and returns an appropriate XML atomic value.

The next method is a generalization of the previous one :

             
          protected ValueSequence getGeometricPropertyForNodes(DBBroker broker, NodeSet contextSet, Connection conn, String propertyName)
            throws SQLException, XPathException {
        PreparedStatement ps = conn.prepareStatement(
        "SELECT " + propertyName + ", DOCUMENT_URI, NODE_ID_UNITS, NODE_ID" + 
        " FROM " + GMLHSQLIndex.TABLE_NAME
        );
        ResultSet rs = null;        
        try {
          rs = ps.executeQuery();
          ValueSequence result = new ValueSequence(contextSet.getLength());         
          while (rs.next()) {
            DocumentImpl doc = null;
            try {
              doc = (DocumentImpl)broker.getXMLResource(XmldbURI.create(rs.getString("DOCUMENT_URI")));                 
            } catch (PermissionDeniedException e) {
              LOG.debug(e);             
              if (rs.getMetaData().getColumnClassName(1).equals(Boolean.class.getName())) {
                result.add(BooleanValue.EMPTY_VALUE);
              } else if (rs.getMetaData().getColumnClassName(1).equals(Double.class.getName())) {
                result.add(DoubleValue.EMPTY_VALUE);
              } else if (rs.getMetaData().getColumnClassName(1).equals(String.class.getName())) {
                result.add(StringValue.EMPTY_VALUE);
              } else if (rs.getMetaData().getColumnType(1) == java.sql.Types.BINARY) {
                result.add(Base64Binary.EMPTY_VALUE);
                  } else 
                throw new SQLException("Unable to make an atomic value from '" + rs.getMetaData().getColumnClassName(1) + "'");
              //Ignore since the broker has no right on the document
              continue;
            }
            if (contextSet.getDocumentSet().contains(doc.getDocId())) {
              NodeId nodeId = new DLN(rs.getInt("NODE_ID_UNITS"), rs.getBytes("NODE_ID"), 0); 
              NodeProxy p = new NodeProxy((DocumentImpl)doc, nodeId);
              if (contextSet.get(p) != null) {
                if (rs.getMetaData().getColumnClassName(1).equals(Boolean.class.getName())) {
              result.add(new BooleanValue(rs.getBoolean(1)));
                } else if (rs.getMetaData().getColumnClassName(1).equals(Double.class.getName())) {
                  result.add(new DoubleValue(rs.getDouble(1)));
                } else if (rs.getMetaData().getColumnClassName(1).equals(String.class.getName())) {
                  result.add(new StringValue(rs.getString(1)));
                } else if (rs.getMetaData().getColumnType(1) == java.sql.Types.BINARY) {
                  result.add(new Base64Binary(rs.getBytes(1)));
                    } else 
                  throw new SQLException("Unable to make an atomic value from '" + rs.getMetaData().getColumnClassName(1) + "'");
            }
          }
            }
            return result;    
            } finally {   
              if (rs != null)
            rs.close();
          if (ps != null)
            ps.close();
            }
          }
          

It queries the whole index for the requested property, ignoring the documents that are not in the `contextSet`, and it also ignores the nodes that are not in the `contextSet`. Finally the property mapped to the appropriate XML atomic value is returned.

> **Note**
>
> This method is not yet used by the spatial functions but it is planned to use it in a future optimization effort.

The last method is a utility method and we will only show a part of its body:

         
          protected boolean checkIndex(DBBroker broker, Connection conn)
            throws SQLException {
        PreparedStatement ps = conn.prepareStatement(
        "SELECT * FROM " + GMLHSQLIndex.TABLE_NAME + ";"
        );
        ResultSet rs = null;
        try {
          rs = ps.executeQuery();
          while (rs.next()) {               
            Geometry original_geometry = wkbReader.read(rs.getBytes("WKB"));
            if (!original_geometry.equals(wktReader.read(rs.getString("WKT")))) {
              LOG.info("Inconsistent WKT : " + rs.getString("WKT"));
              return false;
                }                       
            Geometry EPSG4326_geometry = wkbReader.read(rs.getBytes("EPSG4326_WKB"));                   
            if (!EPSG4326_geometry.equals(wktReader.read(rs.getString("EPSG4326_WKT")))) {
              LOG.info("Inconsistent WKT : " + rs.getString("EPSG4326_WKT"));
              return false;
            }
          
            if (!original_geometry.getGeometryType().equals(rs.getString("GEOMETRY_TYPE"))) {
              LOG.info("Inconsistent geometry type: " + rs.getDouble("GEOMETRY_TYPE"));
              return false;
            }
            
            if (original_geometry.getEnvelopeInternal().getMinX() != rs.getDouble("MINX")) {
              LOG.info("Inconsistent MinX: " + rs.getDouble("MINX"));
              return false;
            }

            ...

        DocumentImpl doc = null;
        try {
          doc = (DocumentImpl)broker.getXMLResource(XmldbURI.create(rs.getString("DOCUMENT_URI")));
        } catch (PermissionDeniedException e) {
          //The broker has no right on the document
          LOG.error(e);
          return false;
            }
        NodeId nodeId = new DLN(rs.getInt("NODE_ID_UNITS"), rs.getBytes("NODE_ID"), 0);                 
        StoredNode node = broker.objectWith(new NodeProxy((DocumentImpl)doc, nodeId));
        if (node == null) {
          LOG.info("Node " + nodeId + "doesn't exist");
          return false;
        }      
        if (!GMLHSQLIndexWorker.GML_NS.equals(node.getNamespaceURI())) {
          LOG.info("GML indexed node (" + node.getNodeId()+ ") is in the '" + 
          node.getNamespaceURI() + "' namespace. '" + 
          GMLHSQLIndexWorker.GML_NS + "' was expected !");
          return false;
        }
        if (!original_geometry.getGeometryType().equals(node.getLocalName())) {
          if ("Box".equals(node.getLocalName()) && "Polygon".equals(original_geometry.getGeometryType())) {
            LOG.debug("GML indexed node (" + node.getNodeId() + ") is a gml:Box indexed as a polygon");
          } else {
            LOG.info("GML indexed node (" + node.getNodeId() + ") has '" + 
            node.getLocalName() + "' as its local name. '" + 
            original_geometry.getGeometryType() + "' was expected !");
            return false;
          }
            }
          
        LOG.info(node);                 
        }
        return true;
          
            } catch (ParseException e) {
              //Transforms the exception into an SQLException.
          //Very unlikely to happen though...
          SQL Exception ee = new SQLException(e.getMessage());
          ee.initCause(e);
          throw ee;
        } finally {   
          if (rs != null)
                rs.close();
              if (ps != null)
                ps.close(); 
            }
          }
          

It deserializes each `Geometry` and checks that its data are consistent with what is stored in the DB.

### Writing a concrete implementation of `org.exist.indexing.StreamListener`

The `StreamListener`'s main purpose is to generate `Geometry` instances, if accurate, from the nodes it listens to.

This will be done using a `org.geotools.gml.GMLFilterDocument` provided by the Geotools libraries. The trick is to map our STAX events to the expected SAX events.

As stated above, our `StreamListener` will be implemented as an inner class of `org.exist.indexing.spatial.AbstractGMLJDBCIndexWorker`. Of course, it will extend `org.exist.indexing.AbstractStreamListener`:

     
          private class GMLStreamListener extends AbstractStreamListener {
          
            Stack srsNamesStack = new Stack();
        ElementImpl deferredElement;
          
        public IndexWorker getWorker() {
          return AbstractGMLJDBCIndexWorker.this;
        }
          }
          

There are only two members. `srsNamesStack` will maintain a (`String`) `java.util.Stack` for the srsName attribute of the elements in the GML namespace (http://www.opengis.net/gml). `null` will be pushed if such an attribute doesn't exist, namely because it isn't accurate.

`deferredElement` will hold an element whose streaming is deferred, namely because we still haven't received its attributes.

The getWorker() method should be straightforward.

Let's see how the process is performed:

         
          public void startElement(Txn transaction, ElementImpl element, NodePath path) { 
            if (isDocumentGMLAware) {
          //Release the deferred element if any
          if (deferredElement != null)              
            processDeferredElement();
          //Retain this element
          deferredElement = element;  
        }
        //Forward the event to the next listener 
        super.startElement(transaction, element, path);
          }
          
          public void attribute(Txn transaction, AttrImpl attrib, NodePath path) { 
            //Forward the event to the next listener 
        super.attribute(transaction, attrib, path);
          }        

          public void characters(Txn transaction, TextImpl text, NodePath path) {
            if (isDocumentGMLAware) {
          //Release the deferred element if any
          if (deferredElement != null)              
            processDeferredElement();               
          try {
            geometryDocument.characters(text.getData().toCharArray(), 0, text.getLength());
          } catch (Exception e) {
            LOG.error(e);
          } 
        }
        //Forward the event to the next listener 
        super.characters(transaction, text, path);
          }

          public void endElement(Txn transaction, ElementImpl element, NodePath path) {
            if (isDocumentGMLAware) {   
          //Release the deferred element if any
          if (deferredElement != null)              
            processDeferredElement();               
          //Process the element 
          processCurrentElement(element);
        }
            //Forward the event to the next listener 
        super.endElement(transaction, element, path);
          }
          

Element deferring occurs only if `currentDoc` is to be indexed of course. If so, an incoming element is deferred but we do not forget to forward the event to the next `StreamListener` in the pipeline.

If we have a deferred element, we will process it (see below) in order to collect its attributes and if relevant, endElement(), will add an index entry for the current element. The method characters() also forwards its data to the SAX handler.

> **Note**
>
> We could have used attribute() to collect the deferred element's attributes. The described design is just a matter of choice.

Let's see how the deferred element is processed :

                 
          private void processDeferredElement() {  
            //We need to collect the deferred element's attributes in order to feed the SAX handler
        AttributesImpl attList = new AttributesImpl();
        NamedNodeMap attrs = deferredElement.getAttributes();
          
        String whatToPush = null;
        
        for (int i = 0; i < attrs.getLength() ; i++) {
          AttrImpl attrib = (AttrImpl)attrs.item(i);
          
          //Store the srs
          if (GML_NS.equals(deferredElement.getNamespaceURI())) {
            //Maybe we could assume a configurable default value here
            if (attrib.getName().equals("srsName")) {               
              whatToPush = attrib.getValue();
            }
            srsNamesStack.push(whatToPush);
          } 
          
          attList.addAttribute(attrib.getNamespaceURI(), 
          attrib.getLocalName(), 
          attrib.getQName().getStringValue(), 
          Integer.toString(attrib.getType()), 
          attrib.getValue());                   
            } 
          
        srsNamesStack.push(whatToPush);

        try {
          geometryDocument.startElement(deferredElement.getNamespaceURI(), deferredElement.getLocalName(), deferredElement.getQName().getStringValue(), attList);
        } catch (Exception e) {
          e.printStackTrace();
          LOG.error(e);
        } finally {
          deferredElement = null;                   
        }
          }
          

We first need to collect its attributes and that's why it is deferred, because attributes events come *after* the call to startElement(). Elements in the GML namespace that carry an srsName attribute will push its value. If the element is not in the GML namespace or if no srsName attribute exists, `null` is pushed.

> **Note**
>
> We could have had a smarter mechanism, but we first have to take a decision about the fact that we could define a default SRS here, either from the config, or from a higher-level element. This part of the code will thus probably be revisited once the decision is taken.

When the attributes are collected, we can send a `startElement()` event to the SAX handler, thus marking the end of the deferring process.

Processing of the current element with endElement():

     
          private void processCurrentElement(ElementImpl element) {
            String currentSrsName = (String)srsNamesStack.pop();                
        try {
          geometryDocument.endElement(element.getNamespaceURI(), element.getLocalName(), element.getQName().getStringValue());
          //Some invalid/(yet) incomplete geometries don't have a SRS
          if (streamedGeometry != null && currentSrsName != null) {   
            currentNodeId = element.getNodeId();
            geometries.put(currentNodeId, new SRSGeometry(currentSrsName, streamedGeometry));                       
            if (flushAfter != -1 && geometries.size() >= flushAfter) {
              //Mmmh... doesn't flush since it is currently dependant from the
              //number of nodes in the DOM file ; would need refactorings
              //currentDoc.getBroker().checkAvailableMemory();
              currentDoc.getBroker().flush();
              ///Aaaaaargl !
              final double percent = ((double) Runtime.getRuntime().freeMemory() / (double) Runtime.getRuntime().maxMemory()) * 100;
              if (percent < 30) {                   
                System.gc();
              }
                }
              }             
        } catch (Exception e) {
          LOG.error("Unable to collect geometry for node: " + currentNodeId + ". Indexing will be skipped", e);             
        } finally {  
          streamedGeometry = null;                      
        }
          }                 
          

We first pop a SRS name from the stack. `null` will indicate that the element doesn't have any and thus that it is an element which doesn't carry enough information to build a complete geometry. That doesn't prevent us to forward this element to the SAX handler.

The SAX handler might have been able to build a `Geometry` then. If so, the current index entry (composed of `currentSrsName`, `streamedGeometry`, `currentNodeId` and the "global" `org.exist.dom.DocumentImpl`) is added to `geometries` (wrapped in the convenience `SRSGeometry` class). We then check if it's time to flush the pending index entries.

This is how the `GeometryHandler` looks like. It is also implemented as an inner class of `org.exist.indexing.spatial.AbstractGMLJDBCIndexWorker`

                 
          private class GeometryHandler extends XMLFilterImpl implements GMLHandlerJTS {
            public void geometry(Geometry geometry) {
          streamedGeometry = geometry;          
          //TODO : null geometries can be returned for many reasons, including a (too) strict
          //topology check done by the Geotools SAX parser.
          //It would be nice to have static classes extending Geometry to report such geometries
          if (geometry == null)
            LOG.error("Collected null geometry for node: " + currentNodeId + ". Indexing will be skipped");
        }
          }
          

Thanks to Geotools SAX parser, it hasn't to be more complicated than setting the `streamedGeometry` "global" member.

> **Note**
>
> However, it may throw some `NullPointerException`s as described above.

### Implementing some functions that cooperate with the spatial index

We currently provide three sets of functions that are able to cooperate with spatial indexes.

The functions are declared in the `org.exist.xquery.modules.spatial.SpatialModule` module which operates in the `http://exist-db.org/xquery/spatial` namespace (whose default prefix is `spatial`).

The functions signatures are documented together with the functions themselves in [this page](http://demo.exist-db.org/xquery/functions.xq). Here we will only look at their eval() methods.

The first functions set we will describe is `org.exist.xquery.modules.spatial.FunSpatialSearch`, which performs searches on the spatial index:

                 
          public Sequence eval(Sequence[] args, Sequence contextSequence) throws XPathException {
            Sequence result = null;
        Sequence nodes = args[0];        
        if (nodes.isEmpty())
          result = Sequence.EMPTY_SEQUENCE;
        else if (args[1].isEmpty())
          //TODO : to be discussed. We could also return an empty sequence here         
          result = nodes;
        else {
          try {
            AbstractGMLJDBCIndexWorker indexWorker = (AbstractGMLJDBCIndexWorker)           
            context.getBroker().getIndexController().getWorkerByIndexId(AbstractGMLJDBCIndex.ID);
            if (indexWorker == null)
              throw new XPathException("Unable to find a spatial index worker");
            Geometry EPSG4326_geometry = null;
            NodeValue geometryNode = (NodeValue) args[1].itemAt(0);   
            if (geometryNode.getImplementationType() == NodeValue.PERSISTENT_NODE)
              //Get the geometry from the index if available
              EPSG4326_geometry = indexWorker.getGeometryForNode(context.getBroker(), (NodeProxy)geometryNode, true);
            if (EPSG4326_geometry == null) {
              String sourceCRS = ((Element)geometryNode.getNode()).getAttribute("srsName").trim();
              Geometry geometry = indexWorker.streamNodeToGeometry(context, geometryNode);              
              EPSG4326_geometry = indexWorker.transformGeometry(geometry, sourceCRS, "EPSG:4326");                          
            }
            if (EPSG4326_geometry == null) 
              throw new XPathException("Unable to get a geometry from the node");
            int spatialOp = SpatialOperator.UNKNOWN;
            if (isCalledAs("equals"))
              spatialOp = SpatialOperator.EQUALS;
            else if (isCalledAs("disjoint"))
              spatialOp = SpatialOperator.DISJOINT;
                else if (isCalledAs("intersects"))
              spatialOp = SpatialOperator.INTERSECTS;    
            else if (isCalledAs("touches"))
              spatialOp = SpatialOperator.TOUCHES;
            else if (isCalledAs("crosses"))
              spatialOp = SpatialOperator.CROSSES;     
            else if (isCalledAs("within"))
              spatialOp = SpatialOperator.WITHIN;       
            else if (isCalledAs("contains"))
              spatialOp = SpatialOperator.CONTAINS;     
                else if (isCalledAs("overlaps"))
              spatialOp = SpatialOperator.OVERLAPS;
            //Search the EPSG:4326 in the index
            result = indexWorker.search(context.getBroker(),  nodes.toNodeSet(), EPSG4326_geometry, spatialOp);
            hasUsedIndex = true;                
          } catch (SpatialIndexException e) {
            throw new XPathException(e);
          }
        }
        return result;
          }
          

We first build an early result if empty sequences are passed to the function.

Then, we try to access the `XQueryContext`'s `AbstractGMLJDBCIndex` (remember that there is a 1:1 relationship between `XQueryContext` and `DBBroker` and a 1:1 relationship between `DBBroker` and `IndexWorker`). If we can not find an `AbstractGMLJDBCIndex` we throw an `Exception` since we will need this and its concrete class to delegate spatial operations to (whatever its underlying DB implementation is, thanks to our generic design).

Then, we examine if the geometry node is persistent, in which case it *might* be indexed. If so, we try to get an EPSG:4326 `Geometry` from the index.

If nothing is returned here, either because the node isn't indexed or because it is an in-memory node, we stream it to a `Geometry` and we transform this into an EPSG:4326 `Geometry`. Of course, this process is slower than a direct lookup into the index.

Then we search for the geometry in the index after having determined the spatial operator from the function's name.

The second functions set is `org.exist.xquery.modules.spatial.FunGeometricProperties`, which retrieves a property for a `Geometry`:

     
          public Sequence eval(Sequence[] args, Sequence contextSequence) throws XPathException {
            Sequence result = null;
        Sequence nodes = args[0];        
        if (nodes.isEmpty())
          result = Sequence.EMPTY_SEQUENCE;
        else {
          try {
            Geometry geometry = null;
            String sourceCRS = null;
            AbstractGMLJDBCIndexWorker indexWorker = (AbstractGMLJDBCIndexWorker)
            context.getBroker().getIndexController().getWorkerByIndexId(AbstractGMLJDBCIndex.ID);
            if (indexWorker == null)
              throw new XPathException("Unable to find a spatial index worker");
            String propertyName = null;
            if (isCalledAs("getWKT")) {
              propertyName = "WKT";
            } else if (isCalledAs("getWKB")) {
              propertyName = "WKB";                     
            } else if (isCalledAs("getMinX")) {
              propertyName = "MINX";                        
            } else if (isCalledAs("getMaxX")) {                 
              propertyName = "MAXX";
            } else if (isCalledAs("getMinY")) {
              propertyName = "MINY";
            } else if (isCalledAs("getMaxY")) {
              propertyName = "MAXY";
            } else if (isCalledAs("getCentroidX")) {
              propertyName = "CENTROID_X";
            } else if (isCalledAs("getCentroidY")) {
              propertyName = "CENTROID_Y";
            } else if (isCalledAs("getArea")) {
              propertyName = "AREA";
            } else if (isCalledAs("getEPSG4326WKT")) {
              propertyName = "EPSG4326_WKT";      
            } else if (isCalledAs("getEPSG4326WKB")) {
              propertyName = "EPSG4326_WKB";
            } else if (isCalledAs("getEPSG4326MinX")) {
              propertyName = "EPSG4326_MINX";
            } else if (isCalledAs("getEPSG4326MaxX")) {
              propertyName = "EPSG4326_MAXX";
            } else if (isCalledAs("getEPSG4326MinY")) {
              propertyName = "EPSG4326_MINY";
            } else if (isCalledAs("getEPSG4326MaxY")) {
              propertyName = "EPSG4326_MAXY";
            } else if (isCalledAs("getEPSG4326CentroidX")) {
              propertyName = "EPSG4326_CENTROID_X";
            } else if (isCalledAs("getEPSG4326CentroidY")) {
              propertyName = "EPSG4326_CENTROID_Y";
            } else if (isCalledAs("getEPSG4326Area")) {
              propertyName = "EPSG4326_AREA";
            } else if (isCalledAs("getSRS")) {
              propertyName = "SRS_NAME";
            } else if (isCalledAs("getGeometryType")) {
              propertyName = "GEOMETRY_TYPE";
            } else if (isCalledAs("isClosed")) {
              propertyName = "IS_CLOSED";
            } else if (isCalledAs("isSimple")) {
              propertyName = "IS_SIMPLE";
            } else if (isCalledAs("isValid")) {
              propertyName = "IS_VALID";
            } else {
              throw new XPathException("Unknown spatial property: " + mySignature.getName().getLocalName());
            } 
            NodeValue geometryNode = (NodeValue) nodes.itemAt(0);
            if (geometryNode.getImplementationType() == NodeValue.PERSISTENT_NODE) {
              if (propertyName != null) {
                //The node should be indexed : get its property
            result = indexWorker.getGeometricPropertyForNode(context.getBroker(), (NodeProxy)geometryNode, propertyName);
            hasUsedIndex = true;
              } else {
                //Or, at least, its geometry for further processing
            if (propertyName.indexOf("EPSG4326") != Constants.STRING_NOT_FOUND) {
              geometry = indexWorker.getGeometryForNode(context.getBroker(), (NodeProxy)geometryNode, true);
              sourceCRS = "EPSG:4326";
            } else {
              geometry = indexWorker.getGeometryForNode(context.getBroker(), (NodeProxy)geometryNode, false);
              sourceCRS = indexWorker.getGeometricPropertyForNode(context.getBroker(), (NodeProxy)geometryNode, "SRS_NAME").getStringValue();
            }
              }
            }
            if (result == null) {
              //builds the geometry
              if (geometry == null) {
                sourceCRS = ((Element)geometryNode.getNode()).getAttribute("srsName").trim();
            geometry = indexWorker.streamNodeToGeometry(context, geometryNode);                     
              } 
              if (geometry == null) 
                throw new XPathException("Unable to get a geometry from the node");
              //Transform the geometry to EPSG:4326 if relevant
              if (propertyName.indexOf("EPSG4326") != Constants.STRING_NOT_FOUND) {
              geometry = indexWorker.transformGeometry(geometry, sourceCRS, "EPSG:4326");
              if (isCalledAs("getEPSG4326WKT")) {
                result = new StringValue(wktWriter.write(geometry));
              } else if (isCalledAs("getEPSG4326WKB")) {
                result = new Base64Binary(wkbWriter.write(geometry));
              } else if (isCalledAs("getEPSG4326MinX")) {
                result = new DoubleValue(geometry.getEnvelopeInternal().getMinX());
              } else if (isCalledAs("getEPSG4326MaxX")) {
                result = new DoubleValue(geometry.getEnvelopeInternal().getMaxX());
              } else if (isCalledAs("getEPSG4326MinY")) {
                result = new DoubleValue(geometry.getEnvelopeInternal().getMinY());
                  } else if (isCalledAs("getEPSG4326MaxY")) {
                result = new DoubleValue(geometry.getEnvelopeInternal().getMaxY());
              } else if (isCalledAs("getEPSG4326CentroidX")) {
                result = new DoubleValue(geometry.getCentroid().getX());
              } else if (isCalledAs("getEPSG4326CentroidY")) {
                result = new DoubleValue(geometry.getCentroid().getY());
              } else if (isCalledAs("getEPSG4326Area")) {
                result = new DoubleValue(geometry.getArea());
              }
            } else if (isCalledAs("getWKT")) {
              result = new StringValue(wktWriter.write(geometry));
            } else if (isCalledAs("getWKB")) {
              result = new Base64Binary(wkbWriter.write(geometry));
            } else if (isCalledAs("getMinX")) {
              result = new DoubleValue(geometry.getEnvelopeInternal().getMinX());
            } else if (isCalledAs("getMaxX")) {
              result = new DoubleValue(geometry.getEnvelopeInternal().getMaxX());
            } else if (isCalledAs("getMinY")) {
              result = new DoubleValue(geometry.getEnvelopeInternal().getMinY());
            } else if (isCalledAs("getMaxY")) {
              result = new DoubleValue(geometry.getEnvelopeInternal().getMaxY());
            } else if (isCalledAs("getCentroidX")) {
              result = new DoubleValue(geometry.getCentroid().getX());
            } else if (isCalledAs("getCentroidY")) {
              result = new DoubleValue(geometry.getCentroid().getY());
            } else if (isCalledAs("getArea")) {
              result = new DoubleValue(geometry.getArea());
            } else if (isCalledAs("getSRS")) {
              result = new StringValue(((Element)geometryNode).getAttribute("srsName"));
            } else if (isCalledAs("getGeometryType")) {
              result = new StringValue(geometry.getGeometryType());
            } else if (isCalledAs("isClosed")) {
              result = new BooleanValue(!geometry.isEmpty());
            } else if (isCalledAs("isSimple")) {
              result = new BooleanValue(geometry.isSimple());
            } else if (isCalledAs("isValid")) {
              result = new BooleanValue(geometry.isValid());
            } else {
              throw new XPathException("Unknown spatial property: " + mySignature.getName().getLocalName());
            }
          }
          } catch (SpatialIndexException e) {
            throw new XPathException(e);
          }
            }
        return result;
          }
          

The design is very much the same : we build an early result if empty sequences are involved, we get a `AbstractGMLJDBCIndex`, then we set a `propertyName`, which is actually a SQL field name, depending on the function's name.

An attempt to retrieve the field content from the DB is made and, if unsuccessful, we try to get the node's `Geometry` from the index.

Then, if we still haven't got this `Geometry`, either because the node isn't indexed or because it is an in-memory node, we stream it to a `Geometry` and we transform this into an EPSG:4326 `Geometry` if the function's name requires to do so.

We then *dynamically* build the property to be returned.

> **Note**
>
> This mechanism if far from being efficient compared to the index lookup, but it shows how easy it would be to return a property which is not available in a spatial index.

The third functions set, `org.exist.xquery.modules.spatial.FunGMLProducers`, uses the same design :

                 
          public Sequence eval(Sequence[] args, Sequence contextSequence)
            throws XPathException {
        Sequence result = null; 
        try {
          AbstractGMLJDBCIndexWorker indexWorker = (AbstractGMLJDBCIndexWorker)
          context.getBroker().getIndexController().getWorkerByIndexId(AbstractGMLJDBCIndex.ID);
          if (indexWorker == null)
            throw new XPathException("Unable to find a spatial index worker");
          Geometry geometry = null;         
          String targetSRS = null;
          if (isCalledAs("transform")) {
            if (args[0].isEmpty())
              result = Sequence.EMPTY_SEQUENCE;
            else {
              NodeValue geometryNode = (NodeValue) args[0].itemAt(0);
              //Try to get the geometry from the index
              String sourceSRS = null;
              if (geometryNode.getImplementationType() == NodeValue.PERSISTENT_NODE) {
                sourceSRS = indexWorker.getGeometricPropertyForNode(context.getBroker(), (NodeProxy)geometryNode, "SRS_NAME").getStringValue();
            geometry = indexWorker.getGeometryForNode(context.getBroker(), (NodeProxy)geometryNode, false);                     
            hasUsedIndex = true;
              }
              //Otherwise, build it
              if (geometry == null) {
                sourceSRS = ((Element)geometryNode.getNode()).getAttribute("srsName").trim();
            geometry = indexWorker.streamNodeToGeometry(context, geometryNode);
              }
              if (geometry == null) 
                throw new XPathException("Unable to get a geometry from the node");
            targetSRS = args[1].itemAt(0).getStringValue().trim();
          
            geometry = indexWorker.transformGeometry(geometry, sourceSRS, targetSRS);
              }
            } else if (isCalledAs("WKTtoGML")) {
              if (args[0].isEmpty())
                result = Sequence.EMPTY_SEQUENCE;
              else {
                String wkt = args[0].itemAt(0).getStringValue();
            WKTReader wktReader = new WKTReader();
            try {           
             geometry = wktReader.read(wkt);
            } catch (ParseException e) {
            throw new XPathException(e);    
            }
            if (geometry == null) 
              throw new XPathException("Unable to get a geometry from the node");
            targetSRS = args[1].itemAt(0).getStringValue().trim();
          }
        } else if (isCalledAs("buffer")) {
          if (args[0].isEmpty())
            result = Sequence.EMPTY_SEQUENCE;
          else {
            NodeValue geometryNode = (NodeValue) args[0].itemAt(0);                             
            //Try to get the geometry from the index
            if (geometryNode.getImplementationType() == NodeValue.PERSISTENT_NODE) {
              targetSRS = indexWorker.getGeometricPropertyForNode(context.getBroker(), (NodeProxy)geometryNode, "SRS_NAME").getStringValue();
              geometry = indexWorker.getGeometryForNode(context.getBroker(), (NodeProxy)geometryNode, false);                       
              hasUsedIndex = true;
            }
            //Otherwise, build it
            if (geometry == null) {
              targetSRS =  ((Element)geometryNode.getNode()).getAttribute("srsName").trim();
              geometry = indexWorker.streamNodeToGeometry(context, geometryNode);
            }
            if (geometry == null) 
              throw new XPathException("Unable to get a geometry from the node");
            double distance = ((DoubleValue)args[1].itemAt(0)).getDouble();
            int quadrantSegments = 8;   
            int endCapStyle = BufferOp.CAP_ROUND;
            if (getArgumentCount() > 2 && Type.subTypeOf(args[2].itemAt(0).getType(), Type.INTEGER))
              quadrantSegments = ((IntegerValue)args[2].itemAt(0)).getInt();
            if (getArgumentCount() > 3 && Type.subTypeOf(args[3].itemAt(0).getType(), Type.INTEGER))
              endCapStyle = ((IntegerValue)args[3].itemAt(0)).getInt();
            switch (endCapStyle) {
              case BufferOp.CAP_ROUND:
              case BufferOp.CAP_BUTT:
              case BufferOp.CAP_SQUARE:
                //OK
            break;
              default:
                throw new XPathException("Invalid line end style"); 
            }           
            geometry = geometry.buffer(distance, quadrantSegments, endCapStyle);
          }
        } else if (isCalledAs("getBbox")) {
          if (args[0].isEmpty())
            result = Sequence.EMPTY_SEQUENCE;
          else {
            NodeValue geometryNode = (NodeValue) args[0].itemAt(0);
            //Try to get the geometry from the index
            if (geometryNode.getImplementationType() == NodeValue.PERSISTENT_NODE) {
              targetSRS = indexWorker.getGeometricPropertyForNode(context.getBroker(), (NodeProxy)geometryNode, "SRS_NAME").getStringValue();
              geometry = indexWorker.getGeometryForNode(context.getBroker(), (NodeProxy)geometryNode, false);                       
              hasUsedIndex = true;
            }
            //Otherwise, build it
            if (geometry == null) {
              targetSRS = ((Element)geometryNode.getNode()).getAttribute("srsName").trim();
              geometry = indexWorker.streamNodeToGeometry(context, geometryNode);                       
            }
            if (geometry == null) 
              throw new XPathException("Unable to get a geometry from the node");
              
            geometry = geometry.getEnvelope();
          }
        } else if (isCalledAs("convexHull")) {
          if (args[0].isEmpty())
            result = Sequence.EMPTY_SEQUENCE;
          else {
            NodeValue geometryNode = (NodeValue) args[0].itemAt(0);
            //Try to get the geometry from the index
            if (geometryNode.getImplementationType() == NodeValue.PERSISTENT_NODE) {
              targetSRS = indexWorker.getGeometricPropertyForNode(context.getBroker(), (NodeProxy)geometryNode, "SRS_NAME").getStringValue();
              geometry = indexWorker.getGeometryForNode(context.getBroker(), (NodeProxy)geometryNode, false);                       
              hasUsedIndex = true;
            }
            //Otherwise, build it
            if (geometry == null) {
              targetSRS = ((Element)geometryNode.getNode()).getAttribute("srsName").trim();
              geometry = indexWorker.streamNodeToGeometry(context, geometryNode);
            }
            if (geometry == null) 
              throw new XPathException("Unable to get a geometry from the node");
              
            geometry = geometry.convexHull();
          }
        } else if (isCalledAs("boundary")) {
          if (args[0].isEmpty())
            result = Sequence.EMPTY_SEQUENCE;
          else {
            NodeValue geometryNode = (NodeValue) args[0].itemAt(0);
            //Try to get the geometry from the index
            if (geometryNode.getImplementationType() == NodeValue.PERSISTENT_NODE) {
              targetSRS = indexWorker.getGeometricPropertyForNode(context.getBroker(), (NodeProxy)geometryNode, "SRS_NAME").getStringValue();
              geometry = indexWorker.getGeometryForNode(context.getBroker(), (NodeProxy)geometryNode, false);                       
              hasUsedIndex = true;
            }
            //Otherwise, build it
            if (geometry == null) {
              targetSRS = ((Element)geometryNode.getNode()).getAttribute("srsName").trim();
              geometry = indexWorker.streamNodeToGeometry(context, geometryNode);
            }
            if (geometry == null) 
              throw new XPathException("Unable to get a geometry from the node");
              
            geometry = geometry.getBoundary();                  
          }
        } else {
          Geometry geometry1 = null;
          Geometry geometry2 = null;
          if (args[0].isEmpty() && args[1].isEmpty())
            result = Sequence.EMPTY_SEQUENCE;
          else if (!args[0].isEmpty() && args[1].isEmpty())
            result = args[0].itemAt(0).toSequence();
          else if (args[0].isEmpty() && !args[1].isEmpty())
            result = args[1].itemAt(0).toSequence();
          else {
            NodeValue geometryNode1 = (NodeValue) args[0].itemAt(0);
            NodeValue geometryNode2 = (NodeValue) args[1].itemAt(0);
            String srsName1 = null;
            String srsName2 = null;
            //Try to get the geometries from the index
            if (geometryNode1.getImplementationType() == NodeValue.PERSISTENT_NODE) {
              srsName1 = indexWorker.getGeometricPropertyForNode(context.getBroker(), (NodeProxy)geometryNode1, "SRS_NAME").getStringValue();
              geometry1 = indexWorker.getGeometryForNode(context.getBroker(), (NodeProxy)geometryNode1, false);                     
              hasUsedIndex = true;
            }
            if (geometryNode2.getImplementationType() == NodeValue.PERSISTENT_NODE) {
              srsName2 = indexWorker.getGeometricPropertyForNode(context.getBroker(), (NodeProxy)geometryNode2, "SRS_NAME").getStringValue();
              geometry2 = indexWorker.getGeometryForNode(context.getBroker(), (NodeProxy)geometryNode2, false);                     
              hasUsedIndex = true;
            }
            //Otherwise build them
            if (geometry1 == null) {
              srsName1 = ((Element)geometryNode1.getNode()).getAttribute("srsName").trim();
              geometry1 = indexWorker.streamNodeToGeometry(context, geometryNode1);
            }
            if (geometry2 == null) {
              srsName2 = ((Element)geometryNode2.getNode()).getAttribute("srsName").trim();
              geometry2 = indexWorker.streamNodeToGeometry(context, geometryNode2);                 
            }
          
            if (geometry1 == null) 
              throw new XPathException("Unable to get a geometry from the first node");
            if (geometry2 == null) 
              throw new XPathException("Unable to get a geometry from the second node");                    
              
            //Transform the second geometry in the SRS of the first one if necessary
            if (!srsName1.equalsIgnoreCase(srsName2)) {
              geometry2 = indexWorker.transformGeometry(geometry2, srsName1, srsName2);         
            }               
            
            if (isCalledAs("intersection")) {
              geometry = geometry1.intersection(geometry2);
            } else if (isCalledAs("union")) {
              geometry = geometry1.union(geometry2);
            } else if (isCalledAs("difference")) {  
              geometry = geometry1.difference(geometry2);
            } else if (isCalledAs("symetricDifference")) {
              geometry = geometry1.symDifference(geometry2);
            }   
          
            targetSRS = srsName1;
          }
        }
          
        if (result == null) {           
          String gmlPrefix = context.getPrefixForURI(AbstractGMLJDBCIndexWorker.GML_NS);
          if (gmlPrefix == null) 
            throw new XPathException("'" + AbstractGMLJDBCIndexWorker.GML_NS + "' namespace is not defined");   
            
          context.pushDocumentContext();
          try {
            MemTreeBuilder builder = context.getDocumentBuilder();
            DocumentBuilderReceiver receiver = new DocumentBuilderReceiver(builder);
            result = (NodeValue)indexWorker.streamGeometryToElement(geometry, targetSRS, receiver);
          } finally {
            context.popDocumentContext();
          }
        }
        } catch (SpatialIndexException e) {
          throw new XPathException(e);
            }        
        return result;
          }
          

It looks more complicated because of the multiple possible argument counts. However, the pinciple remains the same: early result when empty sequences are involved, fetching of the `Geometry`ies (and of its/their SRS) from the DB, streaming if nothing can be fetched, then geometric computations after a transformation of the second `Geometry` if relevant.

The final process streams the resulting `Geometry` as the result, in the SRS specified by the relevant argument or in the SRS of the first `Geometry`, depending on the function's name.

### Playing with the spatial index

Now that we have described the spatial index, it is time to play with it. Only a few of its features will be demonstrated, but we will explain again what happens under the hood.

The first step is to make sure to have a recent enough release version of eXist : 1.2 of later.

Then, you have to prepare eXist to build the spatial index library. To do that, go into the `${EXIST_HOME}/extensions/indexes` directory and, if necessary, copy `build.properties` to a new file, `local.properties`.

Open this file and check that `include.index.spatial` is set to `true`.

Invoke `build.bat clean` or `build.sh clean`, depending on your platform, from a command line. This will generate `${EXIST_HOME}/extensions/indexes/build.xml`, which is needed by the modularized indexes infrastructure.

Invoke `build.bat extension-indexes` or `build.sh extension-indexes`, depending on your platform, from a command line.

If necessary, the required external (large) libraries will be downloaded from the WWW into the `${EXIST_HOME}/extensions/indexes/spatial/lib` directory. Most of them have a `gt2-*.jar` name. Make sure to make them available in your application's classpath !

> **Note**
>
> If you are behind a proxy, do not forget to set its settings in `${EXIST_HOME}/build.properties`.

A file named `exist-spatial-module.jar` should be generated into the `${EXIST_HOME}/lib/extensions` directory.

Enable the spatial index and the spatial module in `${EXIST_HOME}/conf.xml` if it is not already done.

the spatial index:

                 
          <modules>
            <module id="ngram-index" class="org.exist.indexing.ngram.NGramIndex"
             file="ngram.dbx" n="3"/>            
            <module id="spatial-index" class="org.exist.indexing.spatial.GMLHSQLIndex"
             connectionTimeout="10000" flushAfter="300" />
          </modules> 
          

and the spatial module:

                 
          <xquery enable-java-binding="no" enable-query-rewriting="no"  backwardCompatible="no">
            <builtin-modules>
              ...
          
              <module class="org.exist.xquery.modules.spatial.SpatialModule"
               uri="http://exist-db.org/xquery/spatial" />
          
              ...
          
              <!-- Optional Modules -->
          
              ...

            </builtin-modules>
          </xquery>             
          

This concludes the prerequisites for running the test.

Our demonstration file is taken from the [Ordnance Survey of Great-Britain's WWW site](http://www.ordnancesurvey.co.uk/oswebsite/) which offers [sample data]( http://www.ordnancesurvey.co.uk/oswebsite/products/try-now/sample-data.html).

The chosen topography layer is of Port-Talbot, which is available as [2182-SS7886-2c1.gz](http://www.ordnancesurvey.co.uk/products/osmastermap/layers/topography/sampledata/2182-SS7886-2c1.gz). Download this file, gunzip it, and give to the resulting file a `.gml` extension (`port-talbot.gml`) this will allow eXist to reckognize it as an XML file.

> **Note**
>
> If you have previously executed `build test`, the file should have been downloaded and gunzipped for you in `${EXIST_HOME}/extensions/indexes/spatial/test/resources`.

Since this file refers to an OSGB-hosted schema, we will need to bypass validation in `${EXIST_HOME}/conf.xml`.

Make sure the mode value is set like this:

         
          <validation mode="no">
          

We are now ready to start the demonstration and we will use the interactive client for that. Run either `${EXIST_HOME}/bin/client.bat` or `${EXIST_HOME}/bin/client.sh` from the command line (please read elsewhere if you do not know how to start it).

Let's start by creating a collection named `spatial` in the `/db` collection. The menus might be localised, but in english it is `File/Create a collection...`.

Then, we will configure this collection by creating a configuration collection.

Let's navigate to `/db/system/config`

If required, let's create a general configuration collection : `File/Create a collection...` name it `db` and get into it.

Then let's create a configuration collection for `/db/spatial`: `File/Create a collection...` name it `spatial` and get into it.

We are now in `/db/system/config/db/spatial`.

Let's now create a configuration file for this collection: `File/Create an empty document...` name it `collection.xconf`.

Double-click on this document and let's replace its auto-generated content :

          <template/>
          

with this one:

          <collection xmlns="http://exist-db.org/collection-config/1.0">
            <index>
              <gml flushAfter="200"/>
            </index>
          </collection>
          

> **Note**
>
> Do not forget to save the document before closing the window.

The `/db/system/config/db/spatial` collection is now configured to index GML geometries when they are uploaded. The in-memory index entries will be flushed to the HSQLDB every 200 geometries and will wait at most 100 seconds, the default value, to establish a connection to the HSQL db.

Let's navigate to `/db/spatial`.

Let's upload `port-talbot.gml`: File/Upload files/directories...

On my computer, the operation on this 23.6 Mb file is performed in about 100 seconds, including some default fulltext indexing. Let's close the upload window and quit the interactive client.

Let's look our our GML file looks like on GML Viewer, a free viewer provided by [Snowflake software](http://www.snowflakesoftware.co.uk/products/gmlviewer/index.htm) :

If you want to have a look at the spatial index HSQLDB, which, if you are using the default data-dir, is in `${EXIST_HOME}/webapp/WEB-INF/data/spatial_index.*` there is a dedicated script file in `${EXIST_HOME}/extensions/indexes/spatial/`. to launch HSQL's GUI client: Use either `hsql.bat` or `hsql.sh [data-dir]` (you only need to supply data-dir if it is not the default one).

If the SQL command `SELECT * FROM SPATIAL_INDEX_V1;` is executed, the result window shows that 21961 geometries have been indexed.

Let's get back to the interactive client and open the query window (the one we get when clicking on the binocular button in the toolbar).

This query:

                 
          declare namespace gml = "http://www.opengis.net/gml";
          spatial:transform(
            <gml:Polygon srsName="osgb:BNG" xmlns:gml='http://www.opengis.net/gml'>
            <gml:outerBoundaryIs><gml:LinearRing><gml:coordinates>
              278200,187600 278400,187600 278400,188000 278200,188000 278200,187600
             </gml:coordinates></gml:LinearRing></gml:outerBoundaryIs>
            </gml:Polygon>, 
            "epsg:4326")    
          

... is processed in a little bit less than 2 seconds. That could seem high, but there is a cost for the Geotools transformation factories initialization. Subsequent requests will be much faster, although there will always be a small cost for the streaming of the in-memory node to a `Geometry` object.

The result is:

                 
          <gml:Polygon xmlns:gml="http://www.opengis.net/gml">
            <gml:outerBoundaryIs>
              <gml:LinearRing>
                <gml:coordinates decimal="." cs="," ts=" ">-3.7578,51.5743 -3.7579,51.5779 -3.755,51.5779 -3.7549,51.5743 -3.7578,51.5743
            </gml:coordinates>
          </gml:LinearRing>
        </gml:outerBoundaryIs>
          </gml:Polygon>
          

> **Note**
>
> Due to the current Geotools limitations, there is no srsName attribute on gml:Polygon ! See above.

... but people might find more convenient to perform this query :

          declare namespace gml = "http://www.opengis.net/gml";
          spatial:getEPSG4326WKT(
            <gml:Polygon srsName="osgb:BNG" xmlns:gml='http://www.opengis.net/gml'>
              <gml:outerBoundaryIs><gml:LinearRing>
            <gml:coordinates>
              278200,187600 278400,187600 278400,188000 278200,188000 278200,187600
            </gml:coordinates>
          </gml:LinearRing>
        </gml:outerBoundaryIs>
          </gml:Polygon>)   
          

... which returns:

                 
          POLYGON ((-3.7577853800140995 51.57430250509819, -3.7579241102503356 
          51.57789774692169, -3.7550389942943365 51.57794093512567, -3.754900491457913 51.57434568777196, 
          -3.7577853800140995 51.57430250509819)
          

So, 3 degrees West, 51 deegrees North... we must be indeed northern of Brittany, i.e. in south-western Great-Britain.

Let's see what our polygon looks like:

Now, we continue doing something more practical:

                 
          declare namespace gml = "http://www.opengis.net/gml";
          spatial:intersects(//gml:Polygon,
            <gml:Polygon srsName="osgb:BNG" xmlns:gml='http://www.opengis.net/gml'>
              <gml:outerBoundaryIs>
            <gml:LinearRing>
              <gml:coordinates>
                278200,187600 278400,187600 278400,188000 278200,188000 278200,187600
              </gml:coordinates>
            </gml:LinearRing>
         </gml:outerBoundaryIs>
          </gml:Polygon>
          ) 
          

This query returns 756 gml:Polygons in about 15 seconds. A subsequent call returns in just about 450 ms, not having the cost for initializations (in particular the first connection to the HSQLDB). A slighly modified query, in order to show the performance without utilising eXist's performant cache:

          declare namespace gml = "http://www.opengis.net/gml";
          spatial:intersects(//gml:Polygon,
            <gml:Polygon srsName="osgb:BNG" xmlns:gml='http://www.opengis.net/gml'>
              <gml:outerBoundaryIs>
            <gml:LinearRing>
              <gml:coordinates>
                278201,187600 278401,187600 278401,188000 278201,188000 278201,187600
              </gml:coordinates>
            </gml:LinearRing>
          </gml:outerBoundaryIs>
            </gml:Polygon>
          )
          

... retuns 755 gml:Polygon (one less) in just about 470 ms.

The result of our first intersection query looks like this:

Let's try another type of spatial query:

          declare namespace gml = "http://www.opengis.net/gml";
          spatial:within(//gml:Polygon,
            <gml:Polygon srsName="osgb:BNG" xmlns:gml='http://www.opengis.net/gml'>
              <gml:outerBoundaryIs>
            <gml:LinearRing>
              <gml:coordinates>
                278200,187600 278400,187600 278400,188000 278200,188000 278200,187600
              </gml:coordinates>
            </gml:LinearRing>
          </gml:outerBoundaryIs>
            </gml:Polygon>
          ) 
          

It returns 598 gml:Polygons in just a little bit more than 400 ms. Here is what they look like:

The last query of this session is just to demonstrate some interesting capabilities of the spatial functions:

          declare namespace gml = "http://www.opengis.net/gml";
          spatial:buffer(
            <gml:Polygon srsName="osgb:BNG" xmlns:gml='http://www.opengis.net/gml'>
              <gml:outerBoundaryIs>
            <gml:LinearRing>
              <gml:coordinates>
                278200,187600 278400,187600 278400,188000 278200,188000 278200,187600
              </gml:coordinates>
            </gml:LinearRing>
              </gml:outerBoundaryIs>
           </gml:Polygon>,
           500
          )
          

See the (not so) rounded corners of our 500 metres buffer over Port-Talbot :

### Facts and thoughts

As of june 2007, the spatial index is in working condition. It provides an interesting set of functionalities and its performance is satisfactory given the lightweight, non spatially-enabled, database engine that stores the `Geometry` objects and their properties. The main objective was to return within the second; we're there.

Here are still some tentative improvements.

The first improvement is to plug in the getGeometriesForNodes() and getGeometricPropertyForNodes() (in `org.exist.indexing.spatial.AbstractGMLJDBCIndexWorker`) to allow sequence/set optimization.

Indeed, a query like this one on our test file :

    declare namespace gml = "http://www.opengis.net/gml";
    for $pol in //gml:Polygon
    return spatial:getArea($pol)
        

... returns 5339 items through as many calls to the DB in... 51 seconds on an initialized index ! Intercepting the `SINGLE_STEP_EXECUTION` flag when the expression is analyzed would allow to call the 2 above methods rather than their "individual" counterparts, namely getGeometryForNode() and getGeometricPropertyForNode(). The expected performance improvement would be interesting.

A second improvement could be to refine the queries on the HSQLDB. Currently, search() (in `org.exist.indexing.spatial.GMLHSQLIndexWorker`) filters the records on the BBox of the searched `Geometry`. It would also be nice to refine the query on the context nodes and, in particular, on their involved collections and/or documents. The like applies for the HSQL implementation of getGeometryForNode() and getGeometricPropertyForNode() too.

However, we have to be aware that writing such a SQL statement and passing it to the DB server might become counter-productive. The idea is then to define some (configurable) threshold values that would refine the query on the documents if there are fewer than, say, 10 documents in the context nodeset, and if there are more than 10 documents in it, but less than, say, 15 collections, refine the query on the collection.

It would be quite easy to determine those threshold values above which writing a long SQL statement and passing it to the DB server takes more time than filtering the fectched data.

We might also consider the field in which the document's URI is stored (`DOCUMENT_URI`) and possibly split it into two fields, one for the collection and the second one for the document. Of course, having indexed integer values here would probably be interesting.

Having some better algorithms to prefilter the `Geometry`ies could probably help as well and, more generally, everything a DB server could bring (caching for instance) should be considered.

An other improvement would be to introduce some error margins for `Geometry`ies computations or BBox ones. The [Java Topology Suite](http://www.vividsolutions.com/jts/jtshome.htm), widely used by Geotools, has all the necessary material for this.

Another interesting improvement would be to compute and return simplified `Geometry`ies depending of a "hint". Applications might want to return simplified polygons and even points at wider scales. Depending on the hint's value, passed in the function's parameters, the index could use the right DB fields in order to work on *precomputed* simpler (or, more generally, different) entries.

This is how a hint configuration could look like :

      <gml flushAfter="200">
        <!-- divide the number of vertices by 2 -->
        <hint value="simplify1" method="simplify" parameter="2"/>
        <!-- divide the number of vertices by 4 -->
        <hint value="simplify2" method="simplify" parameter="4"/>
        <!-- reduce to a point -->
        <hint value="simplify3" method="point"/>  
      </gml>
        

We should also discuss with the other developers about the opportunity to have a `org.exist.indexing.Index` interface in the modularized indexes hierarchy. The abstract class `org.exist.indexing.AbstractIndex` provides some nice general-purpose methods and allows *static* members that are nearly mandatory (like `ID`). The like for `org.exist.indexing.StreamListener` versus `org.exist.indexing.AbstractStreamListener`.

More tests should also be driven. The spatial index has only be tested on one file until now although this file is sizeable. It might be interesting to see how it behaves with unusual geometries like rectangles, multi-geometries and collections. It might also be interesting to know more about the error margin when geometries in different SRSes are involved. The accuracy of the referencing libraries available in the CLASSPATH would play an important role here.

As always, the code could be written in a more efficient way. There are probably too many

        if (...) ... else if(...) ... else ...
        

constructs in the code for instance. Also, we will have to follow Geotools progress to get rid of some of the more or less elegant workarounds we've had to implement.
