# Release Procedure
Core-contributors should follow these steps when publishing a new release of the documentation app.  

## Local Environment Checks
-   maven requires a valid gpg key associated with your GitHub account to publish a new release, to check your available keys:
```bash
gpg --list-keys
```

-  maven also requires a nexus account. You can create one at [oss.sonatype.org](https://oss.sonatype.org/#welcome) and include your credentials in your maven's `settings.xml` (replacing username and password):

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <servers>
    <server>
      <id>sonatype-nexus-snapshots</id>
      <username>USERNAME</username>
      <password>PASSWORD</password>
    </server>
    <server>
      <id>sonatype-nexus-staging</id>
      <username>USERNAME</username>
      <password>PASSWORD</password>
    </server>
  </servers>
</settings>
```


-   You can perform a dry-run of the release procedure by executing
```bash
$ mvn -DdryRun=true release:prepare
```
-   Dry-runs still create files that will interfere with regular releases. You should therefore clean up afterwards by running:
```bash
$ mvn release:rollback
```


## Preparing the Release Commit
1.  Merge outstanding and reviewed PRs.

2.  Set the `exist.version` in  `pom.xml` to prevent users of older exist releases, from installing the wrong documentation locally. Since the canonical version needs to run on exist-db.org please make sure that the main server can actually run the latest documentation, and raise an issue if necessary.

3.  To generate the release notes run:
```bash
$ mvn site
```

this will generate a `github-report.html` in `target/site` you can copy the list of changes into `xar-assembly.xml` describing which articles changed and how.

## Building the Release
4.  Follow the instructions from [Building from source](README.md#building-from-source)

5.  To create a release run:
```bash
$ mvn release:prepare
$ mvn release:perform
```

When prompted to pick a version number for the release, remember to mirror the [major version](https://github.com/eXist-db/exist/blob/develop/exist-versioning-release.md#versioning-scheme) of the current eXist-db release. So for exist-db version `3.x.x` the documentation's version should be `3.y.y`. The minor and patch numbers remain independent of each other.

You can find the EXPath Application Package (`.xar` file) for the release in the `/target` directory

## Publishing the Release
Release are published in two locations:

6.  GitHub: Repo and [releases](https://github.com/eXist-db/documentation/releases)
    -   commit and push as usual
    -   maven should have automatically created a release tag, update it by copying the release notes from `xar-assembly.xml`
    -   check to make sure that the latest `.xar` file is attached to the GitHub release

7.  [exist-db.org](http://exist-db.org): App repo and documentation homepage
    -   Inform the exist-db.org admins that the documentation app should be deployed on the server.
    -   Add documentation app to the public application repository.
