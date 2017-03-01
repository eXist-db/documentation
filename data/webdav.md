# WebDAV

## Introducing WebDAV

eXist-db ships with a [WebDAV](http://en.wikipedia.org/wiki/WebDAV) interface. WebDAV makes it possible to manage database collections and documents just like directories and files in a file system. You can copy, move, delete, view or edit files with any application supporting the WebDAV protocol, including Windows Explorer, Mac OS X Finder, [cadaver](http://www.webdav.org/cadaver), [KDE Konqueror](http://www.konqueror.org/), [oXygen XML Editor](http://www.oxygenxml.com/), [XML Spy](http://www.altova.com/), [LibreOffice](http://www.libreoffice.org/) and many others (see "Compatibility" below).

While eXist-db has had WebDAV support since version 1.0b2, the new WebDAV implementation since version 1.4.1 brings improved WebDAV compatibility, thanks to its use of the excellent open-source [Milton](http://milton.io/) WebDAV API for Java.

In the default configuration the WebDAV server can be accessed via the URLs <http://localhost:8080/exist/webdav/db/> and <https://localhost:8443/exist/webdav/db/> (since eXist-db 2.0).

## Compatibility

The [Milton](http://milton.io) project maintains a detailed WebDAV client [compatibility list](http://milton.io/guide/m18/docs/compat.html) that describes a "Recipe for broad client compatibility." In case of any problems please read this document. However, some preliminary points specific to eXist should be kept in mind:

-   For Windows 7 see notes below and at the hints on the [Milton documentation](http://milton.io/guide/m18/docs/compat.html).

-   eXist's Milton based WebDAV interface does not currently support HTTP Digest Authentication.

-   The size of an XML document is presented as a multiple of 4096 bytes, which is eXist's internal pagesize (see [conf.xml](configuration.md#conf.xml)). The actual size on an XML document stored in the database can not be determined because the size depends on many factors, e.g. the applied serialization parameters.

The Milton-based WebDAV interface has been successfully tested with: Windows Web Folders (Windows XP/7), [AnyClient](http://www.jscape.com/products/file-transfer-clients/anyclient/) (cross-platform), Mac OS X Finder, [Transmit](http://www.panic.com/transmit/) (Mac OS X), [Cyberduck](http://cyberduck.ch/), davfs2 version 1.4.5 (Linux), OxygenXML and LibreOffice.

The following clients are reported to have issues: [GVFS](http://en.wikipedia.org/wiki/GVFS) (Nautilus) and [NetDrive](http://www.netdrive.net/). (Compatibility can change over time)

## Clients

### Windows Web Folders

Out of the box, Windows (XP, 7) has *some* native support for the WebDAV protocol, but there are some well-known issues. Please consult the following articles in case of any problem.

> **Note**
>
> Be aware that there are multiple versions of WebDAV Microsoft libraries (and different flavors of bugs). To avoid some frustration if the steps below don't work for you, [Update Windows XP for Web Folders](http://support.microsoft.com/?kbid=892211), or take more information about [Web Folder Client (MSDAIPP.DLL) Versions and Issues](http://greenbytes.de/tech/webdav/webfolder-client-list.html).

> **Note**
>
> Windows Vista and Windows 7 both restrict access to WebDAV servers that use Basic HTTP authentication on non-SSL connections. This restriction can be solved by changing a registry key. Read more on [MSDN](http://support.microsoft.com/kb/841215) and [greenbytes.de](http://greenbytes.de/tech/webdav/webdav-redirector-list.html). However, SSL connections do bring improved security.

Perform the following steps in Internet Explorer:

-   Select `File -> Open`.

-   Fill in URL like `http://localhost:8080/exist/webdav/db/` or `https://localhost:8443/exist/webdav/db/`.

-   Check "Open as Web Folder".

-   Click OK.

### Mac OS X Finder

The eXist-db database can be accessed easily with the Mac OS X Finder. First select in the Finder "Go" and "Connect to Server..."

Fill in the eXist-db WebDAV URL http://localhost:8080/exist/webdav/db/

Enter a username and password...

And the database is accessible!

> **Note**
>
> In the last few OSX releases Apple repetitively changed their WebDAV implementation significantly, repetitively introducing new bugs and problems. The main issue is that Finder requires exact document sizes reported for PROPFIND where as eXist-db by default reports a guesstimated size as mentioned in the Compatibility chapter
>
> As a workaround, eXist-db detects the OSX finder via the "user-agent" HTTP header and switches for PROPFIND into a kind of OSX compatibility mode where all XML documents in a collection are serialized to determine the exact sizes of these documents. This is a rather expensive and time consuming operation for large documents and for collections with many documents.
>
> Instead it is recommended to use [Transmit](http://www.panic.com/transmit/) or [Cyberduck](http://cyberduck.ch/) instead.
>
> Note that for Mac OS X 10.8 the WebDAV client has become functional (again) in 10.8.2, but still the client does not work perfect, e.g. at bulk operations.

### oXygen XML Editor

-   Select `File -> Open URL`.

-   Fill `User` and `Password`.

-   Enter `Server URL` http://localhost:8080/exist/webdav/db/.

-   Click `Browse`.

More info on the [OxygenXML](http://www.oxygenxml.com/xml_editor/ftp_webdav.html/) product pages.

> **Note**
>
> Note on SSL connections in oXygen: You may encounter an error: "Error: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target."
>
> In order to avoid this error, you'll need to add the Server certificate to your trusted certificates keystore ([more info](http://java.sun.com/j2se/1.5.0/docs/guide/security/jsse/JSSERefGuide.html#CustomizingStores)).

> **Note**
>
> Warning: When saving a document to the WebDAV server via oXygen, remember to double check that the document path in the File URL field at the top of the dialog does really contain the URL to which you want to save the document. It happens very easily that you click on another folder or resource by mistake and thus overwrite the wrong resource.

### KDE Konqueror

Enter an URL like `webdav://localhost:8080/exist/webdav/db`. Use `webdavs://` for WebDAV over SSL.

### LibreOffice

For LibreOffice and OpenOffice.org the recommended way for opening documents that are stored in eXist-db is using the 'native' WebDAV client, as documented in the [LibreOffice Help](http://help.libreoffice.org/Common/Opening_a_Document_Using_WebDAV_over_HTTPS) documentation.

> **Note**
>
> Warning: When using LibreOffice on OSX, do not write documents to a network share that is mounted via Finder as documented earlier, since this could corrupt your database. The problem has been identified but there is no solution yet. Please use the alternative described in this chapter.

The first step is configuring LibreOffice to use the LibreOffice Open/Save dialogs instead of the dialogs that are provided by the operating system: Now it is possible to type an URL in the File-Open dialog. Enter <http://localhost:8080/exist/webdav/db/> and provide your login credentials. Now the dialogbox shows the content of the database:
