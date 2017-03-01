# Code Review Guide

## Introduction

Several aspects of the design and deployment of the custom solution will be analyzed and appropriate recommendations be provided as well. These criteria are to be followed when conducting code review.
1.  Does the solution provide custom class libraries for reusable classes & methods

2.  What classes have been extended or implemented and whether they are supported.

3.  Look for deprecated classes & methods. Look for alternate methods if deprecated methods used.

4.  Have proper classes been extended to provide functionality based on functional requirements? Need to check whether too heavy of objects been extended where a lighter weight object would suffice.

5.  Has proper abstract classes & interfaces been used to provide a flexible, yet cohesive design model?

6.  Has code been properly documented: JavaDoc, etc.?

And in general, we will look for the 7 Deadly Sins of Software Design and make recommendation accordingly:

-   Rigidity: Make it hard to change, especially if changes might result in ripple effects or when you don't know what will happen when you make changes.

-   Fragility: Make it easy to break. Whenever you change something, something breaks.

-   Immobility: Make it hard to reuse. When something is coupled to everything it uses. When you try to take a piece of code (class etc.) it takes all of its dependencies with it.

-   Viscosity: Make it hard to do the right thing. There are usually several ways to work with a design. Viscosity happens when it is hard to work with the design the way the designer intended to. The results are tricks and workarounds that, many times, have unexpected outcomes (esp. if the design is also fragile).

-   Needless Complexity (Over design): When you overdo it; e.g. the "Swiss-Army knife" anti-pattern. A class that tries to anticipate every possible need. Another example is applying too many patterns to a simple problem etc.

-   Needless Repetition: The same code is scattered about which makes it error prone.

*The 7th Deadly Sin of Software Design is (the obvious) "Not doing any".*

## Clean Unnecessary Code

As our business need and technique evolves, there are more and more changes to our implementation, and thus there are many code deprecated. Some of them may need to remain due to legacy data, but some of them can be cleaned to make the maintenance easy and even improve the performance.

Different cases that might be found in the review:

-   Whole classes are deprecated

-   Some code segments are unnecessary due to changes.

-   Redundant registration of some listener services.

A good planning at the beginning will help to avoid mess in the code. And whenever there is a change to be implemented, plan it first with a thorough review to its impact and identify those codes need to be changed at the same time. Only after that actions can be taken to implement it,

We recommend to review that code have a lot changes and remove unnecessary code and merge similar code with team discussion. This may be scheduled after migrated system go-live. This will improve code quality, make it easy for debugging, and reduce unnecessary maintenance work.

## Optimize and reduce database query to improve performance

Sometimes, we need to balance between the access of Disk/Network and RAM. And we may improve performance at cost of memory as long as memory consumption is not the bottleneck. As a rule of thumb, database query is more expensive then in memory processing in terms of performance, so we need to optimize and combine some of the queries to reduce database query as much as possible. Another balance need to control is between the optimization and readability. We need to manage optimization in a controllable way.

## Use local cache to improve performance

It is recommended to use local cache to store those frequently access data to avoid database queries. This cache mechanism is simple and easy to implement.

## Avoid the use of expensive operations

Avoid using any expensive operations such as String concatenation. String concatenation which is expensive because Strings are constant; their values cannot be changed after they are created. So each concatenation will create a new String object.

## Proper rollback of database transactions

For database transaction, fewer places don’t rollback properly, here is an example:

``` java
Transaction trx = new Transaction();
try
{
    trx.start();
    // do something
    if (trx != null ) trx.commit;
    trx = null;
}
catch ( Exception e )
{
    // processing exception
}
if( trx != null )
{
    trx.rollback();
}
```

The consequence of this code is that if there is an error happens when executing the transaction, the transaction will not be rolled back correctly. This will have an impact to the data integrity.

Recommendations

We recommend using the following structure for all database transactions to ensure data integrity.

``` java
//….
finally
{
    if( trx != null )
    {
        trx.rollback();
    }
}
```

## Hard Coding

Hard code is hard to maintain and may cause potential problems.

Here is an example:

``` java
public static String buildAuthURL ( String action, String cls, WfProcess wfprocess, String rolevalue, String nextAction ) throws Exception
{
    ReferenceFactory rf = new ReferenceFactory();
    Properties urlProperties = new Properties();
    urlProperties.put( "action", action );
    urlProperties.put( "class", cls );
    urlProperties.put( "wfprocess", rf.getReferenceString( wfprocess ) ); // WfProcess Oid
    urlProperties.put( "role", rolevalue );
    urlProperties.put( "nextAction", nextAction );
    //urlProperties.put("Users", getRoleMapUsers(wfprocess, rolevalue));
    String url = GatewayURL.buildAuthenticatedURL( "XX.enterprise.URLProcessor", "generateForm", urlProperties ).toExternalForm();
    url = url.substring( ( XXProperties.getLocalProperties().getProperty( "XX.server.codebase" ) ).length() - 10 );
    return url;
}
```

This code will remove the host name from the URL, however, it is hard coded and may break if there is a rehosting.

## Resources not released

Resource should be released when it is not needed.

Here is an example extracted from a system:

``` java
XXProperties XXp = XXProperties.getLocalProperties();
Properties prop = new Properties();
FileInputStream fis = new FileInputStream( XXp.getProperty ("XX.home", "e:/ptc/Windchill" ) + "/codebase/ext/misccorp/misccorp.properties" );
prop.load( fis );
return prop;
```

The FileInputStream is not closed before returning from the method.

## Comply to Java Coding Standards

Code conventions are important to programmers for a number of reasons:

-   80% of the lifetime cost of a piece of software goes to maintenance.

-   Hardly any software is maintained for its whole life by the original author.

-   Code conventions improve the readability of the software, allowing engineers to understand new code more quickly and thoroughly.

-   If you ship your source code as a product, you need to make sure it is as well packaged and clean as any other product you create.

Sun coding standards is the standards eXist follows for coding. In addition to that, there is some addendum.

Comments

Further details on JavaDoc comments over and above the Sun standard, can be found in the Sun Doc Comments how to guide.

Have JavaDoc comment for all classes

Each class should have a comment. This comment should describe the function, intent and role of the class.

Have JavaDoc comment for all methods

Each method should have a comment describing how the method is called and what it does. Discussion of implementation specifics should be avoided since this is not for the user of a method to know in most cases. That information belongs in implementation comments.

Within the method JavaDoc comment, info should be added on the parameters. Each method JavaDoc comment should contain an @param comment for each parameter, an @return comment if not a void or constructor method, and an @throws comment for each exception (cf. Documenting Exceptions with @throws Tag).

The method pre and post conditions should be documented here. Pre-conditions comprise parameter ranges and the overall state of the object and system expected when calling the method. Post-conditions should document the expected return value sets and the state of the object and system that will apply when the method exits. These should map to assertions.

The JavaDoc should also document traceability of this method to the design and the requirements. Have JavaDoc comment for all fields Each non-trivial field should have a comment describing the role and purpose of the field, as well as any other appropriate information such as the range.

Exceptions

All exceptions should be handled, it is never acceptable to simply print the exception message and stack trace. Exceptions should be dealt and corrective or informative action taken to highlight the issue.

For debugging purposes the stack trace should be logged at the final destination of the exception or at whenever the exception is modified, for example throwing a XXException instead of a java.io.IOException.

Logging

If no logging system is in use in the package already or the logging is unconditional, then log4j should be used for all logging. Please see the ***Log4J Logging Guide***.

If a class has unconditional logging, then it should be updated to use log4j. A case of unconditional logging is where there are System.out.println() in the code with no conditions surrounding the call. This unnecessarily clutters the log and places a burden on performance.

Logging should always be performed at method exit and entry as follows:

-   Log entry

-   Log arguments
-   Log exit

-   Log return values

The occurrence of exceptions and the stack trace should also be logged as info level items.

Logging calls should be wrapped in enablement checks so that arguments do not get unnecessarily evaluated for example:

``` java
  If (getLogger().isDebugEnabled() {
    getLogger().debug("Entering - method - argList");
    getLogger().debug("Arg1 :"+ theArgValue1); 
    getLogger().debug("Arg2 :"+ theArgValue2);
  }
```

Assertions

Assertions should be used in the code to verify that the expected results have occurred. Assertions should be used as liberally as possible.

Standard Assertions should be performed at method entry and exit; these methods should validate the pre and post-conditions for the method. All arguments should be checked for validity as should the return values. Similarly the state of the object and broader system should be checked as appropriate on both method entry and exit, for example if a file is open.
