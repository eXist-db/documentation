# Java Management Extensions (JMX)

## Intro

eXist-db provides access to various management interfaces via Java Management Extensions (JMX). JMX is a standard mechanism available in Java 5 and above. An agent in the Java virtual machine exposes agent services as so-called MBeans that belong to different components running within the virtual machine. A JMX-compliant management application can then connect to the agent through the MBeans and access the available services in a standardized way. The standard Java installation includes a simple client, JConsole, which will also display the eXist-specific services. However, eXist also provides a command-line client for quick access to server statistics and other information.

Right now, eXist only exposes a limited set of read-only services. Most of them are only useful for debugging. This will certainly change in the future as we add more services. We also plan to provide write access to configuration properties.

## Enabling the JMX agent

To enable the platform server within the host virtual machine, you need to pass a few Java system properties to the `java` executable. The properties are:

-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false
> **Note**
>
> This option makes the server publicly accessible. Please check the Oracle [JMX documentation](http://docs.oracle.com/javase/1.5.0/docs/guide/management/agent.html) for details.

The extension can be activated by passing a command-line parameter to the eXist start scripts (`client.sh`, `startup.sh` etc.)

-j &lt;argument&gt;, --jmx &lt;argument&gt;  
set port number through which the JMX/RMI connections are enabled.

Some examples:

bin/startup.sh -j 1099 bin\\server.bat -jmx 1099
> **Note**
>
> In the Oracle Java SE 6 and 7 platforms, the JMX agent for local monitoring is [enabled](http://java.sun.com/javase/6/docs/technotes/guides/management/agent.html) by default.

## Monitoring and Management

### Use JConsole

Once you restart eXist, you can use a JMX-compliant management console to access the management interfaces. For example, you can call jconsole, which is included with the JDK:

jconsole localhost:1099
Clicking on the <span class="menuchoice"></span> tab should show some eXist-specific MBeans below the standard Java MBeans in the tree component to the left.

### Use JMXClient

eXist includes a simple command-line JMX client which provides a quick access to some important server statistics. The application accepts the following command-line parameters:

java -jar start.jar org.exist.management.client.JMXClient &lt;params&gt;
-a, --address &lt;argument&gt;  
RMI address of the server.

-c, --cache  
displays server statistics on cache and memory usage.

-d, --db  
display general info about the db instance.

-h, --help  
print help on command line options and exit.

-i, --instance &lt;argument&gt;  
the ID of the database instance to connect to

-l, --locks  
lock manager: display locking information on all threads currently waiting for a lock on a resource or collection. Useful to debug deadlocks. During normal operation, the list will usually be empty (means: no blocked threads).

-m, --memory  
display info on free and total memory. Can be combined with other parameters.

-p, --port &lt;argument&gt;  
RMI port of the server

-s, --report  
Retrieves the most recent sanity/consistency check report

-w, --wait &lt;argument&gt;  
while displaying server statistics: keep retrieving statistics, but wait the specified number of seconds between calls.

The following command should print some statistics about cache usage within eXist:

java -jar start.jar org.exist.management.client.JMXClient -c -w 2000
### JMXServlet

eXist also provides a servlet which connects to the JMX interface and returns a status report for the database as XML. By default, the servlet listens on

http://localhost:8080/exist/status
For simplicity, the different JMX objects in eXist are organized into categories. One or more categories can be passed to the servlet in parameter `c`. The following categories are recognized:

memory  
current memory consumption of the Java virtual machine

instances  
general information about the db instance, active db broker objects etc.

disk  
current hard disk usage of the database files

system  
system information: eXist version ...

caches  
statistics on eXist's internal caches

locking  
information on collection and resource locks currently being held by operations

sanity  
feedback from the latest sanity check or ping request (see below)

all  
dumps all known JMX objects in eXist's namespace

For example, to get a report on current memory usage and running instances, use the following URL:

http://localhost:8080/exist/status?c=memory&c=instances
This should return an XML document as follows:

``` xml
<jmx:jmx xmlns:jmx="http://exist-db.org/jmx"> 
    <jmx:MemoryImpl name="java.lang:type=Memory"> 
        <jmx:HeapMemoryUsage> 
            <jmx:committed>128647168</jmx:committed> 
            <jmx:init>134217728</jmx:init> 
            <jmx:max>1908932608</jmx:max> 
            <jmx:used>34854528</jmx:used> 
        </jmx:HeapMemoryUsage> 
        <jmx:NonHeapMemoryUsage> 
            <jmx:committed>42008576</jmx:committed> 
            <jmx:init>24313856</jmx:init> 
            <jmx:max>138412032</jmx:max> 
            <jmx:used>40648936</jmx:used> 
        </jmx:NonHeapMemoryUsage> 
        <jmx:ObjectPendingFinalizationCount>0</jmx:ObjectPendingFinalizationCount> 
        <jmx:Verbose>false</jmx:Verbose> 
    </jmx:MemoryImpl> 
    <jmx:Database name="org.exist.management.exist:type=Database"> 
        <jmx:ReservedMem>671455641</jmx:ReservedMem> 
        <jmx:ActiveBrokers>0</jmx:ActiveBrokers> 
        <jmx:InstanceId>exist</jmx:InstanceId> 
        <jmx:MaxBrokers>2</jmx:MaxBrokers> 
        <jmx:AvailableBrokers>2</jmx:AvailableBrokers> 
        <jmx:ActiveBrokersMap/> 
        <jmx:CacheMem>268435456</jmx:CacheMem>
        <jmx:CollectionCacheMem>25165824</jmx:CollectionCacheMem> 
    </jmx:Database> 
</jmx:jmx>
```

#### Testing responsiveness using "ping"

The servlet also implements a simple "ping" operation. Ping will first try to obtain an internal database broker object. If the db is under very high load or deadlocked, it will run out of broker objects and ping will not be able to obtain one within a certain time. This is thus a good indication that the database has become unresponsive for requests. If a broker object could be obtained, the servlet will run a simple XQuery to test the availability of the XQuery engine.

To run a "ping", call the servlet with parameter `operation=ping`. The operation also accepts an optional timeout parameter, `t=timeout-in-ms`, which defines a timeout in milliseconds. For example, the following URL starts a ping with a timeout of 2 seconds:

http://localhost:8080/exist/status?operation=ping&t=2000
If the ping returns within the specified timeout, the servlet returns the attributes of the SanityReport JMX bean, which will include an element &lt;jmx:Status&gt;PING\_OK&lt;/jmx:Status&gt;:

``` xml
<jmx:jmx xmlns:jmx="http://exist-db.org/jmx"> 
    <jmx:SanityReport name="org.exist.management.exist.tasks:type=SanityReport"> 
        <jmx:Status>PING_OK</jmx:Status> 
        <jmx:LastCheckEnd/> 
        <jmx:LastCheckStart/> 
        <jmx:ActualCheckStart/> 
        <jmx:LastActionInfo>Ping</jmx:LastActionInfo> 
        <jmx:PingTime>39</jmx:PingTime> 
        <jmx:Errors/> 
    </jmx:SanityReport> 
    </jmx:jmx>
```

If the ping takes longer than the timeout, you'll instead find an element &lt;jmx:error&gt; in the returned XML. In this case, additional information on running queries, memory consumption and database locks will be provided:

``` xml
<jmx:jmx xmlns:jmx="http://exist-db.org/jmx"> 
    <jmx:error>no response on ping after 2000ms</jmx:error> 
    <jmx:SanityReport name="org.exist.management.exist.tasks:type=SanityReport"> 
        <jmx:Status>PING_WAIT</jmx:Status> 
        <jmx:LastCheckEnd/> 
        <jmx:LastCheckStart/> 
        <jmx:ActualCheckStart/> 
        <jmx:LastActionInfo>Ping</jmx:LastActionInfo> 
        <jmx:PingTime>-1</jmx:PingTime> 
        <jmx:Errors/> 
    </jmx:SanityReport>
    ...
</jmx:jmx>
```
