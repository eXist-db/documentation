# Access Control in eXist: XACML Developer's Guide

## Introduction

This guide provides information to developers interested in adding access control to eXist or potentially users writing applications that use eXist's internal XACML-related classes (note that this is not supported, though).

> **Note**
>
> The XACML functionality is marked as deprecated and should not be used for new projects. Please use the new [ACL](security.md#ACLs) functionality that has been introduced in eXist-db v2.0.

## Selecting XACML for Access Control

XACML is a powerful standard for controlling access to resources, but as with any technology it has advantages and disadvantages. One potential disadvantage is the learning curve required by administrators to write policies. This may be somewhat mitigated by a graphical policy editor, such as the one in eXist's graphical client. However, this takes more work on the part of the developer (although, hopefully not too much: see the section (PENDING) on adding graphical editing for new access control points). Additionally, the administrator still needs to know some general information about the concepts behind XACML. This is certainly more work than applying previous knowledge about and experience with Unix-based permissions or role-based access control.

The second potential disadvantage is performance. Currently, the support that eXist provides to the Policy Decision Point (PDP) does not include indexing policies. This means that when the PDP receives an access request, it must ask each policy if it applies to the request until a policy applies. This simple method is quite sufficient for the current use of XACML in eXist; however, more advanced methods such as indexing and perhaps intelligent caching of results might be needed for uses that involve a substantial number of access requests in a short time or uses that will likely encourage the use of many policies or large policies.

Given these two disadvantages, XACML is still a good choice for access control in many situations. It is highly flexible, it is a well designed standard, and the disadvantages can be compensated for.

TODO: Finish section

## Adding a Policy Enforcement Point (PEP)

TODO: Write section

## Generating a Request

TODO: Write section

## Interpreting a Response

TODO: Write section
