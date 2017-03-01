# XML Validation

## Introduction

eXist-db supports implicit and explicit validation of XML documents. Implicit validation can be executed automatically when documents are being inserted into the database, explicit validation can be performed through the use of provided XQuery extension functions.

## Implicit validation

To enable implicit validation, the eXist-db configuration must be changed by editing the file `conf.xml`. The following items must be configured:

-   Validation mode

-   Catalog Entity Resolver

### Validation mode

        <validation mode="auto">
            <entity-resolver>
                <catalog uri="${WEBAPP_HOME}/WEB-INF/catalog.xml" />
            </entity-resolver>
        </validation>

With the parameter *mode* it is possible to switch on/off the validation capabilities of the (Xerces) XML parser. The possible values are:

#### yes

Switch on validation. All XML documents will be validated. Note - If the grammar (XML schema, DTD) document(s) cannot be resolved, the XML document is rejected.

#### no (default)

Switch off validation. No grammar validation is performed and all well-formed XML documents will be accepted.

#### auto

Validation of an XML document will be performed based on the content of the document. When a document contains a reference to a grammar (*XML schema* or *DTD*) document, the XML parser tries to resolve this grammar and the XML document will be validated against this grammar, just like *mode="yes"* is configured. Again, if the grammar cannot be resolved, the XML document will be rejected. When the XML document does not contain a reference to a grammar, it will be parsed like *mode="no"* is configured.

### Catalog Entity Resolver

All grammars (XML schema, DTD) that are used for implicit validation must be registered with eXist using [OASIS catalog](http://www.oasis-open.org/committees/download.php/14809/xml-catalogs.html) files. These catalog files can be stored on disk and/or in the database itself. In eXist the actual resolving is performed by the apache [xml-commons resolver](http://xml.apache.org/commons/components/resolver/) library.

It is possible to configure any number of catalog entries in the entity-resolver section of conf.xml . The relative "uri="s are resolved relative to the location of the catalog document.

        <validation mode="auto">
            <entity-resolver>
                <catalog uri="xmldb:exist:///db/grammar/catalog.xml" />
                <catalog uri="${WEBAPP_HOME}/WEB-INF/catalog.xml" />
            </entity-resolver>
        </validation>

A catalog stored in the database can be addressed by a URL like '**xmldb:exist:///db/mycollection/catalog.xml**' (note the 3 leading slashes which imply localhost) or the shorter equivalent '/db/mycollection/catalog.xml'.

In the preceeding example **${WEBAPP\_HOME}** is substituted by a *file://* URL pointing to the 'webapp'-directory of eXist (e.g. '**$EXIST\_HOME/webapp/**') or the equivalent directory of a deployed WAR file when eXist is deployed in a servlet container (e.g. '**${CATALINA\_HOME}/webapps/exist/**')

        <?xml version="1.0" encoding="UTF-8"?>
        <catalog xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog">
            <public publicId="-//PLAY//EN" uri="entities/play.dtd"/>
            <system systemId="play.dtd" uri="entities/play.dtd"/>
            <system systemId="mondial.dtd" uri="entities/mondial.dtd"/>    
            
            <uri name="http://exist-db.org/samples/shakespeare" uri="entities/play.xsd"/>
            
            <uri name="http://www.w3.org/XML/1998/namespace" uri="entities/xml.xsd"/>
            <uri name="http://www.w3.org/2001/XMLSchema" uri="entities/XMLSchema.xsd"/>
        
            <uri name="urn:oasis:names:tc:entity:xmlns:xml:catalog" uri="entities/catalog.xsd" />
        </catalog>

### Collection configuration

Within the database the validation mode for each individal collection can be configured using *collection.xconf* documents, in the same way these are used for configuring [indexes](indexing.md). These documents need to be stored in '/db/system/config/db/....'.

    <?xml version='1.0'?>
    <collection xmlns="http://exist-db.org/collection-config/1.0">
        <validation mode="no"/>
    </collection>

This example xconf file turns the implicit validation off.

## Explicit validation

Extension functions for validating XML in an XQuery script are provided. Starting with eXist-db release 1.4 the following validation options are provided:

-   JAXP

-   JAXV

-   Jing

Each of these options are discussed in the following sections. Consult the [XQuery Function Documentation]({fundocs}/view.html?uri=http://exist-db.org/xquery/validation) for detailed functions descriptions.

### JAXP

The JAXP validation functions are based on the validation capabilities of the [javax.xml.parsers](http://java.sun.com/j2se/1.5.0/docs/api/javax/xml/parsers/package-summary.html) API. The actual validation is performed by the [Xerces2](http://xerces.apache.org/xerces2-j/) library.

When parsing an XML document a reference to a grammar (either DTDs or XSDs) is found, then the parser attempts resolve the grammar reference by following either the XSD xsi:schemaLocation, xsi:noNamespaceSchemaLocation hints, the DTD DOCTYPE SYSTEM information, or by outsourcing the retrieval of the grammars to an Xml Catalog resolver. The resolver identifies XSDs by the (target)namespace, DTDs are identified by the PublicId.

Validation performance is increased through grammar caching; the cached compiled grammars are shared by the implicit validation feature.

The jaxp() and jaxp-report() functions accept the following parameters:

$instance  
The XML instance document, referenced as document node (returned by fn:doc()), element node, xs:anyURI or as Java file object.

$cache-grammars  
Set this to true() to enable grammar caching.

$catalogs  
One or more OASIS catalog files referenced as xs:anyURI. Depending on the xs:anyURI a different resolver will be used:

-   When an empty sequence is set, the catalog files defined in conf.xml are used.

-   If the URI ends with ".xml" the specified catalog is used.

-   If the URI points to a collection (when the URL ends with "/") the grammar files are searched in the database using an xquery. XSDs are found by their targetNamespace attributes, DTDs are found by their publicId entries in catalog files.

### JAXV

The JAXV validation functions are based on the [java.xml.validation](http://java.sun.com/j2se/1.5.0/docs/api/javax/xml/validation/package-summary.html) API which has been introduced in Java 5 to provide a schema-language-independent interface to validation services. Although officially the specification allows use of additional schema languages, only XML schemas can be really used so far.

The jaxv() and jaxv-report() functions accept the following parameters:

$instance  
The XML instance document, referenced as document node (returned by fn:doc()), element node, xs:anyURI or as Java file object.

$grammars  
One or more grammar files, referenced as document nodes (returned by fn:doc()), element nodes, xs:anyURI or as Java file objects.

### Jing

The Jing validation functions are based on James Clark's [Jing](http://www.thaiopensource.com/relaxng/jing.html) library. eXist uses the maintained version that is available via [Google Code](http://code.google.com/p/jing-trang/). The library relies on the [com.thaiopensource.validate.ValidationDriver](http://www.thaiopensource.com/relaxng/api/jing/com/thaiopensource/validate/ValidationDriver.html) which supports a wide range of grammar types:

-   XML schema (.xsd)

-   Namespace-based Validation Dispatching Language (.nvdl)

-   RelaxNG (.rng and .rnc)

-   Schematron 1.5 (.sch)

The jing() and jing-report() functions accept the following parameters:

$instance  
The XML instance document, referenced as document node (returned by fn:doc()), element node, xs:anyURI or as Java file object.

$grammar  
The grammar file, referenced as document node (returned by fn:doc()), element node, as xs:anyURI, binary document (returned by util:binary-doc() for RNC files) or as Java file object.

## Validation report

The validation report contains the following information:

        <?xml version='1.0'?>
        <report>
            <status>valid</status>
            <namespace>MyNameSpace</namespace>
            <duration unit="msec">106</duration>
        </report>

        <?xml version='1.0'?>
        <report>
            <status>invalid</status>
            <namespace>MyNameSpace</namespace>
            <duration unit="msec">39</duration>
            <message level="Error" line="3" column="20">cvc-datatype-valid.1.2.1: 'aaaaaaaa' is not a valid value for 'decimal'.</message>
            <message level="Error" line="3" column="20">cvc-type.3.1.3: The value 'aaaaaaaa' of element 'c' is not valid.</message>
        </report>

        <?xml version='1.0'?>
        <report>
            <status>invalid</status>
            <duration unit="msec">2</duration>
            <exception>
                <class>java.net.MalformedURLException</class>
                <message>unknown protocol: foo</message>
                <stacktrace>java.net.MalformedURLException: unknown protocol: foo 
                at java.net.URL.<init>(URL.java:574) 
                at java.net.URL.<init>(URL.java:464) 
                at java.net.URL.<init>(URL.java:413) 
                at org.exist.xquery.functions.validation.Shared.getStreamSource(Shared.java:140) 
                at org.exist.xquery.functions.validation.Shared.getInputSource(Shared.java:190) 
                at org.exist.xquery.functions.validation.Parse.eval(Parse.java:179) 
                at org.exist.xquery.BasicFunction.eval(BasicFunction.java:68) 
                at ......
                </stacktrace>
            </exception>
        </report>

## Grammar management

The XML parser (Xerces) compiles all grammar files (dtd, xsd) upon first use. For efficiency reasons these compiled grammars are cached and made available for reuse, resulting in a significant increase of validation processing performance. However, under certain circumstances (e.g. grammar development) it may be desirable to manually clear this cache, for this purpose two grammar management functions are provided:

-   *clear-grammar-cache()* : removes all cached grammar and returns the number of removed grammar

-   *pre-parse-grammar(xs:anyURI)* : parses the referenced grammar and returns the namespace of the parsed XSD.

-   *show-grammar-cache()* : returns an XML report about all cached grammar

<!-- -->

        <?xml version='1.0'?>
        <report>
        <grammar type="http://www.w3.org/2001/XMLSchema">
            <Namespace>http://www.w3.org/XML/1998/namespace</Namespace>
            <BaseSystemId>file:/Users/guest/existdb/trunk/webapp//WEB-INF/entities/XMLSchema.xsd</BaseSystemId>
            <LiteralSystemId>http://www.w3.org/2001/xml.xsd</LiteralSystemId>
            <ExpandedSystemId>http://www.w3.org/2001/xml.xsd</ExpandedSystemId>
        </grammar>
        <grammar type="http://www.w3.org/2001/XMLSchema">
            <Namespace>http://www.w3.org/2001/XMLSchema</Namespace>
            <BaseSystemId>file:/Users/guest/existdb/trunk/schema/collection.xconf.xsd</BaseSystemId>
        </grammar>
        </report>

Note: the element *BaseSystemId* typically does not provide usefull information.

## Interactive Client

The interactive shell mode of the [Java Admin Client](java-admin-client.md) provides a simple *validate* command that accepts the similar explicit validation arguments.

## Special notes

-   Tomcat has an long standing bug which makes it impossible to register a custom [protocol handler](http://java.sun.com/developer/onlineTraining/protocolhandlers/) (object [URLStreamHandler](http://java.sun.com/j2se/1.5.0/docs/api/java/net/URLStreamHandler.html)) to the JVM. The alternative is to register the object by setting the system property `java.protocol.handler.pkgs` but this fails as well.

    As a result the validation features are only partly useable in tomcat. There are two altenatives: (1) switch to a recent version of Jetty, or (2) use absolute URLs pointing the the REST interface, e.g. `http://localhost:8080/exist/rest/db/mycollection/schema.xsd`.

-   eXist relies heavily on features provided by the Xerces XML parser. Out of the box the eXist izPack installer provides all required jar files. However, when eXist is installed in e.g. Tomcat the required parser libraries need to be copied manually from the eXist lib/endorsed directory into the server '[endorsed](http://tomcat.apache.org/tomcat-5.5-doc/class-loader-howto.html)' directory.

    Required endorsed files: resolver-\*.jar xalan-\*.jar serializer-\*.jar xercesImpl-\*.jar

-   To avoid potential deadlocking it is considered good practice to store XML instance documents and grammar documents in separate collections.

-   The explicit validation is performed by [Xerces](http://xerces.apache.org/xerces2-j/javadocs/api/javax/xml/validation/package-summary.html) (XML schema, DTD) and by [oNVDL](http://www.oxygenxml.com/onvdl.html) - oXygen XML NVDL implementation based on Jing (XSD, RelaxNG, Schematron and Namespace-based Validation Dispatching Language)

## References

-   Apache [xml-commons resolver](http://xml.apache.org/commons/components/resolver/)

-   OASIS [XML Catalog Specification](http://www.oasis-open.org/committees/entity/) V1.1

-   Xerces [caching grammars](http://xerces.apache.org/xerces2-j/faq-grammars.html).

-   [jing-trang](http://code.google.com/p/jing-trang/) Schema validation and conversion based on RELAX NG

-   [NVDL](http://en.wikipedia.org/wiki/Namespace-based_Validation_Dispatching_Language) (Namespace-based Validation Dispatching Language)

-   [Schematron](http://en.wikipedia.org/wiki/Schematron)

-   [Relax NG](http://en.wikipedia.org/wiki/RELAX_NG)
