# Using oXygen

## Overview

[oXygen XML Editor](http://oxygenxml.com/) is a powerful tool for working with eXist-db. Its eXist-db-specific capabilities include:

-   browsing eXist-db database contents

-   editing database contents (open, save, rename documents; create, rename collections)

-   editing XQuery files and continuously validate them against eXist-db's XQuery engine

-   executing queries and displaying results

This article describes how to configure oXygen to work with eXist-db. While the oXygen documentation describes [oXygen's eXist-db support](http://oxygenxml.com/xml_editor/eXist_support.html), we provide up-to-date information here for the convenience of eXist-db users.

## How to tell oXygen about your eXist-db installation

To tap into eXist-db via oXygen, you must tell oXygen a bit about your eXist-db installation. The steps to do this are admittedly too tedious, but you only need to perform these steps once. First, we need to create an entry for eXist-db in oXygen's list of Data Sources; this involves pointing oXygen to 5 key libraries (.jar files) in our eXist-db directory so that oXygen knows how to connect to our version of eXist-db. Then we need to create an entry in its list of Data Connections; this involves providing oXygen with a URL and account information for your eXist-db instance.

In oXygen, go to Preferences &gt; Data Sources, and you will see a window with two areas: Data Sources (on the top) and Connections (on the bottom).

In the Data Sources pane, select the New button to create a new data source.

A new dialog will appear, with fields for Name, Type, and Driver Files.

In the Name field enter a unique name for this eXist-db data source, e.g., "eXist-db Data Source".

In the Type dropdown menu select "eXist."

Finally, select the Add Files button. Browse to the directory where you installed eXist-db, and select each of the following files so that they appear in the Driver files area:

1.  exist.jar

2.  lib/core/ws-commons-1.0.2.jar

3.  lib/core/xmldb.jar

4.  lib/core/xmlrpc-client-3.1.3.jar

5.  lib/core/xmlrpc-common-3.1.3.jar

Select OK to complete the creation of the new Data Source and return to the Data Sources screen, where will will create a new Data Connection to your eXist-db installation. In the "Connections" area of the screen, select the Add button to creat a new data connection.

A new dialog will appear, with fields for Name, Type, and Driver Files.

In the Name field enter a unique name for your eXist-db server, e.g., "eXist-db on localhost 8080".

In the Data Source drop down menu, select the Data Connection name that you created above.

In the XML DB URI field, enter the URL pointing to your eXist-db's XML-RPC service (e.g., http://localhost:8080/exist/xmlrpc). oXygen v14 and higher allow you to make the connection between oXygen and eXist-db secure and SSL-encrypted; to do so select the checkbox, "Use a Secure HTTPS Connection (SSL)", and use your eXist-db's secure port for the XML DB URI (e.g., https://localhost:8443/exist/xmlrpc).

In the User and Password fields, enter your eXist-db account details (e.g., typically, the "admin" user and associated password that you set up when you installed eXist-db).

In the Collection field, enter "/db".

Select OK to complete the creation of the new Data Connection. Select OK to exit oXygen's Preferences. Congratulations! You have told oXygen everything it needs to know about eXist-db.

## How to browse your database contents

Now that you have created an oXygen Data Source and Connection for eXist-db, you can browse your database contents from within oXygen in two ways:

-   Use the Data Source Explorer, an oXygen pane that lists your Connections including the one you created above. To open the Data Source Explorer, select Window &gt; Show view &gt; Data Source Explorer. Using this, you can browse collections and their contents; you can right click on these items display contextual menus with options to create, rename, or move database contents.

-   Use the File &gt; Open URL to browse and pick documents or files database to open. The first time you connect to your database, you will need to fill in several fields: your eXist-db account credentials and Server URL (e.g., http://localhost:8080/exist/webdav/db/)

## How to validate XQuery files against eXist-db's XQuery engine

By default oXygen uses Saxon to validate XQuery files that you open in oXygen. Saxon is a fine tool for validating XQuery (among its many capabilities), but it lacks knowledge of eXist-db built-in functions and other settings. Thus, if you are ultimately creating XQuery to use in eXist-db, you will find numerous advantages in configuring oXygen to use eXist-db for validation instead of Saxon. The steps to complete this configuration are very easy:

In oXygen, go to Preferences &gt; XQuery. On the dropdown menu labeled, "XQuery Validate with", select the name of the Data Connection that you created above.

Select OK to confirm your new preference.

Now when you are editing an XQuery file in oXygen, the validation information you receive (i.e., when you click on the Validate toolbar button) is supplied from eXist-db.

## How to execute queries and display results

You can execute queries against eXist-db from within oXygen. To do so:

Open an XQuery file that you would like to execute.

Select the Configure Transformation Scenario toolbar button, select the New button, and select "XQuery Transformation" in the dropdown menu.

A new dialog will appear with fields to configure your XQuery transformation settings. Enter a Name for the transformation (e.g., "Transform with eXist-db"). In the "Transformer" dropdown menu, select the name of the Data Connection that you created above.

Select OK to confirm these settings, and then select "Save and Close" to exit the configuration window, or select the Apply Associated button to execute your query.

Henceforth, you can execute any query using this transformation scenario by simply selecting the Apply Transformation Scenario toolbar button
