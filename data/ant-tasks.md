# Ant Tasks

## Introduction

eXist-db provides a library for the [Ant](http://ant.apache.org) build tool to automate common tasks like backup/restore or importing a bunch of files. To use this library you need at least Ant 1.6. Ant 1.8.2 is included in the eXist-db v2.0 distribution (if you have installed the eXist-db source code).

In your build file, import the eXist-db tasks as follows:

                        <typedef resource="org/exist/ant/antlib.xml" uri="http://exist-db.org/ant">
        <classpath refid="classpath.core"/>
    </typedef>
                    

The classpath has to be defined before as follows

                        <path id="classpath.core">
        <fileset dir="${server.dir}/lib/core">
            <include name="*.jar"/>
        </fileset>
        <pathelement path="${server.dir}/exist.jar"/>
        <pathelement path="${server.dir}/exist-optional.jar"/>
    </path>
                    

> **Note**
>
> For a working example have a look into the file `webapp/xqts/build.xml
>                 `, which is used to prepare the database for running the xquery test suite.

All tasks share the following common attributes:

uri  
An XMLDB URI specifying the database collection.

ssl  
Use SSL encryption when communicating with the database (default: false).

initdb  
Setting this option to "true" will automatically initialize a database instance if the uri points to an embedded database.

user  
The user to connect with (default: guest).

password  
Password for the user (default: guest).

failonerror  
Whether or not a error should stop the build execution

## Storing Documents

The store task uploads and stores the specified documents into the database. Documents are specified through one or more filesets or as single source file. The following attributes are recognized:

                        <xdb:store xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare/plays"
        createcollection="true">
        <fileset dir="samples/shakespeare"> 
            <include name="*.xml"/>
            <include name="*.xsl"/>
        </fileset>
    </xdb:store>
    <xdb:store xmlns:xdb="http://exist-db.org/ant"
      uri="xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare/plays"
      createcollection="true" srcfile="samples/shakespeare/hamlet.xml"/>
                    

createcollection  
If set to "true", non-existing base collections will be automatically created.

createsubcollections  
If set to "true", any non-existing sub-collections will be automatically created.

type  
The type of the resource: either "xml" or "binary". If "binary", documents will be stored as binary resources. If it is unset, the type will be guessed from identified MIME type

defaultmimetype  
The default MIME type to use when the resource MIME type cannot be identified. If it is not set, binary (application/octet-stream) is the default.

forcemimetype  
Use this attribute when you want to force an specific MIME type. You should also set 'type' attribute, because resource kind guessing is disabled in this mode.

mimetypesfile  
The mime-types.xml file used by Ant eXist-db extension to identify the resource kind ("binary" or "xml") and MIME type of the documents to store. If it is not set, it will use a default one which is either at eXist-db HOME installation or bundled inside the Ant eXist-db extension

srcfile  
a single source file to store; use instead of filesets

permissions  
The permissions to be applied to the resource, expressed in a Unix-style form, e.g. 'rwxr-xr-x'; permissions will be applied to the resource/collection after it is created.

## Removing Documents/Collections

The remove task removes a single resource or collection from the collection specified in the uri attribute.

                        <xdb:remove xmlns:xdb="http://exist-db.org/ant"
      uri="xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare/plays" resource="hamlet.xml"/>
                    

                        <xdb:remove xmlns:xdb="http://exist-db.org/ant"
      uri="xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare" collection="plays"/>
                    

collection  
The name of the collection which should be removed.

resource  
The name of the resource which should be removed.

## Creating Empty Collections

The create task creates a single empty collection from the collection specified in the uri attribute.

                        <xdb:create xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare" collection="plays"/>
                    

collection  
The name of the subcollection which should be created.

permissions  
The permissions to be applied to the resource, expressed in a Unix-style form, e.g. 'rwxr-xr-x'; permissions will be applied to the resource/collection after it is created.

## Check Existence of Resource/Collection

The exist task is a condition that checks whether a resource or collection as specified in the uri attribute exists or not. An ant target can be executed conditionally depending on the property set or not set by the condition.

``` xml
<condition property="exists">
    <xdb:exist xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare/plays" resource="hamlet.xml"/>
 </condition>
```

resource  
The name of the resource which should be checked.

## List Resources/Collections

The list task returns a list of all resources and/or conditions in the collection specified in the uri attribute.

                        <xdb:list xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare/plays" resources="true" outputproperty="resources"/>
                    

                        <xdb:list xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare" collections="true" outputproperty="collections"/>
                    

resources  
If "true" lists resources

collections  
If "true" lists collections

separator  
separator character for the returned list, default is ","

outputproperty  
name of a new ant property that will contain the result

## Copy a Resource/Collection

The copy task copies a resource or collection to a new destination.

                        <xdb:copy  xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare/plays" resource="hamlet.xml" destination="sub"/>
                    

                        <xdb:copy  xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare" collection="plays" destination="sub"/>
                    

resource  
The name of the resource which should be copied.

collection  
The name of the collection which should be copied.

destination  
The name of the destination collection to copy to.

name  
The new name of the resource or collection in the destination.

## Move a Resource/Collection

The move task moves a resource or collection to a new destination.

                        <xdb:move xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare/plays" resource="hamlet.xml" destination="sub"/>
                    

                        <xdb:move xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare" collection="plays" destination="sub"/>
                    

resource  
The name of the resource which should be moved.

collection  
The name of the collection which should be moved.

destination  
The name of the destination collection to move to.

name  
The new name of the resource or collection in the destination.

## Process an XPath Expression

The xpath task executes an XPath expression. The output of the script is discarded, except when a destination file or output property is specified.

The XPath may either be specified through the query attribute or within the text content of the element. A optional namespace may be used for the query.

                        <xdb:xpath xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc/db" query="/example-queries/query"/>
                    

The query task accepts the following attributes:

query  
The query to be processed.

resource  
query a resource instead of a collection.

count  
If "true" the number of found results is returned instead of the results itself.

outputproperty  
return the results as a string in a new property. In this case only the text of the result is returned.

destDir  
write the results of the query to a destination file. In this case the whole XML fragments of the result is written to the file. Care should be taken to get a wellformed document (e.g. one root tag).

namespace  
XML namespace to use for the query (optional).

## Process an XQuery Expression

The xquery task executes an XQuery expression. This task is primarily intended for transformations. The output of the script is discarded when no destination file or output property is specified.

The XQuery may either be specified through an URI, the query attribute or within the text content of the element. External variables declared in the XQuery can be set via one or more nested &lt;variable&gt; elements. You can also use the loadfile task to load the query from a file as in the following example:

                        <loadfile property="xquery" srcFile="wzb.xq"/>
    <xdb:xquery  xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc/db" query="${xquery}"
        user="guest" password="guest-passwd">
          <variable name="alpha" value="aaa-alep" />
    </xdb:xquery>

                    

                        <xdb:xquery  xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc/db" 
        queryUri="http://www.example.com/query/xquery-task.xql"
        user="guest" password="guest-passwd">
          <variable name="beta" value="&#x3d0;" />
        </xdb:xquery>
                    

The XQuery task accepts the following attributes in addition to the common ones:

query  
The query to be processed.

queryUri  
The query to be processed specified as a URI.

outputproperty  
return the results as a string in a new property.

destfile  
write the results of the query to a destination file.

queryfile  
read the query from a file.

## Extract a Resource/Collection

The extract task dumps a resource or collection to a file or directory.

                        <xdb:extract xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare/plays" resource="hamlet.xml" destfile="/tmp/hamlet.xml"/>
                    

                        <xdb:extract xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc/db/shakespeare/plays" destdir="/tmp" subcollections="true" createdirectories="true"/>
                    

resource  
The name of the resource which should be extracted.

subcollections  
If "true" all sub-collections of the specified collection are extracted as well

destfile  
The name of the destination file to extract to. Only supported when a resource is extracted.

destdir  
The name of a destination directory to extract to. Has to be used when extracting a collection.

createdirectories  
If "true" directories for sub-collections will be created Otherwise all extracted resources are written to the destination directory directly.

type  
Type of the resource to extract. Only "xml" is supported currently.

overwrite  
Set to true to force overwriting of files.

## Backup

Creates a backup of the specified database collection on the local disk. For example:

                        <xdb:backup xmlns:xdb="http://exist-db.org/ant"
        uri="${backup.uri}/db/system"
        dir="${backup.dir}" user="${backup.user}" password="${backup.pass}"/>
                    

creates a backup of the system collection.

dir  
The directory where backup files will be stored.

## Restore

Restores database contents from a backup. The backup is read from location specified by the `dir` or `file` attributes. The `dir` attribute should point to a directory containing a valid backup, i.e. a directory with a \_\_contents\_\_.xml backup descriptor in it (e.g. `/home/me/Backup/090228/db`). The `file` attribute should specify a zip archive which contains the backup. The base attribute specifies the base XMLDB URI (i.e. the URI without collections) used for the restore. The collection names will be read from the \_\_contents\_\_.xml file.

dir  
A directory containing a \_\_content\_\_.xml file to be used for the restore.

file  
A zip file which contains the backup to be restored.

The following example restores the /db/home collection:

                        <xdb:restore xmlns:xdb="http://exist-db.org/ant"
        uri="xmldb:exist://localhost:8080/exist/xmlrpc" user="admin" password=""
        dir="${backup.dir}/db/home"/>
                    

## List Groups

This task lists all groups defined in eXist-db.

                        <xdb:groups xmlns:xdb="http://exist-db.org/ant"
        uri="${backup.uri}/db/system" outputproperty="groups"/>
                    

outputproperty  
Name of new property to write the output to.

separator  
Separator character for output, by default "," (comma).

## List Users

This task lists all users defined in eXist-db.

                        <xdb:users xmlns:xdb="http://exist-db.org/ant"
        uri="${backup.uri}/db/system" outputproperty="users"/>
                    

outputproperty  
Name of new property to write the output to.

separator  
Separator character for output, by default ",".

## Lock Resource

This task locks a resource for a user.

                        <xdb:lock  xmlns:xdb="http://exist-db.org/ant"
        uri="${backup.uri}/db/shakespeare/plays" resource="hamlet.xml" name="guest"/>
                    

resource  
Name of resource to lock.

name  
Name of user to lock the resource for.

## Add User

This task adds a user.

                        <xdb:adduser xmlns:xdb="http://exist-db.org/ant"
    uri="${backup.uri}/db" name="guest" secret="ToPSecreT" primaryGroup="users" />
                    

name  
Name of the new user.

home  
Name of collection that is home collection.

secret  
The password of the new user.

primaryGroup  
Name of primary group of the new user.

## Remove User

This task removes a user.

                        <xdb:rmuser xmlns:xdb="http://exist-db.org/ant"
        uri="${backup.uri}/db" name="guest"/>
                    

name  
Name of the user to remove.

## Change password of an User

This task changes the password of an user.

                        <xdb:password xmlns:xdb="http://exist-db.org/ant"
    uri="${backup.uri}/db" user="dba-user" password="dba-user-SecreT" name="guest" secret="Guest-Changed-Secret" />
                    

name  
Name of the user to change the password for.

secret  
The new password of the user.

> **Note**
>
> You can of course also change your own password.

## Add Group

This task adds a group.

                        <xdb:addgroup xmlns:xdb="http://exist-db.org/ant"
    uri="${backup.uri}/db" name="guest" />
                    

name  
Name of the new group.

## Remove Group

This task removes a group.

                        <xdb:rmgroup xmlns:xdb="http://exist-db.org/ant"
        uri="${backup.uri}/db" name="guest"/>
                    

name  
Name of the group to remove.

## Change resource permissions (chmod)

This task changes the permissions of a resource or collection.

                        <xdb:chmod xmlns:xdb="http://exist-db.org/ant"
            uri="${backup.uri}/db/shakespear/plays" resource="hamlet.xml" mode="group=-write,other=-write"/>
                    

resource  
Name of resource to modify. If no resource has been specified, chmod will operate on the collection as defined by the uri.

permissions  
Permission modification string. Use either Unix-style syntax, e.g.:

rwxrwx---

or additive/subtractive syntax, e.g.:

\[user|group|other\]=\[+|-\]\[read|write|execute\]

For example, to set read and write permissions for the group, but not for others:

group=+read,+write,other=-read,-write

The new settings are or'ed with the existing settings.

mode  
Permission modification string. Use either Unix-style syntax, e.g.:

rwxrwx---

or additive/subtractive syntax, e.g.:

\[user|group|other\]=\[+|-\]\[read|write|execute\]

For example, to set read and write permissions for the group, but not for others:

group=+read,+write,other=-read,-write

The new settings are or'ed with the existing settings.

NOTE: The mode attribute on the chown ANT task is deprecated in favor of the "permissions" attribute. In the case that both "mode" and "permissions" are specfied, then the permissions attribute is the only one used.

## Change Owner of resource/collection (chown)

This task changes the owner of a resource or collection.

                        <xdb:chown xmlns:xdb="http://exist-db.org/ant"
    uri="${backup.uri}/db/shakespeare/plays" resource="hamlet.xml" name="guest" group="guest"/>
                    

name  
Name of user to own the resource/collection.

group  
Name of group to own the resource/collection.

## Database Shutdown

The shutdown task is required if you use the database in embedded mode. It will try to shut down the database instance listening at the provided URI.

## Example Ant script - Simple Data Migration

This example Ant script shows how to copy data from two different instances of eXist-db (remote or local).

To use supply your own values for the source and target user, pass, and url properties. Run the default target 'migrate' to copy data from one instance of eXist-db to another.

                        <?xml version='1.0'?>
    <project name="exist-data-migrate" default="migrate" xmlns:xdb="http://exist-db.org/ant">
    <description>Migrate data from one instance of eXist-db to another</description>

    <!-- edit these properties //-->
    <property name="p.exist.dir" value="/opt/eXist-1.0"/>
    <property name="p.source.exist.url" value="xmldb:exist://www.example.org:8080/exist/xmlrpc/db/"/>
    <property name="p.source.user" value="myusername"/>
    <property name="p.source.pass" value="myuserpass"/>
    <property name="p.target.exist.url" value="xmldb:exist://www.example.org:8680/exist/xmlrpc/db/"/>
    <property name="p.target.user" value="myotherusername"/>
    <property name="p.target.pass" value="myotheruserpass"/>
    <property name="p.export.dir" location="export"/>

    <!-- import eXist-db tasks -->
    <typedef resource="org/exist/ant/antlib.xml" uri="http://exist-db.org/ant">
    <classpath>
    <fileset dir="${p.exist.dir}/lib/core">
        <include name="*.jar"/>
    </fileset>
    <fileset dir="${p.exist.dir}/lib/endorsed">
        <include name="*.jar"/>
    </fileset>
    <fileset dir="${p.exist.dir}/lib/optional">
        <include name="*.jar"/>
    </fileset>
    <pathelement location="${p.exist.dir}/exist.jar"/>
    <pathelement location="${p.exist.dir}/exist-optional.jar"/>
    </classpath>
    </typedef>

    <target name="clean" >
        <delete dir="${p.export.dir}"/>
        <mkdir dir="${p.export.dir}"/>
    </target>

    <target name="migrate" depends="extract-source, load-target">
        <echo message="migration complete"/>
    </target>

    <target name="extract-source" depends="clean" description="export xml from source eXist-db instance">

    <xdb:extract uri="${p.source.exist.url}"
    user="${p.source.user}"
    password="${p.source.pass}"
    destdir="${p.export.dir}"/>

    </target>

    <target name="load-target" description="store xml to
    target eXist-db instance">

    <xdb:store uri="${p.target.exist.url}"
    user="${p.target.user}"
    password="${p.target.pass}"
    createcollection="true"
    createsubcollections="true">

    <fileset dir="${p.export.dir}"/>
    </xdb:store>

    </target>

    <target name="check-env"
    description="check env and dependencies are
    installed">
    </target>

    </project>
            
                    

You can find this Ant script under the samples/ant directory.
