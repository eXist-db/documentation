# Getting Help: How to report issues

## Introduction

When a (potential) bug is reported, please include as much of the information as described below. When more information is provided, it is more easy for the developers to understand and reproduce the issue, which means that the issue can be picked-up and solved much faster.

## General information

> **Note**
>
> When reporting a (suspected) bug please make the report as complete as possible:
>
> -   Try to write a clear (and short) description how to reproduce the problem
>
> -   Include the exact version (and revision), e.g. "1.4.3" (rev1234) or "2.1".
>
> -   Always add the operating system (e.g. "Windows7 64bit"), the exact Java version as is outputted by the command 'java -version' on the console.
>
> -   Include relevant parts of the logfile (e.g. `webapp/WEB-INF/logs/exist.log` and `tools/yajsw/logs/wrapper.log`)
>
> -   Mention the changes that have been made in the configuration files, e.g. `conf.xml`, `vm.properties`, `tools/yajsw/conf/wrapper.conf` and `tools/jetty/etc/jetty.xml`.
>
## XQuery specific

> **Note**
>
> When reporting a potential XQuery bug please:
>
> -   Make the XQuery, if possible, 'self containing', meaning that the XQuery does not require any additional files to run.
>
> -   Describe the actual XQuery result and the expected result
>
> -   Check if the issue has been solved in the latest version of eXist-db; For this the web based tool [eXide](http://exist-db.org/exist/apps/eXide/index.html) can be used.
>
> -   Run the XQuery with [Kernow for Saxon](http://kernowforsaxon.sourceforge.net) and check the similarities and differences.
>
Bugs can also be reported on the [Bug Tracker](https://github.com/eXist-db/exist/issues/) where data and log files can be attached.
