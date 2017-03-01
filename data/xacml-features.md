# Access Control in eXist: Capabilities

## Introduction

In XACML, access to resources (such as an XQuery or a Java method) can be controlled by characteristics of the subject(s) accessing the resource (a common subject is a user executing a query), the resource being accessed, the action being taken on the resource (such as 'execute query'), or the environment in which the access is being made (such as the time of the access). This part of the documentation provides an overview of what subjects, resources, and actions are available and what characteristics of those entities may be use to control access.

> **Note**
>
> The XACML functionality is marked as deprecated and should not be used for new projects. Please use the new [ACL](security.md#ACLs) functionality that has been introduced in eXist-db v2.0.

## Subjects

### User

All types of access may be restricted by the user initiating access to a resource, currently XQueries. The user's name and the names of the groups of which the user is a member may be used to control access to any of the supported resources mentioned in the Resources section.

### Intermediaries

There is no support yet for access control based on the route taken to the resource. This type of control would allow, for example, a user to use a library module library.xqm by running query.xql but not through a query passed directly in the HTTP request.

## Resources

All XQuery modules may be controlled by their source. A source has a type (Cocoon, URL, Class, File, Database, String, or ClassLoader resource) and a key. The key is specific to the source. For URLs, ClassLoader resources, and Cocoon, the key is the URI or URL of the source.

Access may also be controlled based on the method of access. The following are direct access contexts: REST, XML:DB (local), XML-RPC, WebDAV, and SOAP. Additionally, some contexts are indirectly used: eXist internally executes queries for validation, triggers may execute queries, and XInclude expansion requries evaluation of a query. There is also a context for unit tests when they directly access the query classes without going through one of the above interfaces.

-   A String source comes from directly passed queries. This may occur externally through the REST-style interface or XML:DB or eXist may internally execute queries directly. The key is "String" for every String source. This source is only used for main modules.

-   A source of type File comes directly from the filesystem. The key is the absolute path to the file. External library modules or main modules may have this source type.

-   A source of type Database is stored in the database. The key is the absolute path to the resource (such as /db/test/test.xqm). External library modules or main modules may have this source type.

-   Cocoon sources are sources requested from a Cocoon context. The key is the URI to the resource. Main modules may have this source type.

-   Class sources are sources that are Java classes. The key is the fully qualified name of the class. These will always be the type of internal library modules and reflective access to Java methods.

-   URL sources have as the key the URL. External library modules or main modules may have this source type.

-   Class loader sources are those resources found by the class loader. The key is the path to the resource. External library modules or main modules may have this source type.

### Java Reflection

Invocation of Java methods by reflection may be restricted by class and method name.

### Internal XQuery Library Modules

Calls to XQuery functions in modules written in Java may be restricted by the name of the implementing module's class, the module's namespace URI, and the name of the function.

### External XQuery Library Modules

Calls to XQuery functions in library modules stored in the database or the file system may be restricted by namespace URI, function name, and module source.

### XQuery Main Modules

Query execution may be controlled by the source of the query.

> **Note**
>
> Overloaded Java methods and XQuery functions share the same access control settings.

## Actions

There is currently one action for each type of resource. The 'execute query' action corresponds to the XQuery main module resource, the 'call function' action corresponds to the XQuery library module resource (both internal and external), and the 'invoke method' action corresponds to the Java method resource.

## Environment

The characteristics of the environment that are present are the current date and time.

## What is not controlled

You cannot control access to documents, HTTP put or get requests, which XML-RPC methods may be invoked, or anything else not explicitly mentioned above. Additionally, there is currently no supported method of using eXist's XACML-related classes for access control in your own application.
