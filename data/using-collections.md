# Using collections in eXist

## Using collections to group your XML documents

eXist supports the concept of document collections. Collections are groupings of both XML documents, binary documents and other collections. This document describes how you can use collections and some design considerations when deciding what collections to use and how to partition your data into XML files.

By convention the root collection of eXist is called "/db" much like the forward slash (/) is the root collection of a UNIX file system. Users create sub-collections under the "/db" collection to store their data.

Collections contain only two types of things, actual files or sub-collections. Each of the files are called "resources" but only well-formed XML documents are indexed by eXist. Non XML files are stored as binary objects in eXist.

In general, you can group XML data files into sub-collections in whatever way is most convenient and meaningful to your organization. For example, if you are collecting daily sales data in XML format you can place daily sales orders for each month into a separate collection for that year and month. So for example sales for October 2012 would be in "/db/sales/data/2010/10". Native XML databases can easily query all XML documents in any folder or any sub-folder to find the document you requested. Unlike a file system, you don't need to know what year or month the data is in. You only need to know the root collection to start your queries. eXist will find your documents from there.

How you create collections should reflect some type of logical structure of your data. You can store tens of thousands of XML file in a single collection, but this might make viewing the files challenging using a folder-interface. Most folder interface tools try to list all the files in a collection. They don't stop a the first 100 items and say "click here for more". So for practical browsing reasons collections of under 1,000 XML files are preferred by most collection designers.

Using dates to separate your data is also quite common. This allows you to remove old records that many not be needed by simply removing a year or month-level collection.

Collections also allow you to customize behavior for any action for all documents within a collection by using database triggers. These triggers are then executed when any document is created, updated, deleted or viewed. Let's say that a typical function of a document collection, is to indicate which elements in the document should be indexed. Once a trigger has been configured for the collection, changes to any document below that collection/sub-collection will be automatically updated and indexed.

XML databases are designed to be flexible with the amount of data stored in a collection or XML file. They work equally well if you have a single file with 10,000 sales transactions or 10,000 individual transaction files. The query you write won't need to be changed if you alter how the files are grouped as long as you reference the root collection of your documents.

There are however, some design considerations to think about when you're performing concurrent reads and writes on a document collection. Some native XML databases only guarantee atomic operations within a single document. So placing two different data elements that must be consistent within an single document might be a good practice.

You many also want to use a database lock on a document or a sub-document to prevent other processes from modifying it at critical times. This feature is similar to file locks that are performed on a shared file in a file system. For example, if you are using a forms application to edit a document you may not want someone else to save their version over your document. Locking a document helps you avoid conflicts when multiple people attempt to edit the same document at the same time. You can also calculate hash tags on a document as you load it into an editor to verify that it has not been modified by someone else while you have been editing it. This strategy, and the use of the etags HTML element, helps you avoid the missing updates problem.

Native XML database collections can be used as a "primary taxonomy" to store documents of different types. This is similar to the categorization of a book in a library where the book is found according to its primary subject. However, unlike a physical book, a document can contain many different category elements and thus does not have to be copied or moved between collections. An XML document can contain keywords and category terms that allow search tools to find documents that fit multiple subject categories.

Collections can also be used as a way to group documents according to who can access them. You may have internal policy that only allows users with a particular role to modify a document. Some native XML systems provide basic UNIX-style permissions on each collection to allow only some groups to have write access to a collection of documents. The UNIX permissions structure permits very fast calculation of what users have access to a document. The disadvantage of using UNIX style permissions is that only a single group can be associated with a collection. Other native XML collection management systems add more flexible access control lists to protect each collection according to multiple groups or roles. Role based collection management is the most robust permission system and is preferred by large organizations with many concurrent users from multiple business units unfortunately only some native XML databases support role-based access control.

An example of using security-based collections to group web application functionality. For example you can:

-   Use the "/db/apps" folder to hold all your applications

-   Use "/db/apps/books" folder to hold your books application.

-   Use a "/db/apps/books/data" to store the actual book data. Only users with edit rights can change the data in the collection. This is the collection that should be versioned or backed up after changes have been made to the book data.

-   Use a "/db/apps/books/views" to store read-only transform views of the book data.

-   Use a "/db/apps/books/edit" to tools that allow you to edit books. Only users with edit rights will be able to access this folder.

-   Use a "/db/apps/books/admin" to store tools that allow you to perform administration on the application. For example changing code-tables in selection lists or tools that re-index the collection.

-   Use a "/db/apps/books/unit-tests" to store unit-test for the books application. Only developers will need this collection loaded on their system.

If you are doing forms processing a common design is to use one file per form. Although there is no reason you must do this. But it does make versioning and other locking issues much easer. Technically, as long as a document has some identifier in it you can use XQuery update functions to change that record in a large XML document with a forms update tool.

In this example only a subset of all roles can add or update the XML files in the "data" collection. A larger number of roles can view and search for books using the queries in the view and search collections. The settings in the overall application information file (app-info.xml) file associates each role with specific read and write permissions.

eXist 2.1 also has a new replication feature that allows you to replicate collections to remote eXist systems by configuring a collection trigger. This might also be a consideration when designing your collection.
