# Advanced Installation Methods

## Introduction

The eXist-db [Quick Start](quickstart.md) document contains basic instructions for installing eXist. This article explains more advanced methods of installing and running eXist.

## Headless Installation

The eXist-db installer requires a graphical desktop in order to launch. However, If you wish to install eXist-db on a headless system, use the `-console` parameter when launching the installer from the command line. For example:

java -jar eXist-{version}.jar -console
In console mode, the installer will prompt for several parameters. It first asks for an installation directory. Please don't be confused if the output stops after showing the line "Select target path \[...\]": you are expected to enter a path or confirm the default by pressing Enter. A dump of a sample interaction is shown below:

    Wolfgangs-MacBook-Air:eXist wolf$ java -jar installer/eXist-db-setup-2.0RC2-rev17974.jar -console
    Select target path [/Users/wolf/Source/trunk/eXist] 
    /Applications/eXist/
    press 1 to continue, 2 to quit, 3 to redisplay
    1
    Set Data Directory
    Please select a directory where eXist will keep its data files. On Vista and Windows 7, this should be outside the usual 'Program Files' directory:
    Data dir:  [webapp/WEB-INF/data] 

    press 1 to continue, 2 to quit, 3 to redisplay
    1
    Set Admin Password
    Enter password:  [] 
    xyz
    Enter password:  [xyz] 
    xyz
    ------------------------------------------

    Max memory in mb: [1024] 

    Cache memory in mb: [128] 

    press 1 to continue, 2 to quit, 3 to redisplay
    1
    [ Starting to unpack ]
    [ Processing package: Core (1/13) ]
    [ Processing package: Sources (2/13) ]
    [ Processing package: Apps (3/13) ]
    [ Processing package: bfDemos (4/13) ]
    [ Processing package: bfReferences (5/13) ]
    [ Processing package: dashboard (6/13) ]
    [ Processing package: demo (7/13) ]
    [ Processing package: doc (8/13) ]
    [ Processing package: eXide (9/13) ]
    [ Processing package: fundocs (10/13) ]
    [ Processing package: shared (11/13) ]
    [ Processing package: xsltforms (12/13) ]
    [ Processing package: xsltforms-demo (13/13) ]
    [ Unpacking finished ]
    [ Starting processing ]
    Starting process Setting admin password ... (1/1)
    --- Starting embedded database instance ---
    File lock last access timestamp: 30.12.2012 /Applications/eXist/webapp/WEB-INF/data/dbx_dir.lck
    Found a stale lockfile. Trying to remove it:  /Applications/eXist/webapp/WEB-INF/data/dbx_dir.lck
    File lock last access timestamp: 30.12.2012 /Applications/eXist/webapp/WEB-INF/data/journal.lck
    Found a stale lockfile. Trying to remove it:  /Applications/eXist/webapp/WEB-INF/data/journal.lck
    Dez 30, 2012 10:13:26 PM org.expath.pkg.repo.util.Logger info
    INFO: Create a new repository with storage: File system storage in /Applications/eXist/webapp/WEB-INF/expathrepo
    Setting admin user password...
    --- Initialization complete. Shutdown embedded database instance ---
    [ Console installation done ]

## Running eXist-db as a Service

Instead of manually running the eXist-db server in a shell window, you may prefer to run it as a background service which is automatically launched during system startup. This can be convenient, because eXist-db can continue to run even after users have logged off of the system.

eXist-db comes with pre-configured scripts that use [YAJSW (Yet Another Java Service Wrapper)](http://yajsw.sorceforge.net/) to handle the setup procedure. The required scripts are contained in the directory `tools/yajsw`.

### Windows

On Windows, you can simply choose the option to *Install eXist-db as Service* from the eXist-db menu created in the start menu. You can also call `tools/yajsw/bin/installService.bat` instead. This will install eXist-db and Jetty as a Windows service.

> **Note**
>
> Installing eXist-db as a service on Windows Vista requires full administrator rights. Right click on the start menu item and select "Run as administrator". You may need to do this even if you are already logged in as an administrator.

After executing the installService.bat script, you should find eXist-db listed in the list of services currently registered with Windows:

Once the service is registered, you can launch it via the service manager, as shown in the screenshot, or from the command line:

tools\\yaysw\\bin\\startService.bat
### Unix

For Unix based systems (Linux, Mac OS X) the start/shutdown scripts can be found in `tools/yajsw/bin/`.

The easiest way to get eXist-db started during initialization of the system is to run the following command: tools/yajsw/bin/installDaemon.sh This works for Mac OS X and many Linux distributions.

Please note it might be required to set some variables for the specific system, e.g. "wrapper.app.account" (to have eXist-db started as a specific user) and "wrapper.plist.template" for launchd. Details can be found on the YAJSW website: [YAJSW Configuration Options](http://yajsw.sourceforge.net/YAJSW%20Configuration%20Parameters.html).

If your system supports systemd you can run the service wrapper as a non-privileged user. You will be notified on choosing systemd non-privileged when running the service wrapper installer: tools/yajsw/bin/installDaemon.sh You will also also be notified to remove it if you run: tools/yajsw/bin/uninstallDaemon.sh

### Other platforms

Out of the box the by eXist-db provided 'wrapper' supports the following mainstream platforms:

-   Windows x86 (32bit/64bit)

-   Linux x86 (32bit/64bit) & IA (64bit)

-   Mac OS X x86 (32bit/64bit)

-   Solaris x86 (32bit/64bit) & SPARC (32bit/64bit)

Support for additional platforms can be bootstrapped by looking at templates in: tools/yajsw/templates/

## About the Scripts in the bin Directory

Included in the distribution are a number of useful `.sh` (Unix Shell) and `.bat` (DOS batch) programs located in the `bin` directory. Whether you have installed the source distribution or used the installer, you can find this directory in the root directory of the installation.

If you find that the programs do not launch, you can also manually launch these files on the command-line, and specify which application you would like to start.

To manually launch these scripts:

startup.sh (Unix) / startup.bat (Windows)  
Enter on the command-line:

java -jar start.jar jetty

Description: Starts the included Jetty web server at port 8080. eXist is installed as a web application, located at <http://localhost:8080/exist/>.

shutdown.sh (Unix) / shutdown.bat (Windows)  
Enter on the command-line:

java -jar start.jar shutdown -p youradminpassword

Description: Closes the running instance of eXist. If eXist has been started with `startup.sh`, calling `shutdown.sh` will also stop the Jetty web server. Otherwise, only the database is stopped by this call, since eXist has no control over the environment in which it is running. You should *always* call `shutdown` before killing the server process.

server.sh (Unix) / server.bat (Windows)  
Enter on the command-line:

java -jar start.jar standalone

Description: Launches eXist as a stand-alone server process. In this setup, eXist is only accessible through the XMLRPC and the simple, built-in HTTP interface.

client.sh (Unix) / client.bat (Windows)  
Enter on the command-line:

java -jar start.jar client

Description: Launches the Java Administration Client - a graphical database interface. By default, this application is also launched if no application is selected on the command-line:

java -jar start.jar
