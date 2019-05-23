# eXist-db Documentation
[![Build Status](https://travis-ci.com/eXist-db/documentation.svg?branch=master)](https://travis-ci.com/eXist-db/documentation)
[![Docbook version](https://img.shields.io/badge/docbook-5.0-19a5a4.svg)](http://docbook.org/xml/5.0/)
[![eXist-db version](https://img.shields.io/badge/eXist_db-4.7.0-blue.svg)](http://www.exist-db.org/exist/apps/homepage/index.html)

<img src="src/main/xar-resources/icon.png" align="left" width="15%"/>

This repository contains the official documentation for the [eXist-db native XML database](http://www.exist-db.org) and the application for browsing it. You can browse the latest release of the documentation on [eXist-db homepage](http://exist-db.org/exist/apps/doc/). User reporting errors should check the [contributions](#contributions) section below. Core-contributors preparing a release should consult the [release procedure](RELEASE.md)

## Dependencies
-   [Maven](https://maven.apache.org): 3.x
-   [eXist-db](http://exist-db.org): 4.7.0

## Installation
-   The default eXist-db installer includes the documentation app. Just go to your eXist server's Dashboard and select Documentation.
-   If you need to install an older version, you can download EXPath Application Packages (`.xar` files) of previous [releases](https://github.com/eXist-db/documentation/releases) from GitHub.
-   Update to the latest release via the eXist-db package manager or via the eXist-db.org public app repository at [http://exist-db.org/exist/apps/public-repo/](http://exist-db.org/exist/apps/public-repo/).

## Contributions
Found an area of the documentation that needs to be improved? Please raise an [issue](https://github.com/eXist-db/documentation/issues) or better yet submit a [pull request](https://github.com/eXist-db/documentation/pulls)!

Before you edit the docs please take a look at our [style guide](https://www.exist-db.org/exist/apps/doc/author-reference). It should help you understand our articles structure and use of the docbook format. You can speed up the review process by running `mvn validate` on your local machine before opening a pull request. This way you can be certain that your edits won't interfere with the [automated tests](https://travis-ci.org/eXist-db/documentation) of this repo.

Should you encounter documentation for features that are deprecated in the minimum eXist-db version mentioned [above](#dependencies), you can simply delete them. If you are unsure about this, please open an [issue](https://github.com/eXist-db/documentation/issues).

## Building from source
1.  Clone the repository to your system:
    ```bash
    $ git clone https://github.com/exist-db/documentation.git
    ```

2.  Build the documentation application:
    ```bash
    $ cd documentation
    $ mvn clean package
    ```
    The compiled `.xar` file is located in the `/target` directory

3.  Install this file via the Dashboard > Package Manager.

## (WIP) Testing

### Unit tests
The full test-suite consists of validation, unit, and integration tests, it runs automatically on travis. To be able to run integration tests locally, contributors should run `npm i` to download and install [cypress.js](https://www.cypress.io). This is only required once. To execute the tests run the following commands:          
-   To validate xml files run `mvn validate`,
-   to run the javascript tests `mvn test` (xQsuite coming soon). We do **not** support testing via node alone, aka `npm test`, use the maven command instead.
-   To run the Integrations tests, however, use `npm run cypress`.

Both unit and integration tests, expect a running instance of exist with a copy of the documentation app installed reachable at `localhost:8080` and an empty admin password. It might be necessary to skip test execution during building from time to time, use: `mvn clean package -DskipTests`.

You can view recordings of the previous integration test runs on our [Cypress Dashboard](https://dashboard.cypress.io/#/projects/h8zx19/runs)

## License
LGPLv2.1 [eXist-db.org](http://exist-db.org/exist/apps/homepage/index.html)
