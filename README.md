# eXist-db Documentation
[![Build Status](https://travis-ci.org/eXist-db/documentation.svg?branch=master)](https://travis-ci.org/eXist-db/documentation)
[![docbook version](https://img.shields.io/badge/docbook-4.5-blue.svg)](http://docbook.org/xml/4.5/)

This repository contains the official documentation for the eXist-db Native XML database and the application for browsing it.

## Resources
-   Browse the latest release of the documentation at [http://exist-db.org/exist/apps/doc/](http://exist-db.org/exist/apps/doc/).
-   The documentation app is included by default in the eXist-db installer. Just go to your eXist server's Dashboard and select Documentation.
-   Update to the latest release via the eXist-db package manager or via the eXist-db.org public app repository at <http://exist-db.org/exist/apps/public-repo/>.

## Building from source
1.  Dependencies: Maven 3.x

2.  Clone the repository to your system:
```bash
$ git clone https://github.com/exist-db/documentation.git exist-documentation
```

3.  Build the documentation application:
```bash
$ cd exist-documentation
$ mvn clean package
```

4.  An EXPath Application Package (.xar file) is deposited in the `target` directory

5.  Install this file via the Dashboard > Package Manager.


## Contributions
Found an area of the documentation that needs to be improved? Please raise an [issue](https://github.com/eXist-db/documentation/issues) or better yet submit a [pull request](https://github.com/eXist-db/documentation/pulls)!

Our test-suite performs a validation check on all articles when you open a pull request. You can speed up the review process by using `mvn validate` locally before submitting a pull request.

## Building a Release from source
1.  Merge outstanding and reviewed PRs.

2.  Set the `exist.version` in  `pom.xml` to prevent users of older exist releases, from installing the wrong documentation locally.

3.  Edit the release notes in `xar-assembly.xml` describing which article changed and how.

4.  Follow the instructions from [Building from source](#building-from-source)

5.  Create a Release:
```bash
$ mvn release:prepare
$ mvn release:perform
```

When prompted to pick a version number for the release, remember to mirror the [major version](https://github.com/eXist-db/exist/blob/develop/exist-versioning-release.md#versioning-scheme) of the current eXist-db release. So for exist-db version 3.x.x the documentation's version should be 3.y.y. The minor and patch numbers remain independent of each other. 

You can find the EXPath Application Package (.xar file) for the release in the `/target` directory

6.  If you are a core contributor, you should then commit and push.

7.  Check [GitHub releases](https://github.com/eXist-db/documentation/releases)
    -   to see if the  compiled .xar file of the stable release was uploaded for archiving.
    -   to copy the release notes from `xar-assembly.xml` to the GitHub release.  

8.  Inform the exist-db.org admins that the documentation app should be released in the application repository and deployed on the server.
