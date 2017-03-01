# Log4J Logging Guide

## Introduction

Logging may seem like a rather unimportant part of our application. After all, it consumes resources – taking programmer time, increasing class file size (both on disk and in memory), and consuming CPU cycles to execute – all while doing nothing to provide end-user capability, e.g. configuration and document management. In reality, however, logging is an important part of any substantial body of software and is absolutely critical in enterprise software.

-   R&D often needs some debug or trace output mode to help give greater insights into how mechanisms are operating in various situations.
-   Occurrences of problems or potential problems need to be recorded for examination by site administrators.
-   Given that R&D cannot watch the software from a debugger constantly while it is running in a customer environment, we need a means of capturing what is going on at various levels in the software to facilitate troubleshooting. Lack of appropriate log data can make attempts to identify and address customer problems ineffective or even completely infeasible.
-   Customers want to be able to record and monitor trends in the operation of their software.
-   Appropriate transaction logs are an important tool in performance tuning. Also, customers often want some general idea as to what the software is up to.
-   Customers need to record various data for security reasons, e.g. to produce an access log of who accessed the system.

## What’s been lacking in our logging?

Customers have been complaining about our logging for quite some time – and there are some good reasons for this.

As should be clear by now, there are many different motivations and audiences for logging. Some log data is interesting primarily for analysis of access and/or performance. Other data is critical for examination of system health. Still other data is just informative – and some of this is really only meaningful to developers. To date, XXXXXXXXX has generally made it very hard to filter out the data of interest. XXXXXXXXX also has not consistently and clearly distinguished between important error messages, informational messages of possible customer interest, and debugging messages.

A big issue with the use of XXXXXXXXX logs in troubleshooting has been the fact that XXXXXXXXX has required a restart for changes to log configuration (e.g. enabling a type of logging or changing its verbosity) to take effect. Customers are often extremely reluctant to restart their production servers, so we often get customer rancor, resistance, and delays in obtaining the log data critical to effective troubleshooting.

The overall flexibility of XXXXXXXXX logging has left much to be desired. Certain data always goes to separate files whereas other data cannot be separated into its own files. There is no reliable, cross-platform means for reducing a log file’s size without a restart. The format of the log entries themselves cannot be specified by the administrator. Overall, XXXXXXXXX’s logging does not provide the myriad of features, big and small, that other logging systems provide today.

Finally, XXXXXXXXX’s logging is showing signs of its grass-roots growth. There are many disparate xx.properties which control logging done in a number of different ad hoc fashions. Info\*Engine introduces its own logging controlled in a different fashion and overall behaving differently. It is hard for a site administrator to get a big, useful picture of XXXXXXXXX’s logging.

## What to do about it?

Most classes are using Apache’s log4j (http://logging.apache.org/log4j/). Log4j is the most powerful Java-based logging library available today and is used by most of the application servers on the market.

## What does log4j give us?

Log4j is based on several core concepts:

-   Each log event is issued by a hierarchically named “logger”, e.g. “xx.method.server.httpgw”.
-   These hierarchical names may or may not correspond to Java class names.
-   All log events have an associated severity level (trace, debug, info, warn, error, or fatal).
-   To issue a log event programmers just acquire a logger by name and specify a log message and its severity level (and optionally a Throwable where applicable).
-   Decisions as to whether a given log event is output, how and where it is output, what additional data (e.g. timestamps) are included beyond the log message, etc, are generally not made by the programmer – instead they are controlled by an administrator via a log4j configuration file.

Based on these core concepts, log4j provides a powerful set of functionalities.

-   Many “appender” choice

    Each log event may be output to zero or more “appenders,” which are essentially generalized output pipes. Log4j output can be sent to the System.out/err, files, JDBC, JMS, syslog, the Windows event log, SMTP, TCP/IP sockets, telnet, and more – all at the site administrator’s discretion. File output includes various options for log rolling, e.g. daily creation of new log files, segmenting when a given file size is reached, and externally controlled log rotation. These appenders can be run synchronously to the threads generating log events or as separate asynchronous queues.

-   Flexible “layout” options

    With each appender one can specify a “layout” for formatting the log message. The administrator may choose from HTML, XML, and various plain text formats – including the flexible PatternLayout which allows selection of data to include (e.g. timestamps, originating thread, logger name, etc) and exactly how to include it.

-   Hierarchical logger configuration

    Administrators can easily configure log event cutoff levels and appenders for entire branches of the hierarchical logger tree, i.e. for a whole set of related loggers, at once. For instance, by adding a “console” appender targeting System.out to the root logger, all log4j output will go to System.out. One can similarly configure the overall cutoff level as “error” at the root logger level so that only error and fatal messages are output unless otherwise specified. One could then configure the “xx.method” logger to have an “info” level cutoff and an appender to capture all output to a specified file (in addition to System.out). These “xx.method” settings would then affect all loggers whose names begin with “xx.method.” (e.g. “xx.method.server.httpgw”), in addition to the “xx.method” logger itself.

-   Log viewers

    Various free and commercial products provide specialized viewing capabilities for log4j logs. Apache provides a very useful log4j log viewer, Chainsaw (http://logging.apache.org/log4j/docs/chainsaw.html).

See the log4j website (http://logging.apache.org/log4j/ and in particular http://logging.apache.org/log4j/docs/manual.html) for more information.

It is worth noting that Java 1.4 and higher’s java.util.logging API and concepts are very similar to log4j’s, but log4j is much more powerful in a number of critical areas.

In conjunction with our JMX MBeans for log4j, one can also:

-   Dynamically examine and reconfigure the log4j configuration for the duration of the process via a JMX console,

-   Have all processes using a log4j configuration file periodically check its modification date and automatically re-load it upon any change , and

-   Force an immediate reload from a configuration file via a JMX console.

Overall use of log4j provides an immense leap forward in XXXXXXXXX logging functionality and flexibility. Specifically, by using log4j we can address each of the shortcomings previously noted in our existing logging.

## How can I use log4j in new code?

Using log4j from XXXXXXXXX code is quite easy.

1.  Acquire a logger. import org.apache.log4j.Logger; … private Logger logger = Logger.getLogger("xx.method.server.httpgw");

    -   This is a somewhat time-consuming operation and should be done in constructors of relatively long-lived objects or in static initializers .
    -   Many classes can separately acquire a logger using the same logger name. They will all end up with their own reference to the same shared logger object.

2.  Use the logger: logger.info( "Something I really wanted to say" );

    -   info() is just one of Logger’s methods for issuing log4j log events. It implicitly assigns the event a severity level of “info” and does not specify a Throwable. Logger methods for issuing log events include:
    -   Note that in each case the “message” is an Object, not a String. If (and only if) log4j decides to output the given log event (based on the configuration), it will render this object as a String. By default this is essentially via toString().

It’s as simple as that. You just emit log events with appropriate log levels to appropriately named loggers. The log4j configuration determines which appenders (if any) should output/record the event and how this should be done.

For more information on “Do’s and Don’t” see that section. For more information on how to configure log4j output see the “Configuring log4j?” section.

## How can I convert existing logging code to use log4j?

Conversion of existing logging code to use log4j can be simply viewed as replacing System.out.println() calls, etc, with use of the log4j API. There are, however, a few special considerations worth noting.

### Dealing with Legacy Properties

In the conversion process the behavior of some existing properties will generally be affected.

In cases this may mean simply removing the existing properties. For instance, properties specifying specific output files can generally be removed as customers can now siphon log4j output to specific files at their discretion via log4j’s configuration files.

On the other hand, it may be useful in cases to preserve well known log enabling properties to reduce confusion amongst those used to these properties. In such cases it is suggested that the property be ignored unless it is set to enable the given log – in which case it will ensure the given log4j logger’s log level is verbose enough to cause the existing messages to be output. For instance, one might have something like

``` java
   private static final boolean VERBOSE_SERVER;
   static
   {
     XXProperties properties = XXProperties.getLocalProperties();
     VERBOSE_SERVER = properties.getProperty("xx.method.verboseServer", false);
   }
   …
   if ( VERBOSE_SERVER )
     System.out.println( "some message" );
     
```

in the existing code. The static portions above can be left as is and the remainder changed to:

``` java
   import org.apache.log4j.Level;
   import org.apache.log4j.Logger;

   // place VERBOSE_SERVER declaration and static block from above here
   private static final Logger  serverLogger =
                                     Logger.getLogger( "xx.method.server" );
   static
   {
     if ( VERBOSE_SERVER )
       serverLogger.setLevel( Level.ALL );
   }
   …
   serverLogger.debug( "some message" );
   
```

This example assumes that output from the given log4j logger should be completely enabled, i.e. for all log levels, when the existing property is set. One can also use logic like:

``` java
   if ( VERBOSE_SERVER )
     if ( !serverLogger.isDebugEnabled() )
       serverLogger.setLevel( Level.DEBUG );
       
```

to cause the existing property to enable output from the given log4j logger up through only a certain severity level, debug in this example.

To be clear, this approach to preserving existing “enabling” properties only keeps them working more or less as they were. The intended minimum log verbosity is ensured upon initialization and then cannot be reset via the property without a restart. The ability to change the log-level on the fly or make finer-grained log-level adjustments is still only available through log4j configuration.

When an existing property’s behavior is changed or when log4j configuration is now the more powerful (and thus preferred) approach, this should be noted in the property’s entry in properties.html. Be sure to include the name of new log4j logger in such notes.

### Conditional Computation of Data for Logging

In cases you will find existing code like:

``` java
   if ( VERBOSE_SERVER )  // static final boolean
   {
     // various computations and assignment
   }
   
```

the if block may include System.out.println()’s or the results of the block may be used in later System.out.println()’s.

In either case, the code is intended to avoid the block of computations and assignments unless their results are to be used. This intent can be satisfied by use of one of log4j’s is\*Enabled() methods. For example:

``` java
   if ( serverLogger.isDebugEnabled() )
   {
     // various computations and assignment that will only be used
     // if serverLogger.debug() calls
   }
                
```

The log4j Logger class provides a set of methods for this purpose including:

``` java
   public boolean isTraceEnabled();
   public boolean isDebugEnabled();
   public boolean isInfoEnabled();
   public Boolean isEnabledFor(Level);
                
```

This technique obviously applies to new log4j usage as well but is noted at this point so as to make conversion of existing logging code more straightforward.

## Configuring log4j

In 1.4 the ***log4j.xml*** configuration file control log4j’s behavior.

The full format of this configuration file is described here and a short introduction of the basics is given here. Note this is the simpler, but less powerful, form of log4j configuration file. An XML-based configuration file format also exists and customers will end up supplanting one or more of the properties files above with an XML configuration file if they require some of the most advanced log4j features.

These out-of-the-box configuration should generally be kept fairly simple (see “Do’s and Don’ts” below), so the main use case for development configuration of log4j is to enable a given level of log output from one or more loggers. Without such configuration XXXXXXXXX will output only ERROR and FATAL log events out-of-the-box – except where the configuration has already been extended to output other log events. Therefore you generally must change the configuration to see trace, debug, info, or warn log events in the log4j output.

To turn on a given logging level for all loggers, find the log4j.root property and change the priority value to the desired level. For instance, change

                    
        <root>
            <priority value="debug"/>
            <appender-ref ref="exist.core"/>
        </root>

                

to

                    
        <root>
            <priority value="info"/>
            <appender-ref ref="exist.core"/>
        </root>

                

Of course this will result in a cacophony of log output, so you’ll generally want to adjust the logging level at a more specific level. To do this you can append a line to the properties file of following form:

                    
        <category name="targetedLoggerName" additivity="false">
            <priority value="desiredLogLevel"/>
            <appender-ref ref="exist.xacml"/>
        </category>
     
                

For instance, you would add

                    
        <category name="org.exist.security" additivity="false">
            <priority value="info"/>
            <appender-ref ref="exist.security"/>
        </category>

                

to set the “org.exist.security” logger’s level to “info”. Note that doing so also causes all the default log level of all org.exist.security loggers to be set to “INFO”. For example, the level of the org.exist.security.xacml logger would also be set to INFO unless the level of this logger is otherwise specified.

Changes to log4j configuration files may go unnoticed for as long as a few minutes as the checks for modifications to these files take place on a periodic basis. To force an immediate reload of the log4j configuration file, change the configuration file modification check interval, or make temporary changes to the log4j configuration without changing the configuration files, one must use our JMX MBeans.

To use our log4j JMX MBeans:

1.  Start jconsole.

    jconsole is located in the Java 5 SDK’s bin directory. You can either double-click on it or run it from the command line.

2.  Select the target JVM.

    jconsole will list the Java processes running on your machine under your current user which have been configured to allow local JMX connections.

3.  Navigate to the Logging node in the MBean tree.

    -   Select the MBeans tab.

    -   Expand the XXXXXXXXX folder.

    -   In the servlet engine expand the “WebAppContext” folder and the folder named after your web app.

    -   Select the “Logging” node (which should now be visible).

    -   Note that it may take a short while after initial start up for all of these tree nodes to load into jconsole.

4.  Perform desired operations and/or modifications.

    -   To change the configuration file check interval, change the ConfigurationCheckInterval attribute to the desired number of seconds. \[Note that this change will apply only for the duration of the JVM process unless you select the Loader node and its “save” operation.\]

    -   To force an immediate reload of the configuration file, press the “reconfigure” button on the operations tab.

    -   To examine other aspects of the configuration and make temporary (for the duration of the JVM process) changes to the logging configuration, press the “registerLoggers” button on the operation tab. Expand the “Logging” tree node and examine/operate upon its children.

## Do’s and Don’ts

General

Do carefully select appropriate logger names

Logger names should be somewhat meaningful and should facilitate hierarchical configuration by administrators. They should also be namespaced with “xx” or “com.xxx” so as to avoid collision with logger names from 3rd-party libraries and customizations. For instance, one might (and we do) have “xx.method.server” for general logging related to various low-level aspects of the method server and “xx.method.server.timing” for logging specifically related to the method timing. One can certainly use Java class and package names where these make sense, but an understandable and useful hierarchy is the important thing.

Do document your logger in /XXXXXXXXX/src\_web/loggers.html if appropriate

If your logger is to be sent significant information of potential customer interest, then the logger should be documented (by name) in /XXXXXXXXX/src\_web/loggers.html (which ends up in XXXXXXXXX’s codebase in an installation) unless there are special considerations to the contrary. Special considerations which would cause one not to document the logger include a likelihood that the logger will be removed in the near future or any other scenario wherein we do not want to raise customers’ awareness of a given logger.

Do carefully select appropriate levels for log events One of the big advantages of log4j is that each logging event has an associated level and thus an administrator can easily filter out log messages by level. This advantage is nullified, however, if those outputting log events do not select appropriate log levels when they do so. The following table delineates when to use each level.

| Level | Usage                                                                                                                                                              |
|-------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Trace | Very low-level debugging “execution is here” debugging / troubleshooting types of events.                                                                          |
| Debug | Messages of interest to those debugging or troubleshooting of a greater importance than trace messages; possibly still only meaningful to developers               |
| Info  | General informational messages; provide higher level and/or more important information than debug messages; understandable by and/or of interest to non-developers |
| Warn  | Warnings of potential problems                                                                                                                                     |
| Error | Error conditions                                                                                                                                                   |
| Fatal | Fatal error conditions, i.e. where the product is going to have to shut down, is likely to crash, or something equally severe                                      |
||

Don’t go overboard with the log4j configuration files

Log4j provides a great deal of ease and flexibility in its configuration. Its log viewers also make it easy to merge log data from multiple log4j logs or filter out the data of interest from a general purpose log. Given this it makes little sense to provide a complex log4j configuration file out-of-the-box. The customer can change the configuration to have more or less specific log outputs as dictated by their needs and desires.

Do adjust log levels in log4j configuration files where appropriate

Currently the out-of-the-box global default for XXXXXXXXX is to only output “error” and “fatal” log messages. This is a reasonable default in that it generates fairly quiet logs that only alert administrators to issues. There are, however, some cases where a given log event is best classified as being only informational (and thus is output as level “info”) and yet should be output to logs as an out-of-the-box default behavior. Examples include periodic summaries of requests serviced by the server over the last time interval and periodic process health summaries. In such cases one should add to the out-of-the-box log4j configuration to enable info level debug output for the logger in question.

Don’t include redundant data in log messages

Administrators can easily configure log4j log output to efficiently include:

-   current time

-   thread name

-   logger name

-   log event level

Moreover, log4j includes this information in a standard, structured fashion which is therefore easily interpreted by log viewers like Chainsaw.

Inclusion of any of these pieces of information in the log message itself is therefore redundant and pointless.

Do make use of AttributeListWrapper where appropriate

For some particularly significant logs it is important to give the administrator even more control including:

-   Allowing them to select which of many possible attributes should be included in a given log message

-   Allowing them to specify the order of these attributes

-   Allowing them to specify the formatting of these attribute (e.g. comma delimited, with or without attribute names, etc)

Examples of such cases include request access and periodic statistics logging.

We have a re-usable utility for just this purpose, xx.jmx.core.AttributeListWrapper. See its existing usages for examples of how to use it and the Runtime Management design note for background information.

Don’t be afraid to use log4j in any tier or JVM

log4 currently is not included in the client jar set. The only reason for this is that currently no clients use log4j. We should not waste time and energy trying to avoid log4j logging from the client. If/when we need log4j.jar on the client we should simply include it in the client jar set. Java 5’s Pack200 technology reduces jars to 25% their original size on average, and log4j.jar is not that big to begin with.

Performance

The operation of log4j’s Logger class’s logging methods for issuing log events can be roughly summed up as:

``` java
public void  log( Level level, Object message )
{
  if ( isEnabledFor( level ) )
  {
    String  string = render( messasge );
    for ( Appender appender : myAppenders )
      appender.output( string );
  }
}
```

where:

-   render() is simply a toString() call except when ‘message’ is an instance of a Class for which a specialized render has been registered.

-   trace(), debug(), info(), warn(), error(), etc, simply call log() with the appropriate ‘level’.

Note that log4j documentation claims that isEnabledFor(), and the Logger.is\*Enabled() method in general, are extremely fast (and they have some benchmark data to back this up). Thus log() should take very little time as well unless isEnabledFor() returns ‘true’.

Given this, a few performance do’s and don’t become clear:

Don’t reacquire a logger on each usage

As already noted, the LogR.getLogger() (and underlying Logger.getLogger()) calls are relatively expensive. One should thus acquire these objects once per class or once instance of a class and re-use them in subsequent logging calls against that logger.

Don’t assume a log’s level cannot change

One of the big advantages of log4j is that administrators can easily change the level setting of any logger at any time. One can easily completely break this by following conventions common in existing XXXXXXXXX logging code, e.g.:

``` java
 static boolean  LOG_ENABLED = logger.isInfoEnabled ();
…
public void someMethod()
{
  if ( LOG_ENABLED )
    logger.info( … );
}
```

There is no reason such code should ever occur. Logger’s isEnabledFor() and is\*Enabled() routines are fast enough that we can pay the penalty to call them much more frequently in order to obtain the benefits of dynamically configurable logging levels.

Don’t check whether the log level is enabled before every log call

Do not write code such as:

``` java
if ( logger.isDebugEnabled() )
  logger.debug( "Some constant string" );
  
```

Such code results in essentially no savings when isDebugEnabled() is true but logger being checked twice to determine if it is debug enabled in the case when isDebugEnabled() is true. Besides this it makes the code more verbose and harder to read. In such cases one should simple do:

``` java
logger.debug( "Some constant string" );
            
```

Do avoid doing additional work for logging unless the logger is enabled

If last example instead looked like:

``` java
if ( logger.isDebugEnabled() )
  logger.debug( "Object " + object.getDisplayIdentity() + 
                " is being deleted" );
                
```

Then the isDebugEnabled() check should be performed. In this case two String concatenations and a potentially (somewhat) expensive method call can be saved when the logger is not debug enabled – at a cost of only an extra isDebugEnabled() call when the logger is debug enabled. See the “Conditional Computation of Data for Logging” section above for another example of this pattern.

On the other hand, this technique should not be used when you are all but certain the given logger will be enabled. Usually this applies only to log events being emitted with an “error” or “fatal” level designation. In this case saving time for the few cases in which someone has actually disabled this level of logging is not worth while for the extra time required in the majority of cases.

Another technique to avoid unnecessary work is to leverage the fact that Logger’s take objects, not Strings, as arguments. Thus one might have:

``` java
SomeClass  someObj = new SomeClass(…);
logger.info( someObj );
```

Here one will pay the construction of “someObj” in all cases but will only pay for someObj.toString() when “logger” is enabled for info-level log events. Thus if very little work is done in the constructor and most is done in toString() this avoids doing work except when necessary – which is always a good thing. AttributeListWrapper (see above) is an example of this technique.

Do hoist log level checks outside of very tight loops

For cases where a given log level will usually not be enabled, e.g. for trace and debug log messages, one should avoid repeated checks within a tight loop. As an example:

``` java
{
  final boolean  traceEnabled = logger.isTraceEnabled();
  for ( int ii = 0; ii < n; ++ii )
  {
    // do some very quick stuff
    if ( traceEnabled )
      logger.trace( ... );
    // do a little more very quick stuff
  }
}
```

Trace level logging is rarely enabled and so in this example checking for this case ahead of time can save us from repeatedly verifying this in a tight loop. This does, however, come at the cost of making it impossible to dynamically enable trace logging for this logger in the middle of this loop. Due to this cost this technique should only be used for tight loops where the duration of the execution represented by the loop (and thus the time during which the logging behavior may lag the intended setting) is small.
