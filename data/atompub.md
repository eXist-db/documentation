# A Short Introduction to the Atom Publishing Protocol

## Introduction

The [Atom Publishing Protocol](http://www.ietf.org/rfc/rfc5023.txt) is a new protocol being developed at the [IETF](http://www.ietf.org/) as part of their Atom Publishing Format and Protocol working group that lets you manipulate Atom feeds over a REST-style HTTP interface. The RFC is still in draft status but is nearing completion. Though Atom is often associated with newsfeeds, it can be used for a much wider range of applications.

eXist-db provides an implementation of the [Atom Publishing Protocol](http://www.ietf.org/rfc/rfc5023.txt) sitting on top of the database. Feed and entry data is stored into special collections. Our wiki and blog system, [AtomicWiki](http://code.google.com/p/atomicwiki), which powers the [eXist Wiki](http://atomic.exist-db.org/blogs/eXist/) is completely based on eXist's Atom support.

## Creating and Manipulating Atom Entries

To create an entry in the feed, you just POST an \[atom:\]entry element to the collection url. This creates a new entry in the feed and possibly returns a new representation of the entry. For example, to create a simple annotation entry (possibly a blog post), you'd formulate an \[atom:\]entry element using the \[atom:\]content element and post that to the server.

    POST /myblog/entries HTTP/1.1
    Host: example.org
    User- Agent: Thingio/1.0
    Content- Type: application/atom+xml
    Content- Length: nnn

    <?xml version="1.0" ?>
    <entry xmlns="http://www.w3.org/2005/Atom">
       <title>Atom-Powered Robots Run Amok</title>
       <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
       <updated>2003-12-13T18:30:02Z</updated>
       <author><name>John Doe</name></author>
       <content>Some text.</content>
    </entry>

> **Note**
>
> It is important to specify the correct Content-Type in the HTTP header. If the content type is not application/atom+xml, the server will just store the resource as a document into the existing feed collection and add an entry to the feed which links to the new resource.

The server then responds with the created entry, a location header to the created entry, or both.

    HTTP/1.1 201 Created
    Date: Fri, 7 Oct 2005 17:17:11 GMT
    Content- Length: nnn
    Content- Type: application/atom+xml; charset="utf-8"
    Content- Location: http://example.org/edit/first-post.atom
    Location: http://example.org/edit/first-post.atom

    <?xml version="1.0"?>
    <entry xmlns="http://www.w3.org/2005/Atom">
       <title>Atom-Powered Robots Run Amok</title>
       <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
       <updated>2003-12-13T18:30:02Z</updated>
       <author><name>John Doe</name></author>
       <content>Some text.</content>
       <link rel="edit"
             href="http://example.org/edit/first-post.atom"/>
    </entry>

In the above example response, notice the 'edit' relation link. This link will let you change this entry in the future. A PUT request on that link URL will update that entry in the feed. Similarly, a DELETE request on that link URL will delete the entry.

## Uploading Resources

Collections can also contain non-atom entry resources that are also represented by an \[atom:\]entry in the feed. These are created by a POST to the same collection URL. The response is an \[atom:\]entry element.

    POST /myblog/fotes HTTP/1.1
    Host: example.org
    Content- Type: image/png
    Content- Length: nnnn
    Title: An Atom-Powered Robot

    ...binary data...

In the above request, a title for the entry can be requested when the resource is created. The server then responds with the created entry, a location header to the created entry, or both.

    HTTP/1.1 201 Created
    Date: Fri, 7 Oct 2005 17:17:11 GMT
    Content- Length: nnn
    Content- Type: application/atom+xml; charset="utf-8"
    Content- Location: http://example.org/edit/first-post.atom
    Location: http://example.org/edit/first-post.atom

    <?xml version="1.0"?>
    <entry xmlns="http://www.w3.org/2005/Atom">
      <title>A picture of the beach</title>
      <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
      <updated>2003-12-13T18:30:02Z</updated>
      <author><name>John Doe</name></author>
      <summary type="text" />
      <content type="image/png"
               src="http://example.org/media/img123.png"/>
      <link rel="edit"
             href="http://example.org/edit/first-post.atom" />
      <link rel="edit-media"
            href="http://example.org/edit/img123.png" />
    </entry>

In the above example response, notice the 'edit-media' relation link in addition to the 'edit' relation link. The 'edit-media' link relation lets you update the image while the 'edit' link relation lets you change the entry as in the previous section. Also, a delete on either editing link relation will delete the resource and its corresponding entry.

## Introspection

To get started with an Atom Publishing Protocol enabled service you need to know the collection URL. A GET request on that collection URL will return the feed and that same URL is used to create entries. One way to bootstrap a client and get that collection URL is through service introspection.

Given a service URL, a GET request will return an XML document that enumerates the workspaces and collections available to use. This is a simple document of the following structure:

                        <?xml version="1.0" encoding='utf-8'?>
    <service xmlns="http://purl.org/atom/app#">
      <workspace title="Main Site" >
        <collection
          title="My Blog Entries"
          href="http://example.org/reilly/main" />
        <collection
          title="Pictures"
          href="http://example.org/reilly/pic" >
          <accept>image/*</accept>
        </collection>
      </workspace>
      <workspace title="Side Bar Blog">
        <collection title="Remaindered Links"
          href="http://example.org/reilly/list" />
      </workspace>
    </service>
                    

Each 'collection' element represents a feed that can be modified. The colleciton URL is specified in the 'href' attribute on that element.

## Setting Permissions

When creating a feed or entry, you can specify which permissions should be applied to the newly created resource within eXist. For this, the entry or feed document should contain an empty element, exist:permissions, in the "exist" namespace.

&lt;exist:permissions xmlns:exist="http://exist.sourceforge.net/NS/exist" owner="myuser" group="mygroup" mode="755"/&gt;
where `owner` and `group` should be valid database users/groups and `mode` is an octal number defining the permissions to be set. Please refer to the [Security Guide](security.xml#octal) for further information.

# Atom Services

## Modules

The Atom services are provided by modules loaded into the Atom service. This service is normally provided at the server's '/atom' path (e.g. http://localhost:8088/atom/). Every module has a name and to access the module the name is appended to the atom service path. For example, for the 'content' module, the URL http://localhost:8088/atom/content would be used.

Following the module name is a collection or resource path. That appened path maps to a collection or resource in the database with the /atom/{name} prefix removed. For example, 'http://localhost:8088/atom/content/myfeed' is the '/myfeed' collection while 'http://localhost:8088/atom/content' is the root collection of the database.

The Atom Publishing Protocol makes a distinction between a collection and the feed that represents it. In eXist, a similar distinction exists in that a collection is a set of resources and not a feed. The exception is that the Atom implementation makes one XML document special and uses that to represent the collection as a feed.

Currently, if a collection is an also an Atom feed, a document named '.feed.atom' must exist in the collection. If so, the Atom interface servlet will treat the collection as a Atom feed that can be manipulated. If that document does not exist, a module may respond with a failure status code.

## The Content Module

Getting the feed is a simple GET request with the "/atom/content" prefix on the collection path. For example, if you have a collection at '/my/blog', then the path '/atom/content/my/blog' will return the feed.

## The Edit Module

The 'edit' module allows you to create new feeds and manipulate existing feeds. This module implements the full Atom Publishing protocol except for the service introspection part.

In addition to implementing the Atom Publishing Protocol, you can create a manipulate feeds on collections. To create a new collection or turn an existing collection into a feed, POST an \[atom:\]feed element to the collection path with a /atom/edit/ prefix. This will create a new collection feed using the feed title, etc. specified in the post.

To change the metadata associated with the collection's feed (e.g. the feed title), make a PUT request to the collection URL with the updated \[atom:\]feed element without any \[atom:\]entry (these will be ignored). That will change the feed's metadata.

## The Introspect Module

Service introspection is provided by the 'introspect' module. A GET request on any collection path prefixed with /atom/introspect will return a service introspection document.

## The Query Module

The 'query' module allows you to query your collection's feed by a POST of an XQuery. The POST is sent to the collection path prefixed with /atom/query/ and is run against the collection's feed document. This module is how both the Introspect and Topic modules are implemented. For example, if you want to generate a feed of all the feeds in all subcollections, the following query could be sent:

                        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:atom="http://www.w3.org/2005/Atom">
       <title>All Feeds Example</title>
       <id>id:all</id>
       {
         let $current := substring-before(base-uri(/atom:feed),'/.feed.atom'),
             $current-path := substring-after($current,'/db')
            for $i in (collection($current)/atom:feed)
               let $path :=  substring-after(substring-before(base-uri($i),'/.feed.atom'),'/db')
                  return ( <entry>
                            {
                               $i/atom:id,
                               $i/atom:title,
                               <summary> {
                                   $i/atom:subtitle/@type,
                                   $i/atom:subtitle/node()
                               }</summary>,
                               <link rel="alternate" type="application/atom+xml" href="/atom/edit{$path}"/>
                           }
                           </entry>
                         )
       }
    </feed>
                    

## The Topic Module

The 'topic' module is an example module that generates a list of subtopics give a certain feed. A GET request will return a feed with the collection path's feed, an entry for each ancestor feed, and an entry for each sub-collection but not any sub-collections of sub-collections. This is useful for generation feed navigation.

# An Example

## Example Scenario

A blog feed can easily be implemented using the Atom services. We'll create a blog where all the entries are in the feed as well as any resources (e.g. images) are also in the same feed.

In this system, we want a /{username}/blog to be the user's blog. That way we can search against all the user blogs.

## Setting Up the Blog Feeds

We'll want a top-level blog so we can post queries. This feed can be empty and is created as:

    POST /atom/edit/users HTTP/1.1
    Host: example.org
    User- Agent: Thingio/1.0
    Content- Type: application/atom+xml
    Content- Length: nnn

    <?xml version="1.0" ?>
    <feed xmlns="http://www.w3.org/2005/Atom">
       <title>All Users</title>
    </feed>

When a user is created, we'll have to post a new \[atom:\]feed element to the user directory and blog:

    POST /atom/edit/users/johndoe HTTP/1.1
    Host: example.org
    User- Agent: Thingio/1.0
    Content- Type: application/atom+xml
    Content- Length: nnn

    <?xml version="1.0" ?>
    <feed xmlns="http://www.w3.org/2005/Atom">
       <title>User John Doe</title>
       <author><name>John Doe</name></author>
    </feed>

    POST /atom/edit/users/johndoe/blog HTTP/1.1
    Host: example.org
    User- Agent: Thingio/1.0
    Content- Type: application/atom+xml
    Content- Length: nnn

    <?xml version="1.0" ?>
    <feed xmlns="http://www.w3.org/2005/Atom">
       <title>John Doe's Blog</title>
       <author><name>John Doe</name></author>
    </feed>

## Creating Entries

Now a user can post a new entry to their blog:

    POST /atom/edit/users/johndoe/blog HTTP/1.1
    Host: example.org
    User- Agent: Thingio/1.0
    Content- Type: application/atom+xml
    Content- Length: nnn

    <?xml version="1.0" ?>
    <entry xmlns="http://www.w3.org/2005/Atom">
       <title>My First Entry</title>
       <content type='xhtml'>
          <div xmlns='http://www.w3.org/1999/xhtml'>
             <p>Isn't life grand!?!</p>
          </div>
       </content>
    </entry>

Or do whatever they like with their favorite Atom Publishing Protocol client.

## Querying the Blog

A service provider can query their blog to display the entries for a particular month:

    POST /atom/query/users/johndoe/blog HTTP/1.1
    Host: example.org
    User- Agent: Thingio/1.0
    Content- Type: application/xquery
    Content- Length: nnn

    <?xml version="1.0" ?>
    <atom:feed xmlns:atom="http://www.w3.org/2005/Atom">
         {
             /atom:feed/atom:id,
             /atom:feed/atom:title,
             /atom:feed/atom:updated,
             for $e in (/atom:feed/atom:entry)
                 where starts-with(string($e/atom:published),"2006-06")
                    return ( "&#x0a;",$e, "&#x0a;")
         }
    </atom:feed>

# Configuring the Atom Servlet

## Enabling Atom Services.

The Atom Servlet must be enabled to have Atom services provided by the standalone configuration. This is done by adding or enabled the Atom Servlet implementation in server.xml:

                            <servlet enabled="yes"
             context="/atom/*"
             class="org.exist.atom.http.AtomServlet"/>
                        

## Configuration

By default, without any configuration file, all the atom modules are provided. If there is an atom-services.xml document in the eXist home directory, that configuration will be used instead.

                        <atom-services xmlns="http://www.exist-db.org/Vocabulary/AtomConfiguration/2006/1/0">
    <module name="edit" class="org.exist.atom.modules.AtomProtocol"/>
    <module name="content" class="org.exist.atom.modules.AtomFeeds"/>
    <module name="query" query-by-post="true"/>
    <module name="topic">
       <method type="GET" query="/org/exist/atom/modules/topic.xq" from-classpath="true"/>
    </module>
    <module name="introspect">
       <method type="GET" query="/org/exist/atom/modules/introspect.xq" from-classpath="true"/>
    </module>
    <module name="example">
       <method type="GET" query="atom-example.xq"/>
    </module>
    </atom-services>
                    

### Adding a Custom Module

A custom module, implemented in Java, can be configured by adding a `{http://www.exist-db.org/Vocabulary/AtomConfiguration/2006/1/0}module` element. The 'name' specifies the module name that will be used in the URL path and the 'class' attribute specifies the implementation class. This class must implement `com.exist.atom.AtomModule`.

### Adding a Query Module

A query can be registered as module by adding a `{http://www.exist-db.org/Vocabulary/AtomConfiguration/2006/1/0}module` element without the 'class' attribute specified. The 'name' specifies the module name that will be used in the URL path.

As children of the element, a `{http://www.exist-db.org/Vocabulary/AtomConfiguration/2006/1/0}method` element can be specifed for each HTTP method for which a query should be associated. This element has three attributes:

type  
The HTTP method to which the query should be associated--must be one of GET, PUT, POST, HEAD, or DELETE.

query  
A reference to the query source (a relative URL value).

from-classpath  
A boolean value where 'true' indicates that the query should be loaded as a resource off the classpath.

# Extensions

## Setting permissions when creating feeds/entries

When creating a new feed or entry, you can specify access permissions as well as an owner and owner group for the new resource. This is done by including a special exist:permissions element in the posted feed or entry document:

&lt;exist:permissions mode="0755" owner="editor" group="users"/&gt;
The `mode` attribute specifies the permissions to be assigned to the resource. The attribute value has to be an octal number or a string describing the permissions to set, using the syntax:

\[user|group|other\]=\[+|-\]\[read|write|update\]\[, ...\]
The `owner` attribute specifies the user which will own all resources associated to the feed or entry. Parameter `group` specifies the user group.
