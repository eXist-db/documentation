# Access Control in eXist

## XACML

eXist uses the OASIS standard [eXtensible Access Control Markup Language (XACML)](http://www.oasis-open.org/committees/tc_home.php?wg_abbrev=xacml) for XQuery access control. XACML [1.1](http://www.oasis-open.org/committees/tc_home.php?wg_abbrev=xacml#XACML11) and [1.0](http://www.oasis-open.org/committees/tc_home.php?wg_abbrev=xacml#XACML10) are currently supported.

> **Note**
>
> The XACML functionality is marked as deprecated and should not be used for new projects. Please use the new [ACL](security.xml#ACLs) functionality that has been introduced in eXist-db v2.0.

This documentation is divided into four parts. The first part of this documentation, [Capabilities](xacml-features.md), is intended to be a thorough overview of what in eXist is controlled using XACML. This part does not require prior knowledge of XACML and should provide the database administrator with enough information to decide whether to enable and use eXist's XACML subsystem.

The second part, [Introduction to XACML](xacml-intro.md), is a brief introduction to XACML. The targeted level of detail is the level necessary to use eXist's policy editor to manage policies (policies are how access is restricted in XACML). It also provides some background information on the XACML implementation library used by eXist.

The third part, [Using XACML in eXist](xacml-usage.md) includes a short description of how to configure the XACML subsystem in eXist. This covers enabling XACML, the location of policies, and the default behavior of the XACML subsystem. This part then describes how to create, edit, and remove policies in eXist using the graphical editor.

The last part of the documentation, [XACML Developer's Guide](xacml-dev.md), is targeted towards eXist developers and describes how to implement a Policy Enforcement Point (PEP) in eXist, among other topics.

A basic description of the operation of access control using XACML in eXist is the that database administrator writes policies (either manually or with the graphical editor) that determine who can access what resources and when and how those resources can be accessed. When an XQuery is executed (or some other controlled resource is accessed), eXist asks Sun's XACML Implementation if that action is permitted according to the provided policies. If access is denied, a PermissionDeniedException is thrown. If it is granted, program execution continues normally.
