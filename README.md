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

Find an area of the documentation that needs to be improved? Please raise an [issue](https://github.com/eXist-db/documentation/issues) or better yet submit a [pull request](https://github.com/eXist-db/documentation/pulls)!

Our test-suite performs a validation check on all articles when you open a pull request. You can speed up the review process by using `mvn validate` locally before submitting a pull request.


## Building a Release from source

1.  Merge outstanding and reviewed PRs.

2.  Set version numbers in `pom.xml`.
    2.  The major version of the documentation app mirrors the [major version](https://github.com/eXist-db/exist/blob/develop/exist-versioning-release.md#versioning-scheme) of the current eXist-db release. So for exist-db version `3.x.x` the documentation's version should be `3.y.y`. Minor and Patch numbers can vary between the two.
    3.  You should also check and set the appropriate `exist.version` to prevent users of older exist releases, from installing the wrong documentation locally.

3.  Edit the release notes in `xar-assembly.xml` describing which article changed and how.

2.  Follow the instructions from [Building from source](#building-from-source)

3.  Create a Release:
```bash
$ mvn release:prepare
$ mvn release:perform
```
This will create an EXPath Application Package (.xar file) in the `/target` directory

5.  If you are a core contributor, you should then commit and push.

    This  automatically increments the version number in the  master branch to the next `-SNAPSHOT`.

6.  Check [GitHub releases](https://github.com/eXist-db/documentation/releases)
    1.  The compiled .xar file of the stable release should have been  uploaded for archiving.

    2.  Copy the release notes from `xar-assembly.xml` to the GitHub release.  

8.  Inform the exist-db.org admins that the documentation app should be released in the application repository and deployed on the server.
