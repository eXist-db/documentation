# Access Control in eXist: Introduction to XACML

## The XACML Standard

[eXtensible Access Control Markup Language (XACML)](http://www.oasis-open.org/committees/tc_home.php?wg_abbrev=xacml) is an OASIS standard for restricting access to resources. eXist currently uses version [1.1](http://www.oasis-open.org/committees/tc_home.php?wg_abbrev=xacml#XACML11) / [1.0](http://www.oasis-open.org/committees/tc_home.php?wg_abbrev=xacml#XACML10) of the standard. The most recent version is [2.0](http://www.oasis-open.org/committees/tc_home.php?wg_abbrev=xacml#XACML20) (unsupported). Work on version 3.0 is currently [in progress.](http://www.oasis-open.org/committees/tc_home.php?wg_abbrev=xacml#CURRENT) The following background information on XACML is not exhaustive. It is meant to be a relatively brief introduction to XACML in order to get started using XACML in eXist.

> **Note**
>
> The XACML functionality is marked as deprecated and should not be used for new projects. Please use the new [ACL](security.xml#ACLs) functionality that has been introduced in eXist-db v2.0.

## Basic Terminology

There are a few common terms used when discussing XACML. There are many more terms explicitly defined in the glossaries of the specifications; these terms are the ones that occur frequently throughout this documentation and are the most important for an overall understanding of XACML. Additionally, the below explanations are not the official definitions given in the XACML specifications. Those definitions may be found in the glossary of any of the specifications listed in the previous section.

Resource  
A resource is anything to which access can be controlled. Examples include XQuery modules and Java methods.

Access Request  
An access request consists of attributes that describe an operation on a resource. There are usually attributes providing information about the subject(s) (for example, a user) making the access, the resource being accessed, and the action being performed on the resource (such as 'execute query' or 'call function').

Policy  
A policy is a group of definitions that restricts access to resources. Policies are generally written by a database administrator.

PEP  
A Policy Enforcement Point (PEP) generates the access request to the Policy Decision Point (PDP). It interprets the PDP's decision and proceeds accordingly. For example, the PEP will likely perform the access if it is allowed or provide feedback to the user if the access is not allowed.

PDP  
A Policy Decision Point (PDP) handles an access request and determines if that access is allowed. The PDP uses policies in order to make that decision.

## An Example

To try to help make the key terms and their usage clearer, here is an example of an XACML use case in eXist.

A user clicks the Function Library documentation link on the left sidebar on the eXist webpage. This causes a request to eXist to execute the XQuery functions.xq. The code responsible for executing XQueries contains a Policy Enforcement Point (PEP) that generates an access request. This request contains the user making the request (in this case, the user under which Cocoon runs), the interface used to make the request (Cocoon uses the XML:DB interface, so 'XML:DB' is the specified interface in the request), the source of the query (which is 'functions.xq' for this example), and the action being performed on the resource (in this example, 'execute' is the action).

The PEP makes the request to the Policy Decision Point (PDP). The PDP finds the applicable policy out of all of the policies created by the administrator. The PDP then checks the request against the policy, makes a decision, and informs the PEP. Let's say that in this example, the administrator decided to allow execution of functions.xq by everyone. The PDP then informs the PDP that functions.xq may be executed.

The PEP gets the response from the PDP that executing functions.xq is allowed. It allows the query execution code to proceed. If the access were denied, it would have thrown a PermissionDeniedException.

During its execution, the functions.xq query calls several functions in the http://exist-db.org/xquery/util module during its execution. util:registered-modules() is one of these functions. In the code that performs XQuery function calls, there is a PEP controlling access to function calls. This PEP generates the appropriate access request, passes it to the PDP, obtains the result, and allows the method to be called if the PDP allowed the access.

This sequence of events occurs for each access to a controlled resource.

## XACML Policies

This section describes XACML policies in enough detail to write policies in eXist using the graphical policy editor in the client. To manually create policies, the level of detail provided in the specifications (or possibly in a thorough tutorial) is probably required. A policy has a structure that is represented by the following cropped screenshot from the graphical editor.

A Policy Decision Point (PDP) responds to an access request by finding the unique policy that applies to that request. It is an error if more than one policy applies or if no policy applies. The target section of each policy provides the initial information for determining the applicable policy.

### The Target Section

#### Purpose

A target is intended to be a simple description of the requests to which its enclosing policy applies by allowing basic comparisons—such as equals, greater than, or less than—between an attribute specified in the request and a given literal value.

So, for a policy to apply to a request made by the "guest" user, the semantics of the target section of that policy might be:

This policy applies if: the value of the subject attribute "user-name" in the request equals the string constant "guest".
The target section does not allow for more advanced comparisons—such as regular expression matching, functions, and operators—because it is supposed to be easily indexable. That is, the target section is intended to be a quick way to decide whether a particular policy applies to a request.

#### Usage

In XACML 1.0/1.1, there are three types of attributes in a target: subject, resource, and action. XACML 2.0 (currently unsupported) adds environment attributes to this list.

Each attribute type has zero or more attribute groups. If the type has no groups, it matches all requests. Each attribute in a given group must match the request in order for that group to match the request. At least one group in an attributes type must match the request for the type to match the request and each type must match the request for the target to match.

So, to expand upon the previous semantic example, suppose the administrator has two cases to which he or she wants the policy to apply. The first case is when the XQuery "delete.xql" is being accessed through the REST-style interface. The second case is when the Java method "exit" in the class "java.lang.System" is called (from a query) through the XML:DB interface. Expressed in the target of a policy, the semantics of the target might be:

This policy applies if the resource being accessed is: (an "XQuery main module" named "delete.xql" accessed through the "REST" interface) OR (a "Java method" named "exit" in class "java.lang.System" accessed by the "XML:DB" interface).
The parentheses are added for clariy and should emphasize that this policy does not apply to a request to access an XQuery main module named "delete.xql" accessed through the XML:DB interface. Similarly, it doesn't apply to the Java method name "currentTimeMillis" in class "java.lang.System" (no matter which interface is being used to access it).

Restrictions that cross attribute types cannot be completely expressed in a target.

An example of such a case is if the administrator wants to allow the "xmldb" user to access resources through the XML:DB interface only and the "cocoon" user to access resources through the Cocoon interface only. If the administrator attempted to express these restrictions solely in the target of a policy, its semantics would be something like:

This policy applies if: The subject's name is ("xmldb" or "cocoon") AND the interface is ("XML:DB" or "Cocoon").
The parentheses are added for clarity and should help demonstrate that the "cocoon" user would be allowed access through XML:DB and the "xmldb" user would be allowed access through Cocoon although this was not intended.

If the target section of a policy applies to the request, the PDP then evaluates that policy's rules.

### Rules

Each rule has a target section that has the same purpose and structure as the target section of a policy (to determine if the rule applies to a request). A rule has an additional section that allows for more advanced comparisons than the target section. Its purpose is also to determine if the rule applies to a request. A rule applies to a request if both its target and condition section apply to a request.

The condition section is essentially a functional language. Functions operate on the results of other functions, literal values, and attributes from the request. There are no side effects to function calls and the final result is a boolean value indicating whether or not the rule applies to the request.

A rule has a defined effect when it applies to a request. Valid effects are Deny and Permit.

To make the decision on the request, the PDP uses the policy's rule-combining algorithm. For each policy, a rule combining algorithm determines how the rules of a policy determine the overall result of the policy. There are several rule combining algorithms defined in XACML (custom ones may be defined). Brief descriptions are listed below. For the official definitions, see the XACML specifications.

In all cases, if none of the rules apply, the policy does not apply.

First Applicable
The effect of the first rule that applies is the decision of the policy. The rules must be evaluated in the order that they are listed in the policy.

Only One Applicable
Only one rule will be applicable (an error occurs otherwise). The effect of the applicable rule is the decision of the policy.

Deny Overrides
If any rule denies access, the policy denies access.

Ordered Deny Overrides
This algorithm is identical to Deny Overrides except that it requires that the rules in a policy be evalutated in the order that they are listed in the policy.

Permit Overrides
If any rule permits access, the policy permits access.

Ordered Permit Overrides
This algorithm is identical to Permit Overrides except that it requires that the rules in a policy be evalutated in the order that they are listed in the policy.

> **Note**
>
> Sun's XACML Implementation (the XACML implementation used in eXist) currently treats the ordered and unordered variants identically.

### Policy Summary

To summarize the contents of a Policy, a Policy contains a Target and Rules. A Rule contains a Target and a Condition. A Rule applies to a request if both its Target and Condition match the request. A Policy applies to a request if its Target matches the request and at least one of its Rules applies to the request. The decision of an applicable Policy is the result of applying its rule-combining algorithm to its Rules.

## Sun's XACML Implementation

As the section title suggests, Sun developed an implementation of XACML in Java called Sun's XACML Implementation. It is open source and is hosted at SourceForge: <http://sunxacml.sourceforge.net/>. eXist uses this implementation to construct and evaluate access requests according to the policies provided by the database administrator. In general, you don't need to know much about Sun's implementation unless you want to use XACML outside of eXist. That is, if you will be enforcing policies in your application and making your own requests. The Policy Decision Point (PDP) in Sun's implementation should theoretically be a black box to which you provide policies, eXist provides an access request, and it tells you if that access is allowed.

> **Note**
>
> eXist uses version 1.2 of sunxacml. This is the latest official release, supporting XACML 1.0/1.1. More recent CVS versions are supporting more and more of XACML 2.0. When a new release of sunxacml is made we will likely look into upgrading so that XACML 2.0 and its improvements are supported.

Sun, Sun Microsystems, and Java are trademarks or registered trademarks of Sun Microsystems, Inc. in the U.S. and other countries.
