# Troubleshooting

## Introduction

This document contains hints and tips about troubleshooting problems. It also tells you where to find information (such as version numbers, log information, etc.) that is very helpful to know when you need to reach out to [get help](getting-help.md).

## Normal Start Up

While eXist-db starts up, log output appears in the console. If you started eXist-db via the system tray launcher (default), the console output is captured and can be viewed by selecting the Show Tool Window menu entry in the system tray popup, then select Show console messages. If you launched eXist-db via one of the shell scripts, the output should directly appear in those.

If eXist-db launched properly, you will find output similar to the following (this example output is taken from Mac OS X):

    06 Oct 2012 16:56:32,797 [main] INFO  (JettyStart.java [run]:116) - Configuring eXist from /Applications/eXist/conf.xml 
    06 Oct 2012 16:56:32,798 [main] INFO  (JettyStart.java [run]:117) -  
    06 Oct 2012 16:56:32,798 [main] INFO  (JettyStart.java [run]:118) - Running with Java 1.6.0_35 [Apple Inc. (Java HotSpot(TM) 64-Bit Server VM) in /System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home] 
    06 Oct 2012 16:56:32,798 [main] INFO  (JettyStart.java [run]:123) -  
    06 Oct 2012 16:56:32,824 [main] INFO  (JettyStart.java [run]:127) - [eXist Version : 2.1-dev] 
    06 Oct 2012 16:56:32,824 [main] INFO  (JettyStart.java [run]:129) - [eXist Build : 20121006] 
    06 Oct 2012 16:56:32,825 [main] INFO  (JettyStart.java [run]:131) - [eXist Home : unknown] 
    06 Oct 2012 16:56:32,825 [main] INFO  (JettyStart.java [run]:133) - [SVN Revision : 17031] 
    06 Oct 2012 16:56:32,825 [main] INFO  (JettyStart.java [run]:141) - [Operating System : Mac OS X 10.8.2 x86_64] 
    06 Oct 2012 16:56:32,825 [main] INFO  (JettyStart.java [run]:144) - [jetty.home : /Applications/eXist/tools/jetty] 
    06 Oct 2012 16:56:32,825 [main] INFO  (JettyStart.java [run]:146) - [log4j.configuration : file:/Applications/eXist/log4j.xml] 
    06 Oct 2012 16:56:33,698 [main] INFO  (JettyStart.java [lifeCycleStarting]:387) - Jetty server starting... 
    06 Oct 2012 16:56:33,699 [main] INFO  (Server.java [doStart]:253) - jetty-8.1.3.v20120416 
    Logging already initialized. Skipping...
    06 Oct 2012 16:56:34,572 [main] INFO  (NCSARequestLog.java [doStart]:644) - Opened /Applications/eXist/tools/jetty/logs/2012_10_06.request.log 
    06 Oct 2012 16:56:34,589 [main] INFO  (AbstractConnector.java [doStart]:333) - Started SelectChannelConnector@0.0.0.0:8080 
    06 Oct 2012 16:56:34,690 [main] INFO  (SslContextFactory.java [doStart]:298) - Enabled Protocols [SSLv2Hello, SSLv3, TLSv1] of [SSLv2Hello, SSLv3, TLSv1] 
    06 Oct 2012 16:56:34,691 [main] INFO  (AbstractConnector.java [doStart]:333) - Started SslSelectChannelConnector@0.0.0.0:8443 
    06 Oct 2012 16:56:34,691 [main] INFO  (JettyStart.java [lifeCycleStarted]:393) - Jetty server started. 
    06 Oct 2012 16:56:34,691 [main] INFO  (JettyStart.java [run]:221) - ----------------------------------------------------- 
    06 Oct 2012 16:56:34,691 [main] INFO  (JettyStart.java [run]:222) - Server has started on ports 8080 8443. Configured contexts: 
    06 Oct 2012 16:56:34,692 [main] INFO  (JettyStart.java [run]:229) - '/exist' 
    06 Oct 2012 16:56:34,692 [main] INFO  (JettyStart.java [run]:260) - ----------------------------------------------------- 

When you see the "Server has started" message, and no further errors appear, you know that your eXist-db installation is working normally.

However, if you do not even see this message, you should follow these troubleshooting steps

## Database Refuses to Start

If eXist-db was not shut down properly, it may start a recovery process to redo committed transactions and roll back uncommitted ones. If an inconsistency is found during this process, eXist-db will automatically abort the startup and print out a warning. This emergency stop is done to avoid potential damage and give an administrator a chance to check the db and create a backup. It does not necessarily indicate a real problem. In most cases, the db should be ok and restarting it will be save.

However, we definitely recommend to run a [consistency check](backup.md#consistency-check) in those cases. If inconsistencies are found, make sure you have a backup before continuing. If only one or two resources are affected, it might still be ok to restart, but it's good to have a backup just in case.

## Going Back to an Empty Database

During development and testing you may sometimes wish to go back to a completely empty, fresh database. Here's how to really *remove everything* and reset the db to its initial state:

Make sure eXist-db is no longer running

If you installed the source code (and thus the development tools), call ant as follows:

./build.sh clean-default-data-dir
If you do not have build.sh (or build.bat), you may just manually remove the contents of your data directory. By default, the data directory is in `EXIST_HOME/webapp/WEB-INF/data`

## JAVA\_HOME and EXIST\_HOME Environmental Variables

When using one of the shell or batch scripts, eXist-db can fail to start up properly if either of the two key environmental variables, JAVA\_HOME and EXIST\_HOME, are not set properly. Both variables are used in the `startup.bat` and `startup.sh` scripts and have to be set correctly before the scripts are run (you can also insert the lines required in the beginning of the scripts themselves).

-   JAVA\_HOME should point to the directory where Java—the JRE or JDK—is installed. For instructions about how to set JAVA\_HOME on Windows, follow the instructions in this [guide](http://confluence.atlassian.com/display/DOC/Setting+the+JAVA_HOME+Variable+in+Windows); on Linux, follow this [guide](http://www.cyberciti.biz/faq/linux-unix-set-java_home-path-variable/), and on Mac OS X, follow this [guide](http://www.mehtanirav.com/2008/09/02/setting-java_home-on-mac-os-x-105).

-   EXIST\_HOME should point to the directory that contains the configuration file `conf.xml`, so that the server uses the path `EXIST_HOME/conf.xml`. For example, if the EXIST\_HOME path is `C:\Program
                                Files\eXist`, the server will look for `C:\Program
                                    Files\eXist\conf.xml`. You can set EXIST\_HOME in the same way that you set JAVA\_HOME; thus, on Mac OS X, you would enter "export EXIST\_HOME=/Applications/eXist" in the Terminal.

You should also ensure that you have "write" permissions set for the `data` directory located in `webapp/WEB-INF/`.

## Port Conflicts

eXist-db can fail to start up if another service on your system is using port 8080 or 8443, the default ports that eXist's embedded web server, Jetty, uses. To see whether this is the case, enter <http://localhost:8080/> in your browser. If another service occupies this port, you cannot start up eXist-db unless you shut down the service in question or make eXist-db use another port. To make eXist-db use another port, open the file `/tools/jetty/etc/jetty.xml` inside your eXist-db installation in a text or XML editor and change the value "8080" in

&lt;Set name="port"&gt;&lt;SystemProperty name="jetty.port" default="8080"/&gt;&lt;/Set&gt;
to a port that is not used, e.g. "8899":

&lt;Set name="port"&gt;&lt;SystemProperty name="jetty.port" default="8899"/&gt;&lt;/Set&gt;
eXist-db uses port 8443 for confidential communication. Another service may also be using this port. To make eXist-db use another port, open the file `/tools/jetty/etc/jetty.xml` and change the value "8443" in

&lt;Set name="confidentialPort"&gt;8443&lt;/Set&gt;
and

&lt;Set name="Port"&gt;8443&lt;/Set&gt;
to a port that is not used, e.g. "8444".

If these scripts do not launch eXist-db, you can launch it by changing to the directory where you installed eXist-db and entering the following into the console:

java -Xmx1024M -Djava.endorsed.dirs=lib/endorsed -jar start.jar jetty
If you have problems running the shell/batch scripts, read the section [Running Executable Files](advanced-installation.md#bin-executables).

## Using the Logs

If you experience any problems while using eXist-db, your first step should be to check the log files to get additional information about the source of the problem. eXist-db uses the *log4j-package* to write output logs to files. By default, this output is written to the directory `webapp/WEB-INF/logs`. Or, if you are running eXist as a service, check the directory `tools/yajsw/logs`. The main log files for eXist itself are `exist.log` and `xmldb.log`.

## Out of Memory

Running out of memory typically throws Java into an inconsistent state: some threads may still be alive and continue to run while others have died. It is thus important to avoid memory errors up front by checking the memory consumption of your queries before they go into production. Should you encounter an out of memory error, please make sure to restart eXist and follow the emergency procedure.

### Streaming Large Files

If you have to generate large binaries, e.g. a ZIP or PDF, from within an XQuery, please ensure the content does not need to be kept in memory. There are various XQuery functions which directly stream to the HTTP response.

There's also a known issue with the betterform XForms filter caching every HTTP response. To work around this, your XQuery should be run via an URL which is not processed by the XForms filter: either disable the filter or use /rest or /restxq.

## Killing the Database

If you ever feel you have to kill the database (e.g. because it does not respond - for whatever reason), the recommended procedure is as follows:

Check if a query is running wild and try to kill it. This can be done either through the "Scheduler" plugin in the dashboard, or the "Running Jobs" section in the "Admin Web Client". Try to kill the query there and wait for a minute if the system returns to normal operations:

Attempt to trigger a proper shutdown either via the system tray icon or the dashboard. Wait for at least 3 minutes. Even if eXist-db does not stop completely, it may still be able to complete the shutdown procedure for the core database.

It may now be safe to kill the eXist-db process. Check the logs to see if the database has properly shut down. The last message in the logs would indicate this.

If the logs indicate a proper shutdown: before restarting, remove any `.log` and `.lck` files from the data directory. This will prevent a recovery run, which would certainly take time.

Otherwise:

-   You are sure you have no valuable changes in this db instance, e.g. because it's a development system: follow the step above and remove the `.log` files before restart to reduce startup time.

-   Before restart, archive the contents of the data directory: you may need them if anything goes wrong. Restart the database but be prepared for a recovery run, which may take considerable time (depending on the size of your db).

-   If inconsistencies are detected during the recovery, eXist will switch to read-only mode. In this case, stop it again and run a [consistency check](backup.md#consistency-check), which can also create a low-level backup.

    If the consistency check reports a number of errors, eXist may still be able to run, but there might be errors in the data structures. So please prepare for a complete restore into a clean data directory as soon as you can take the database offline for maintenance.

> **Warning**
>
> Do not repeatedly kill the database. If it does not come up immediately, it may run recovery. This can take some time. Killing eXist during recovery will most likely result in additional damages. Always check the logs and console output to see what eXist is doing before you kill it.
