# Versioning Extensions

## Abstract

> Since release 1.4, eXist-db provides a basic document versioning extension. The extension will track all changes to a document by storing a diff between the revisions. Older versions can be restored on the fly and even queried in memory. There's also basic support to detect and intercept conflicting writes.
>
> However, eXist-db has no control over the client. It does not know where a document update comes from and cannot directly communicate with the user. The versioning extension should be seen more like a toolbox than a complete solution. Advanced functionality (e.g. merging and conflict resolution) will require support from the end-user applications, which is outside of eXist's reach.
>
> The versioning extension has been created with human editors in mind, who will typically be changing a document through an editor or some form-based frontend. It should work well with documents up to several megabytes in size. However, the versioning will not track machine-generated node-level edits using XUpdate or XQuery update extensions.

## Components

The versioning extensions consist of the following components:

VersioningTrigger  
a trigger which has to be registered with a collection and implements the core versioning functionality

VersioningFilter  
a serialization filter which adds special version attributes to every serialized document. The attributes are used to detect conflicting writes.

`versioning.xqm`  
an XQuery module which provides a function library for end-user applications, including functions like v:doc (used to restore a given revision on the fly).

## Setup

Versioning can be enabled for any collection in the collection hierarchy. It is not necessary to use versioning for all collections. To enable versioning, a trigger has to be registered with the top-level collection. This is done through the same collection configuration files that are used for defining indexes.

### Register the versioning trigger

To enable version for a collection, you have to edit the collection's `.xconf` configuration file, which has to be stored below the `/db/system/config` collection. As described in the [Configuring Indexes](indexing.md) document, the `/db/system/config` collection mirrors the hierarchical structure of the main collection tree.

Within the collection's `.xconf`, you should register the trigger class `org.exist.versioning.VersioningTrigger` for the "create", "update", "delete", "copy" and "move" events:

``` xml
<collection xmlns="http://exist-db.org/collection-config/1.0">
    <index>
        <fulltext default="none" attributes="no">
        </fulltext>
    </index>
    <triggers>
        <trigger event="create,delete,update"
            class="org.exist.versioning.VersioningTrigger">
            <parameter name="overwrite" value="yes"/>
        </trigger>
    </triggers>
</collection>
```

If you store above document into `/db/system/config/db/collection.xconf`, it will enable versioning for the entire database.

> **Note**
>
> Note that a `collection.xconf` at a lower level in the hierarchy will *overwrite* any configuration on higher levels, including the trigger definitions. Triggers are not inherited from ancestor configurations. If the new configuration doesn't define a trigger, the trigger map will be empy.
>
> When working with nested collection configurations, you need to make sure that the trigger definitions are present in all `collection.xconf` files.

VersioningTrigger accepts one parameter, `overwrite`: if this is set to "no", the trigger will check for potential write conflicts. For example, if two users opened the same document and are editing it, it may happen that the first user saves his changes without the second user recognizing it. The second user also made changes and if eXist did allow him to store his version, he would just overwrite the modifications already committed by the first user.

The `overwrite="no"` setting prevents this. However, eXist has no control over the client. It does not know where the conflicting document came from. All it can do is to reject the write attempt and raise an error. The error should then be handled by the client. Right now there are no clients to support this. More work will be required in this area. However, clients can already use the supplied XQuery functions to check for write conflicts (see below).

### Enabling the serialization filter

In order to detect conflicting writes, the versioning extension needs to keep track of the base revision to which changes were applied. It does this by inserting special metadata attributes into a document when it is retrieved from the database. For this purpose, a *custom filter* has to be registered with eXist's serializer. This is done in the serializer section in the main configuration file, `conf.xml`. Add a custom-filter child tag to the serializer element and set its `class` attribute to `org.exist.versioning.VersioningFilter`:

``` xml
<serializer add-exist-id="none" compress-output="no" enable-xinclude="yes"
            enable-xsl="no" indent="yes" match-tagging-attributes="no" 
            match-tagging-elements="no">
    <custom-filter class="org.exist.versioning.VersioningFilter"/>
</serializer>
```

eXist needs to be restarted for the versioning filter to become active.

## Checking versions through the admin webapp

> **Note**
>
> This part of the documentation does not reflect the current state of the software. The old HTML admin interface has been removed meaning that the versioning panels mentioned in the documentention below are removed too.

The admin web application provides a simple way to see the revision history of a document and restore old versions. From the sidebar menu, select Browse Collections. Within the collection view you should find a revision number next to each document which has been changed since versioning was enabled. Unchanged documents will not have a revision number:

The revision number is the last number in each row ("34" in the screenshot above). You can click on the revision number to see the history of changes for this document:

Clicking on Diff shows the differences between the selected and the previous revision. The way in which the differences are recorded is specific to eXist. It uses eXist's unique node ids to identify the reference node to which a change applies (the `ref` attributes in the XML shown above).

The Restore link will restore the corresponding revision. This is done in memory by recursively applying all diffs since the base revision.

## Accessing the versioning information

The versioning extension uses the collection `/db/system/versions` to store base revisions and diffs. The collection hierarchy below `/db/system/versions` again mirrors the main collection tree. For each versioned resource, you will find a document with suffix `.base`, which contains the base revision, i.e. the first version of the document. Each revision is stored in a document which starts with the original document name and ends with the revision number, e.g. `hamlet.xml.35`:

Like the admin webapp, you can use XQuery functions to access the revision history or restore a given revision. eXist provides a single XQuery module for that. For example, to view the history of a resource, use the following query:

``` xquery
import module namespace v="http://exist-db.org/versioning";
v:history(doc("/db/shakespeare/plays/hamlet.xml"))
```

This should return an XML fragment like the following:

``` xml
<v:history>
    <v:document>/db/shakespeare/plays/hamlet.xml</v:document>
    <v:revisions>
        <v:revision rev="35">
            <v:date>2009-08-22T22:19:33.777+02:00</v:date>
            <v:user>admin</v:user>
        </v:revision>
        <v:revision rev="36">
            <v:date>2009-08-22T22:38:41.629+02:00</v:date>
            <v:user>admin</v:user>
        </v:revision>
    </v:revisions>
</v:history>
```

The most important function is `v:doc`, which is used to restore an arbitrary revision of a document on the fly. You can use this function similar to the standard `fn:doc` to query the revision. For example:

``` xquery
import module namespace v="http://exist-db.org/versioning";
v:doc(doc("/db/shakespeare/plays/hamlet.xml"), 35)//SPEECH[SPEAKER="HAMLET"]
```

This will restore revision 35 of `hamlet.xml` and then find all SPEECH elements with a SPEAKER called "HAMLET". Please note that no indexes will be available to the query engine when processing a restore document.

## Detecting write conflicts

To avoid that a user overwrites the changes made by another user, eXist needs to know upon which revision the user's changes are based. To make this possible, the versioning filter adds a number of metadata attributes to the root element of a document when it is serialized (e.g. to be opened in an editor). The inserted metadata attributes are all in a separate versioning namespace and will never be stored in the db. The following fragment shows the added attributes:

``` xml
<PLAY xmlns:v="http://exist-db.org/versioning" v:revision="36" v:key="12343e4940b24" 
v:path="/db/shakespeare/plays/hamlet.xml">...</PLAY>
```

As described above ("Setup"), when eXist detects a potential write conflict, it cannot do more than to reject the update and raise an error. However, there's an XQuery function which can be used by clients to check if newer revisions exist. You pass it the revision number and the unique key as given in the versioning attributes of the document root element. If the function returns the empty sequence, no newer revisions exist in the database. Otherwise, the function returns the version documents of each newer revision.

``` xquery
import module namespace v="http://exist-db.org/versioning";
v:find-newer-revision(doc("/db/shakespeare/plays/hamlet.xml"), 36, "12343e4940b24")
```

Once you made sure that you really want to store the document and overwrite the other revisions, simply remove the version attributes from the root element.

Future releases of the versioning extension may provide a more advanced conflict handling, including an automatic merge of non-conflicting changes.
