# eXist-db Documentation
[![Build Status](https://travis-ci.org/eXist-db/documentation.svg?branch=master)](https://travis-ci.org/eXist-db/documentation)
[![Docbook version](https://img.shields.io/badge/docbook-4.5-19a5a4.svg)](http://docbook.org/xml/4.5/)
[![eXist-db version](https://img.shields.io/badge/eXist_db-3.5.0-blue.svg)](http://www.exist-db.org/exist/apps/homepage/index.html)

<img src="src/main/xar-resources/icon.png" align="left" width="15%"/>

This repository contains the official documentation for the [eXist-db native XML database](http://www.exist-db.org) and the application for browsing it. You can browse the latest release of the documentation on [eXist-db homepage](http://exist-db.org/exist/apps/doc/). User reporting errors should check the [contributions](#contributions) section below. Core-contributors preparing a release should consult the [release procedure](RELEASE.md)


## Dependencies
-   [Maven](https://maven.apache.org): 3.x
-   [eXist-db](http://exist-db.org): 3.5.0

## Installation
-   The default eXist-db installer includes the documentation app. Just go to your eXist server's Dashboard and select Documentation.
-   If you need to install an older version, you can download EXPath Application Packages (`.xar` files) of previous [releases](https://github.com/eXist-db/documentation/releases) from GitHub.
-   Update to the latest release via the eXist-db package manager or via the eXist-db.org public app repository at [http://exist-db.org/exist/apps/public-repo/](http://exist-db.org/exist/apps/public-repo/).

## Contributions
Found an area of the documentation that needs to be improved? Please raise an [issue](https://github.com/eXist-db/documentation/issues) or better yet submit a [pull request](https://github.com/eXist-db/documentation/pulls)!

Our test-suite performs a validation check on all articles when you open a pull request. You can speed up the review process by running `mvn validate` locally before submitting a pull request.

## Building from source
1.  Clone the repository to your system:
    ```bash
    $ git clone https://github.com/exist-db/documentation.git exist-documentation
    ```

2.  Build the documentation application:
    ```bash
    $ cd exist-documentation
    $ mvn clean package
    ```
    The compiled `.xar` file is located in the `/target` directory

3.  Install this file via the Dashboard > Package Manager.

## License
LGPLv2.1 [eXist-db.org](http://exist-db.org/exist/apps/homepage/index.html)
