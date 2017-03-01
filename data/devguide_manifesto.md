# eXist-db Developer Manifesto

## Introduction

This document lays out guidelines for developers that are either committing directly to the eXist-db code base via the projects GitHub repository or developing externally for later incorporation into eXist-db.

## Communication

Communication between developers and within Open Source projects can be a hard thing to achieve effectively, but to ensure the success of the project and contributions, we must all strive to improve on communicating our intentions.

Public and open discussion of all new features and changes to existing features MUST always be undertaken. eXist-db is a community project and the community must be invited to provide input and feedback on development. Development discussion should take place through the [eXist-db Development mailing list](http://sourceforge.net/mail/?group_id=17691).

If conflicts of interest occur during discussion, they must be resolved before any code changes are made. If conflicts cannot be resolved by the community, one of the core maintainers may act as a moderator. Maintainers are contributors who feel responsible for the project as a whole and have shown it in the past through their commitment and support. Right now this includes: Pierrick Brihaye, Wolfgang Meier, Leif-Jöran Olsson, Adam Retter and Dannes Wessels. We name those people, so you know who to talk to, but the list is in no way exclusive and may change over time.

## Maintainability

All code accepted to the project must be maintainable otherwise there is the possibility that it will grow stale and without maintainers will be removed from the code base.

To ensure a happy future for the code base each contributor has a responsibility to ensure:

-   New code and bug-fixes *must* be accompanied by JUnit/XQuery/XSpec test cases. This helps us understand intention and avoid regressions.

-   Code should be appropriately commented (including javadoc/xqdoc) so that intention is understood. Industry standard code formatting rules should be followed. This helps us read and understand contributions.

-   Code must be appropriately with the developers name and current email address. This helps us contact contributors/maintainers should issues arrive.

-   Consider the maintainability of new features, will you maintain and support them over years? If not, who will and how do you communicate what is required?

## Developing

-   Follow Industry Standard coding conventions.

-   eXist-db is now developed atop Sun Java 8, so make use of Java 8 features for cleaner, safer and more efficient code.

-   New Features *must* be generic and applicable to an audience of more than one or two. Consider whether the eXist-db community would see this as a valuable feature; You should have already discussed this via the eXist-db Development mailing list! If a feature is just for you and/or your customer, it may have no place in the eXist-db main code base.

-   Major new features or risky changes must be developed in their own branch. Once they have been tested (should include some user testing) they may then be integrated back into the main code base.

-   Follow a RISC like approach to developing new functions. It is better to have a single function that is flexible than multiple function signatures for the same function. Likewise, do not replace two functions by offering one new super function. Functions should act like simple building blocks that can be combined together.

-   The use of Static Analysis tools is highly recommended, these bring value by reducing risk, and are even valuable to the most highly skilled developers. Such tools include [Checkstyle](http://checkstyle.sourceforge.net), [FindBugs](http://findbugs.sourceforge.net) and [PMD](http://pmd.sourceforge.net/).

## Before Committing

-   *TEST, TEST and TEST again!* See last section how to do this.

-   Execute the JUnit test suite to ensure that there are no regressions, if there are regressions then do not commit!

-   Execute the XQTS test suite to ensure that there are no regressions, if there are regressions then do not commit!

-   If you are working in an area of performance, there is also a Benchmark test suite that you should run to ensure performance.

-   When effecting major changes, make sure all the demo applications which ship with eXist-db are still working as expected. Testing of the main user interfaces including Java WebStart client and WebDAV helps to avoid surprises at release time.

-   Documentation, whilst often overlooked this is critical to getting users to accept and test any new feature. If you add features without documentation they are worthless to the community.

-   Atomicity! Please consider how you group your commits together. A feature should be contributed as an atomic commit, this enables co-developers to easily follow and test the feature. During development if you need to clean existing code up, please commit this at the time labelled as 'cleaning up', this makes your final commit much more concise.

-   Very large commits. If possible, without breaking existing functionality, it can be useful to break very large commits up into a few smaller atomic commits spanning a couple of days. This allows other users to test and help identify any parts of your code which might introduce issues.

-   Commit tagging, helps us to generate lists of what has changed been releases. Please prefix your commit messages with an appropriate tag:

    -   \[bugfix\]

    -   \[lib-change\]

    -   \[feature\]

    -   \[ignore\]

    -   \[format-change\]

    -   \[documentation\]

    -   \[documentation-fix\]

    -   \[performance\]

    -   \[testsuite\]

    -   \[building\]

    The change log scripts will ignore any messages which do not start with one of the tags above or whose tag is \[ignore\].

## Finally

Open Source projects are not a democracy, although they are not far from that. Breaking, unknown and untested commits cause a lot of pain and lost hours to your fellow developers.

Whilst we of course wish to encourage and nurture contributions to the project, these have to happen in a manner that everyone involved in the project can cope with. However, as an absolute last measure, if developers frequently fail to adhere to the Manifesto then Commit access to the eXist-db repository could be revoked by the core developers.

## Appendix: How to enable all and test

It is essential that none of the existing code breaks because of your commit. Here is how to be sure all code can be built and tested:

1.  Edit `conf.xml` (or actually the original file `conf.xml.tmpl`)

    1.  Uncomment all (really, all) builtin-modules under xpath `/exist/xquery/builtin-modules`

    2.  Activate the spatial index by uncomment the index-module "spatial-index" under xpath `/exist/indexer/modules` (the corresponding function module is uncommented by the first step.

2.  Edit `
                                    
                                        local
                                    .build.properties`, switch-on all modules

    1.  The Oracle module can be switched to false, the required jar is a bit difficult to download

    2.  Switch all on modules on with the command cat build.properties | sed 's/false/true/g' &gt; local.build.properties
