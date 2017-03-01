# Getting Data into eXist-db

## Introduction

There are several ways to upload/store/get data into eXist-db. These include:

-   Dashboard

-   eXide

-   A WebDAV client

-   The Java Admin Client

-   Using XQuery to load files via HTTP or from disk

-   Using Ant

## Uploading files with Dashboard

[Dashboard](dashboard.md)'s Collections pane lets you upload files from your filesystem into the database. You can upload one or multiple files at a time. To initiate an upload, open Dashboard, click on the Collections pane. If you are not logged in, Dashboard will prompt you to log in first. A dialog will appear showing you the database collection hierarchy. Select the target collection for your files in the left pane. (If you need to create a new collection for your files first, do so by selecting the New Collection button; it looks like a manila folder with a green plus.) Then click on the Upload button (it looks like a gray cylinder with a green plus). When the Upload Files dialog appears, click on the Click to select file to upload button, then browse to select a file from your disk. Once you have selected your file (or files), click on the Select button to begin the upload. Once all files haven been uploaded and stored, the Upload Files dialog will close automatically.

## Uploading files with eXide

Among eXide's many functions is the ability to upload files from your filesystem into the database. You can upload one or multiple files at a time. To initiate an upload, open eXide and go to File &gt; Manage. If you are not logged in, eXide will prompt you to log in first. Once you see the DB Manager dialog, select the target collection for your files in the left pane. Then click on the Upload button (it looks like a gray cylinder with a green plus). An Upload Files button appears; you can drop files onto it, or click on it below to select files from your disk. Maximum file size is 100MB. Click on the Done button to dismiss the Upload Files dialog, and then select the Close button to dismiss the DB Manager dialog.

Compared to Dashboard, eXide's upload facility is more advanced, since it lets you drag and drop files into the upload dialog, rather than requiring you to browse your file system for each file.

## Uploading files with a WebDAV client

A WebDAV client lets you manage eXist-db database collections and documents very much like directories and files in a file system—often with the full drag-and-drop convenience of a desktop or file transfer client. WebDAV clients, or applications with built-in WebDAV support, include Windows Explorer, Mac OS X Finder, [cadaver](http://www.webdav.org/cadaver), [KDE Konqueror](http://www.konqueror.org/), [oXygen XML Editor](http://www.oxygenxml.com/), [XML Spy](http://www.altova.com/), [LibreOffice](http://www.libreoffice.org/), [Transmit](http://panic.com/transmit/) (for Mac OS X only), and many others.

To connect a WebDAV client to eXist-db, you typically need to provide the URL to eXist's WebDAV interface and an eXist-db username and password. eXist-db's default URL for its WebDAV interface is <http://localhost:8080/exist/webdav/db/>; the URL with HTTPS (SSL) encryption is <https://localhost:8443/exist/webdav/db/>. The client may accept a URL like this, or it may ask you to split up the URL into its component parts; taking http://localhost:8080/exist/webdav/db/ as an example, the server name is localhost, the port is 8080, and the remote path is /exist/webdav/db.

Many eXist-db users find dedicated WebDAV clients such as these to be an excellent way to upload and manage the contents of their database. For more information about using WebDAV connections with eXist-db (including client-specific instructions), see the [WebDAV](webdav.md) documentation.

## Uploading files with the Java Admin Client

The [Java Admin Client](java-admin-client.md), which can be used as a GUI application or via the command line, lets you upload files into the database. To upload files with the GUI application, select File &gt; Store files/directories, or click on the Store icon (which looks like a piece of paper with a plus icon). To upload files with the command line, use the command bin/client.sh -m /db/target-collection -p /filesystem-path, where the -m parameter specifies the target collection and the -p parameter specifies the path on the filesystem to the files that will be uploaded. For more information about these directions, see the [Java Admin Client](java-admin-client.md) documentation.

## Uploading files with XQuery

eXist-db's xmldb:store() function lets you programmatically store data into the database. You can fetch your data using the various HTTP Client modules, such as the EXPath HTTP Client http:request() function or the eXist-db specific httpclient:get() function. You can also fetch your data from the filesystem using the xmldb:store-files-from-pattern() function, which accepts wildcard patterns like \*.xml.

## Uploading files with Ant

Ant is a build tool for automating common tasks, and by importing the eXist-db tasks into your Ant files, you can automate eXist-db actions like importing files from the filesystem into your database. The action for uploading files and storing them into your database is xdb:store. See the [Ant Tasks](ant-tasks.md) documentation for more information.
