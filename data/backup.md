# Database Backup and Restore

## Abstract

> This section discusses eXist-db's database backup/restore procedures. eXist-db provides different methods for creating backups, which will be explained below.

## Backup Format

During backup, eXist-db exports the contents of its database (as standard XML files) to a hierarchy of directories on the hard drive. This hierarchy is organized according to the organization of collections in the database.

Other files stored during backup include index configuration files and user settings. Resource and collection metadata is exported to a special XML file, called `__contents__.xml`, which lists information including the resource type, owner, modification date and/or the permissions assigned to a resource. You will find one `__contents__.xml` file in each directory created by the backup. This descriptor file is required to restore the backup.

Since eXist-db uses an open XML format rather than a proprietary format for its database files, users can manually modify files in the backup directories without requiring special software. Any changes made to these files are reflected in the database with a restore or once the data is imported to another database system.

It is even possible to directly edit user data and permissions stored in the file `/db/system/users.xml`. This is particularly useful when making global changes to the user database. For example, to reset the passwords for all your users, you can simply edit the file `users.xml` by removing the `password` attribute, or set it to a default value and restore the document.

> **Note**
>
> When migrating to a new eXist-db version, take care to use a version of the client corresponding to your server version. Usually, the backup process is backwards compatible. However, using a newer client version to create the backup from a server running an older version may sometimes lead to unexpected problems.

> **Important**
>
> Due to limitations of the ZIP format, please make sure the size of your zipped backup does not exceed 4 gigabytes. All backup methods support backups to the file system as an alternative.

## Backup Methods

There are two main methods for creating a backup:

Client-side  
You can use the Java admin client or a small command line utility to create a backup of the data on the server. In this case, the client controls the backup process. The server is not blocked and continues to accept requests from other clients. Other users can modify the db while the backup is running, so logical dependencies between different resources may not be preserved correctly.

Client-side backups are *not safe*. The client uses the XML:DB API to access the db. This means that it cannot backup documents or collections if they are damaged in any way.

Server-side  
Server-side backups are usually run through eXist-db's job scheduler, though they can also be triggered via the web interface. This type of backup extracts the data directly from the low-level database files. It is thus much faster then a client-side backup. It also supports incremental backups.

It is guaranteed that the database is in a consistent state while the backup is running. Possible corruptions in the db will be detected and the backup process will try to work around them. In many cases, damaged resources can at least be partially recovered.

The format of the generated backup archives will be the same for both backup methods. They can all be restored via the standard Java client.

## Server-side Backup

This is now the recommended backup method. To guarantee consistency, server-side backups are always executed as system tasks, which means that the database will be switched to a protected service mode before the backup starts. eXist-db will wait for all pending transactions to complete before it enters protected mode. A database checkpoint will be performed and the backup task is executed. While the system task is running, no new transactions will be allowed. Concurrent requests by other clients will be blocked and added to the internal queue. Once the backup is complete, the database will switch back to normal service and all locks will be released.

You can trigger the backup via the Dashboard:

Clicking the Trigger button will schedule a single backup task. The server will wait for all running transactions to return before it executes the task. You can click on Refresh to update the view, which lists all backup archives currently available within the standard backup directory. Click on the name of an archive to download it.

Beginning with version 1.2.5, eXist-db can also create *incremental backups*. Only resources which were modified since the last backup are archived.

All backups will be stored in ZIP format into a directory `export/` below the main data directory, which means `webapp/WEB-INF/data/export/` by default (unless you configured a different data directory in `conf.xml`).

## Automatic Consistency Check

The system task runs a consistency and sanity check on the database before backing it up. Reports of this check are written into the same directory as the backup archive. The last report can also be viewed via JMX (see below).

The consistency check will first check the collection hierarchy, then scan through the stored node tree of every document in the db, testing node properties like the node's id, child count, attribute count and node relationships. Contrary to normal database operations, the different dbx files are checked independently. This means that even if a collection is no longer readable, the tool will still be able to scan the documents in the damaged collection.

The backup task uses the information provided by the consistency check to work around damages in the db. It tries to export as much data as possible, even if parts of the collection hierarchy are corrupted or documents are damaged:

-   Descendant collections will be exported properly even if their ancestor collection is corrupted

-   Documents which are intact but belong to a destroyed collection will be stored into a special collection `/db/lost_and_found`

-   Damaged documents are detected and are removed from the backup

### Scheduling Backups and Consistency Checks

The core class for the server-side backup as well as consistency checks is called `ConsistencyCheckTask`. It can be registered as a system task with eXist-db's [scheduler](configuration.xml#N104CF). To do this, add the following definition to the scheduler section in `conf.xml`:

    <job type="system" class="org.exist.storage.ConsistencyCheckTask"
        cron-trigger="0 0 0/12 * * ?">
        <!-- the output directory. paths are relative to the data dir -->
        <parameter name="output" value="export"/>
        <parameter name="zip" value="yes"/>
        <parameter name="backup" value="yes"/>
        <parameter name="incremental" value="yes"/>
        <parameter name="incremental-check" value="no"/>
    </job>

This will launch a consistency check and database backup every 12 hours, starting at midnight. The time/frequency of the backup is specified in the `cron-trigger` attribute. The syntax is borrowed from the Unix cron utility, though there are small differences. Please consult the Quartz documentation about [CronTrigger](http://www.opensymphony.com/quartz/wikidocs/TutorialLesson6.html) configuration.

The task accepts the following parameters:

output  
The directory to which the backup is written. Relative paths are interpreted relative to eXist-db's main data directory.

backup  
Create a full database backup in addition to running the system checks. Setting this to "no" will not create a backup - unless errors were detected during the consistency check! If errors are found, the task will always try to generate an emergency backup.

zip  
If set to "yes", the backup will be written into a zip archive. For larger databases, please make sure the generated archive is smaller than 4 gigabytes. Due to limitations of the zip format, archives larger than 4 gigabytes may not be readable. In this case, use a backup to the file system instead.

incremental  
Created backups will be incremental. Only resources which were modified since the last backup will be saved. The first backup will always be a full backup, subsequent backups will be incremental.

Note: you can schedule more than one backup job. For example, an incremental backup could be done multiple times a day while a full backup is created only once during the night

incremental-check  
By default, no consistency check will be run during an incremental backup. For big databases, the consistency check may take too long, so it should be done for full backups only. Set `incremental-check` to "yes" to run a consistency check during incremental backups.

max  
If incremental backups are enabled, create a full backup every `max` backup runs. If you set the parameter to e.g. 2, you will get a full backup after two incremental backups.

### Triggering Backups from XQuery

System jobs can also be triggered from an XQuery using the `system:trigger-system-task` function defined in the "system" module:

``` xquery
let $params :=
 <parameters>
   <param name="output" value="export"/>
    <param name="backup" value="yes"/>
    <param name="incremental" value="yes"/>
 </parameters>
 return
    system:trigger-system-task("org.exist.storage.ConsistencyCheckTask", $params)
```

The function will schedule a backup to be executed as soon as possible.

### Emergency Export Tool

eXist provides a graphical interface to the consistency check and backup utilities which can be used in case of an emergency, in particular if the database does not start up properly anymore. The tool needs direct access to the database files, so any running database instance has to be stopped before launching the GUI.

Use the following command line to start the utility:

java -jar start.jar org.exist.backup.ExportGUI
If you installed the eXist distribution using the installer, a shortcut to this should have been placed into the start menu, so you don't need to type above command.

On a headless system you can use the command-line version instead:

java -jar start.jar org.exist.backup.ExportMain
Call it with parameter `-h` to get a list of possible options.

For every check run, an error report will be written into the directory specified in Output Directory. If you clicked on Check Export, the utility will also export the database into a zip file in the same directory. This backup can be restored via the standard [backup/restore tools](#restore).

### Using JMX to View Check Reports

If Java Management Extensions (JMX) are enabled in the Java VM that is running eXist, you can use a JMX client to see the latest consistency check reports. The screenshot shows jconsole, which is included with the Java 5 and 6 JDKs.

eXist also includes a command-line JMX client. Call it with parameter `-s` to see the latest consistency report:

java -jar start.jar org.exist.management.client.JMXClient -s
This may produce output as shown below:

    Sanity report
    -----------------------------------------------
                    Status: FAIL
          Last check start: Thu May 08 21:40:00 CEST 2008
            Last check end: Thu May 08 21:40:00 CEST 2008
                Check took: 594ms
                Error code: RESOURCE_ACCESS_FAILED
                Description: 32

You can also subscribe to the notifications made available by the SanityReport MBean to be informed of sanity check results. Please consult the [documentation](jmx.md) on how to configure JMX.

## Client-side Backup

You can either use the Java-based Admin Client, or the backup command line utility.

If you are using the Admin Client, do the following:

Select either the Backup Icon (arrow pointed upward) in the toolbar OR Tools » Backup from the menu.

From the Collection drop-down menu, select the collection to backup. To backup the entire database, select `/db`. Otherwise, select the topmost collection that should be stored. Note, however, that user data and permissions will only be exported if you backup the entire database.

In the `Backup-Directory` field, enter the full directory path to the where you want the backup database files to be stored or the path to a zip file into which the backup will be written. In general, if the file name ends with `.zip`, the client will attempt to write to a ZIP. Otherwise, it tries to create the specified directory.

Click `OK`.

If you are using the command-line utility for the backup/restore, do the following:

To launch the utility, do ONE of the following:

-   start either the `bin/backup.sh` (Unix), OR the `bin/backup.bat` (Windows/DOS) script file

-   OR enter on the command-line:

    java -jar start.jar backup -u
    \[admin\_username\]
    -p
    \[admin\_password\]
    -b
    \[collection\_path\]
    -d
    \[target\_path\]
    -ouri=
    \[xml\_uri\]
    To view the all of the available options for this command, use the `-h` parameter.

Use the `-b` parameter to indicate the *collection path*, and the `-d` parameter to indicate the *target directory* on your system. You can also specify the current admin username using the `-u` parameter, and the admin password using the `-p` parameter. For example, to backup the entire database on a Unix system to the target directory `/var/backup/hd060501`, you would enter the following:

bin/backup.sh -u admin -p admin-pass -b /db -d /var/backup/hd060501
By default, the utility connects to the database at the URI: `xmldb:exist://localhost:8080/exist/xmlrpc`. If you want to backup a database at a different location, specify its `XML:DB URI` (excluding any collection path) using the `-ouri` parameter. For example, the following backup on a Unix Tomcat system running on port 80 specifies the database URI `xmldb:exist://192.168.1.2:80/xmlrpc`

bin/backup.sh -u admin -p admin-pass -b /db -d /var/backup/hd060501 -ouri=xmldb:exist://192.168.1.2:80/xmlrpc
> **Note**
>
> Default settings for the user, password or server URIs can also be set via the `backup.properties` file.

## Restoring the Database

### Important Note about the Restore Process

Restoring from a backup (or parts of it) does not mean that the existing data in the current database instance will be deleted entirely. The restore process will upload the collections and documents contained in the backup. Collections and documents which exist in the database but are not part of the backup will not be modified.

This is a feature, not a bug. It allows us to restore selected parts of the database without touching the rest.

If you really need to restore into a fresh, completely clean database, proceed as follows:

Stop the running eXist database instance

Change into directory `EXIST_HOME/webapp/WEB-INF/data` or another directory you specified as data directory in the configuration (conf.xml).

Remove all `.dbx`, `.lck` and `.log` files. This means removing all your old data! eXist will recreate those files upon the next restart.

Start eXist again and launch a restore.

### Restore Using the Java Client

To restore the database files from a backup, you can again use either the Admin Client, or the backup command line utility.

> **Note**
>
> For eXist 1.2.x, the restore tool can not directly read from a zipped backup. You have to extract it before restoring. Version 1.4 can handle the zip.
>
> Also, if you experience any issues with bad characters in collection names, use the standard Java `jar` tool to unpack the zip. Contrary to other zip tools, this utility handles character encodings correctly.

If you are using the Admin Client, do the following:

Select either the Restore Icon (arrow pointed downward) in the toolbar OR Tools » Restore from the menu.

The dialog box shown below will then prompt you to select the backup descriptor `__contents__.xml` from the topmost directory you want restored. To restore the entire database, select the `__contents__.xml` from the `db/` directory.

eXist 1.3 allows to directly select the ZIP archive of a backup.

A second dialog box will then prompt you for an admin password to use for the restore process. This password is required ONLY IF the password of the "admin" user set during the backup differs from the log-in password for the current session. (If you provide an incorrect password, the restore will be aborted.) If the passwords are different, note that restoring the user settings from the backup will cause the current user password to become invalid.

If the restore was accepted, a progress dialog box will display the restored files:

#### Using the Command Line

To restore from a backup using the command-line utility, follow the instructions above for launching `bin/backup.sh` (Unix), OR the `bin/backup.bat` (Windows/DOS) script files. Include the `-r` parameter, and the full path of the `__contents__.xml` file to restore. As with the Admin Client, if the backup uses a different password for the "admin" user than the current session, you must specify the backup password using the `-P`. For Example:

bin/backup.sh -u admin -p admin-pass -P backup-pass -r /var/backup/hd060501/db/\_\_contents\_\_.xml
### Repairing the Package Repository After Restore

After a complete restore, your package repository will probably be out of sync. The dashboard will not show all the packages you had previously installed, even though their data collections have hopefully been restored (into `/db/apps` unless you changed the default repository root).

This happens because the package registry is stored on the file system and is not part of a backup. During a restore, only the contents of your packages are written back into the database.

A manual "repair" step is required to get the package repository into sync again. The repair procedure is implemented as an XQuery module, which you can run via eXide or the Java admin client. The module provides two functions:

repair:clean-all()  
Unlinks all currently installed packages from the package manager without removing deployed data from the db.

repair:repair()  
Scan the app root collection in the db for deployed packages and register each of them with the package repository. This reconstructs the metadata for the package. The data stored in the db will not be modified in any way.

repair:repair ($collection)  
Only try to repair the application whose deployed data is stored in the given collection.

After a complete restore into a clean database, the clean-all and repair functions would typically be combined in the following XQuery:

``` xquery
xquery version "3.0";

import module namespace repair="http://exist-db.org/xquery/repo/repair" 
at "resource:org/exist/xquery/modules/expathrepo/repair.xql";

repair:clean-all(),
repair:repair()
```

## Backing Up Single Apps

Creating a backup of a single expath application or library package is rather straightforward within eXide. Either use:

-   the [synchronize feature](development-starter.xml#synchronize) to write the package contents to a directory on disk, or

-   call Application / Download App to retrieve a `.xar` package which can be deployed into another eXist-db instance

## Standalone Backup/Restore

### Standalone Backup/Restore on Server platforms

The above instructions assume that you have a standard eXist installation directory in place, either from a release package or a full build environment. That is not always the case on remotely deployed server instances that might be running using only an eXist WAR file in an application server (eg. Tomcat).

To support such deployment scenarios, and make it easier to do restores local to the deployed server, there is an ant build target called: backrest

Building the backrest target will create a fully-self contained zip file in the backrest directory that can be copied to a remote server and used to do both restores and backups local to that server.

Just unzip the backrest zip file, preserviding subdirectories, and execute either the backup.bat or backup.sh scripts per the prior instructions and parameter usage.
