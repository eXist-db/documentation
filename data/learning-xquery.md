# Learning XQuery and eXist-db

## Introduction

This article provides tips and resources for newcomers to XQuery and eXist-db.

## Key Points to Learning XQuery

This is a guide to help you learn XQuery. It contains some brief background information on XQuery and then lists a number of resources you can use to learn XQuery.

XQuery is unique in the development stack in that it replaces both SQL and the traditional software layers that convert SQL into presentation formats such as HTML, PDF and ePub. XQuery can both retrieve information from your database and format it for presentation.

Learning how to select basic data from an XML document can be learned in just a few hours if you are already familiar with SQL and other functional programming languages. However, learning how to create custom XQuery functions, how to design XQuery modules and how to execute unit tests on XQuery takes considerably longer.

### Learning by Example

Many people find that they learn a new language best by reading small examples of code. One of the ideal locations for this is the [XQuery Wikibook Beginning Examples](http://en.wikibooks.org/wiki/XQuery#Beginning_Examples)

These examples are all designed and tested to work with eXist. Please let us know if there are specific examples you would like to see.

### Learning Functional Programming

XQuery is a functional programming language, so many things that you do in procedural programs are not recommended or not possible. In XQuery all variables should be immutable, meaning they should be set once but never changed. This aspect of XQuery allows it to be stateless and side-effect free.

### Learning FLOWR statements

Iteration in XQuery uses parallel programming statements called FLOWR statements. Each loop of a FLOWR statement is performed in a separate thread of execution. As a result you cannot use the output of any computation in a FLOWR loop as input to the next loop. This concept can be difficult to learn if you have never used parallel programming systems.

### Learning XPath

XQuery also includes the use of XPath to select various nodes from an XML document. Note that with native XML databases the shortest XPath expression is often the fastest since short expressions use element indexes. You may want to use a tool such as an XPath "builder" tool within an IDE such as oXygen to learn how to build XPath expressions.

### Using eXide

eXist comes with a web-based tool for doing XQuery development called eXide. Although this tool is not as advanced as a full IDE such as oXygen, it is ideal for small queries if an IDE is not accessible.

### Learning how to update XML documents

eXist comes with a set of operations for updating on-disk XML documents. [eXist XQuery Update Operations](update_ext.md)

### Learning how to debug XQuery

eXist has some support for step-by-step debugging of XQuery, but the interface is not mature yet. Many people choose to debug complex recursive functions directly within XML IDEs such as oXygen that support step-by-step debugging using the internal Saxon XQuery library. The oXygen IDE allows you to set breakpoints and watch the output document get created one element at a time. This process is strongly recommended if you are learning topics like recursion. [eXist XQuery Debugger](debugger.md)

### Learning recursion in XQuery

XML is an inherently recursive data structure: trees contain sub-trees, so many XQuery functions for transforming documents are best designed using recursion. One good place to start learning recursion is the identity node filter functions in the XQuery wikibook.

### Effective use of your IDE

Most developers who do XQuery more than a few hours a day eventually end up using a full commercial XQuery IDE, with oXygen being the best integrated with eXist. Setting up oXygen is a bit tricky the first time since you need to load five jar files into a "driver" for oXygen. See [Using oXygen](oxygen.md). Yet once this is done and the default XQuery engine is set up to use eXist, there are many high-productivity features that are enabled. Central to this is the XQuery auto-complete feature. As you type within XQuery, all eXist functions and their parameters are shown in the IDE. For example if you type "xmldb:" all the functions of the XMLDB module will automatically appear in a drop-down list. As you continue to type or select a function the parameters and types are also shown. This becomes a large time saver as you use more XQuery functions.

## Learning XQuery Resources

The following is an annotated list of resources that can help you learn XQuery.

# 

<http://www.w3.org/TR/xquery/> The official 1.0 specification. You should use XQuery 1.0 to keep your XQuery programs portable.

<http://en.wikibooks.org/wiki/XQuery> A collection of sample programs in XQuery using the eXist system. Note that some examples are not complete and some may not be updated to use the latest release of eXist.

<http://en.wikibooks.org/wiki/XQuery#Beginning_Examples> Simple examples starting with basic sequences and FLOWR statements

<http://en.wikipedia.org/wiki/XQuery> An excellent brief overview of what XQuery is and it main features.

<http://www.datypic.com/books/xquery/> A precise and thorough coverage of all the features of the XQuery language. An excellent and well-written reference book for all XQuery developers. This book is frequently cited in other XQuery tutorials.

<http://www.w3schools.com/xquery> Basic XQuery tutorial but not recommended for eXist specific items. Discussion of XLink and XPointer should not be used.
