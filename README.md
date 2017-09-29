eXist-db Documentation
======================

This repository contains the official documentation for the eXist-db Native XML database and the application for browsing it.

## Resources

- Browse the latest release of the documentation at http://exist-db.org/exist/apps/doc/. 
- The documentation app is included by default in the eXist-db installer. Just go to your eXist server's Dashboard and select Documentation.
- Update to the latest release via the eXist-db package manager or via the eXist-db.org public app repository at <http://exist-db.org/exist/apps/public-repo/>.

## Building from source

1. Dependencies: Maven 3.x

2. Clone the repository to your system:

```bash
$ git clone https://github.com/exist-db/documentation.git exist-documentation
```

3. Build the documentation application:
```bash
$ cd exist-documentation
$ mvn clean package
```

4. An EXPath Application Package (.xar file) is deposited in the `target` directory

5. Install this file via the Dashboard > Package Manager.

Find an area of the documentation that needs to be improved? Please raise an issue and submit a pull request!


## Building a Release from source

1. Follow the instructions from [Building from source](#building-from-source)

2. Create a Release:

```bash
$ mvn release:prepare
$ mvn release:perform
```

3. An EXPath Application Package (.xar file) is deposited in the `target` directory

4. If you are a core contributor, you should then commit and push.
