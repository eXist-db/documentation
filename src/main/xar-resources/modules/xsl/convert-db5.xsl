

<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:db5sup="http://exist.sourceforge.net/NS/exist/db5-support"
  xmlns:db5="http://docbook.org/ns/docbook"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:local="#local.mlz_2hz_lcb"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  version="2.0"
  exclude-result-prefixes="#all">
  <!-- ================================================================== -->
  <!-- Stylesheet that transforms Docbook 5 to HTML for use by the eXist documentation app. -->
  <!-- ================================================================== -->
  <!-- SETUP: -->

  <xsl:output method="xml" indent="no" encoding="UTF-8"/>

  <xsl:include href="convert-db5-lib.xsl"/>

  <!-- ================================================================== -->
  <!-- PARAMETERS: -->

  <xsl:param name="uri-relative-from-app" as="xs:string" required="yes"/>
  <xsl:param name="uri-relative-from-document" as="xs:string" required="yes"/>

  <!-- ================================================================== -->
  <!-- MAIN TEMPLATES: -->

  <xsl:template match="/">
    <xsl:apply-templates select="/*/contents/node()"/>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="/*/contents/node()">
    <article>

      <!-- Header with title etc. -->
      <xsl:for-each select="db5:info[1]">
        <h1 class="front-title">
          <xsl:value-of select="(db5:title, '?NO TITLE?')[1]"/>
        </h1>

        <xsl:if test="normalize-space(db5:date) ne ''">
          <p>(<xsl:value-of select="db5:date"/>)</p>
        </xsl:if>
        <br/>
      </xsl:for-each>

      <!-- Contents -->
      <xsl:call-template name="process-block-contents">
        <xsl:with-param name="block-elements" select="db5:* except db5:info"/>
      </xsl:call-template>

    </article>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- BLOCK CONTENTS: -->

  <xsl:template name="process-block-contents">
    <xsl:param name="block-elements" as="element()*" required="yes"/>
    <xsl:apply-templates select="$block-elements" mode="mode-process-block-contents"/>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:sect1 | db5:sect2 | db5:sect3" mode="mode-process-block-contents">

    <xsl:variable name="level" as="xs:integer" select="xs:integer(substring-after(local-name(.), 'sect'))"/>
    <section>

      <xsl:element name="h{$level + 1}">
        <xsl:call-template name="do-anchor"/>
        <!-- No markup processing in titles... -->
        <xsl:value-of select="db5:title"/>
      </xsl:element>

      <xsl:apply-templates select="db5:* except db5:title" mode="#current"/>
    </section>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:para" mode="mode-process-block-contents">
    <p>
      <xsl:call-template name="do-anchor"/>
      <xsl:call-template name="process-inline-contents">
        <xsl:with-param name="nodes" select="node()"/>
      </xsl:call-template>
    </p>

    <!-- Check for index: -->
    <xsl:if test="exists(/*/index)">

      <xsl:variable name="roles" as="xs:string*" select="tokenize(string(@role), '\s+')"/>
      <xsl:variable name="indexonkeyword" as="xs:string?" select="($roles[starts-with(., 'indexonkeyword')])[1]"/>

      <xsl:choose>

        <xsl:when test="'indexontitle' = $roles">
          <xsl:call-template name="create-indexontitle"/>
        </xsl:when>

        <xsl:when test="exists($indexonkeyword)">

          <xsl:call-template name="create-indexonkeyword">
            <xsl:with-param name="keyword" select="normalize-space(substring-after($indexonkeyword, ':'))"/>
          </xsl:call-template>
        </xsl:when>

        <xsl:otherwise/>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:itemizedlist | db5:orderedlist" mode="mode-process-block-contents">
    <xsl:call-template name="do-anchor"/>
    <xsl:element name="{if (exists(self::db5:orderedlist)) then 'ol' else 'ul'}">

      <xsl:for-each select="db5:listitem">
        <li>
          <xsl:call-template name="do-anchor"/>
          <xsl:apply-templates select="db5:*" mode="#current"/>
        </li>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:variablelist" mode="mode-process-block-contents">

    <xsl:variable name="spacing" as="xs:string" select="normalize-space((@spacing, 'normal')[1])"/>
    <xsl:call-template name="do-anchor"/>
    <dl class="row {if ($spacing = 'normal') then 'wide' else ''}">

      <xsl:for-each select="db5:varlistentry">
        <dt>
          <xsl:call-template name="do-anchor"/>
          <xsl:call-template name="process-inline-contents">
            <xsl:with-param name="nodes" select="db5:term/node()"/>
          </xsl:call-template>
        </dt>
        <dd>
          <xsl:apply-templates select="db5:listitem/db5:*" mode="#current"/>
        </dd>
      </xsl:for-each>
    </dl>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:note" mode="mode-process-block-contents">
    <div class="alert alert-success">
      <xsl:call-template name="do-anchor"/>
      <xsl:if test="exists(db5:title)">
        <h2>
          <xsl:text>Note: </xsl:text>
          <xsl:value-of select="db5:title"/>
        </h2>
      </xsl:if>

      <xsl:apply-templates select="db5:* except db5:title" mode="#current"/>
    </div>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:warning | db5:important" mode="mode-process-block-contents">
    <div class="alert alert-danger">
      <xsl:call-template name="do-anchor"/>
      <h2>
        <xsl:value-of select="concat(upper-case(substring(local-name(), 1, 1)), substring(local-name(), 2))"/>
        <xsl:text>: </xsl:text>
        <xsl:value-of select="db5:title"/>
      </h2>

      <xsl:apply-templates select="db5:* except db5:title" mode="#current"/>
    </div>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:programlisting" mode="mode-process-block-contents">
    <!-- Uses either the value of @xlink:href or the direct contents of the element. -->

    <xsl:call-template name="do-anchor"/>
    <xsl:variable name="contents" as="xs:string">
      <xsl:choose>
        <xsl:when test="exists(@xlink:href)">
          <xsl:variable name="full-internal-uri" as="xs:string" select="local:get-internal-uri(@xlink:href)"/>

          <xsl:choose>
            <xsl:when test="unparsed-text-available($full-internal-uri)">
              <xsl:sequence select="unparsed-text($full-internal-uri)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="concat('?', @xlink:href, '?')"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>

        <xsl:otherwise>
          <xsl:sequence select="string(.)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- When @language exists it is supposed to be in some language and flagged as such. If not it is supposed to be plain text. -->
    <xsl:choose>

      <xsl:when test="exists(@language)">
        <pre>
          <code class="{@language}">
            <xsl:value-of select="$contents"/>
          </code>
        </pre>
      </xsl:when>

      <xsl:otherwise>
        <pre>
          <xsl:value-of select="$contents"/>
        </pre>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:example" mode="mode-process-block-contents">
    <!-- Handled almost like an asset ref... -->

    <xsl:call-template name="do-anchor"/>
    <div class="panel">
      <figure>
        <xsl:apply-templates select="db5:* except db5:title" mode="#current"/>
        <xsl:if test="exists(db5:title)">
          <figcaption>
            <xsl:value-of select="db5:title"/>
          </figcaption>
        </xsl:if>
      </figure>
    </div>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:*" mode="mode-process-block-contents mode-process-table mode-process-figure" priority="-1000">
    <!-- Error catch all for block mode: -->
    <p style="color: red; font-weight: bold;">*** Unrecognized block element:

      <xsl:value-of select="local-name(.)"/>
    </p>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- FIGURES (BOTH INLINE AND BLOCK): -->

  <xsl:template match="db5:figure | db5:informalfigure" mode="mode-process-block-contents">

    <xsl:call-template name="do-anchor"/>
    <figure>

      <xsl:apply-templates select="db5:* except db5:title" mode="mode-process-figure">
        <xsl:with-param name="figure-title" as="xs:string" select="normalize-space(db5:title)" tunnel="yes"/>
      </xsl:apply-templates>

      <xsl:if test="exists(db5:title)">
        <figcaption>
          <xsl:value-of select="db5:title"/>
        </figcaption>
      </xsl:if>
    </figure>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:inlinemediaobject" mode="mode-process-inline-contents">

    <xsl:apply-templates select="db5:*" mode="mode-process-figure">
      <xsl:with-param name="inline" as="xs:boolean" select="true()" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:mediaobject | db5:imageobject | db5:videoobject" mode="mode-process-figure">
    <xsl:apply-templates select="db5:*" mode="#current"/>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:imagedata" mode="mode-process-figure">

    <xsl:param name="figure-title" as="xs:string?" required="no" select="()" tunnel="yes"/>

    <xsl:param name="inline" as="xs:boolean" required="no" select="false()" tunnel="yes"/>
    <img src="{local:get-full-uri(@fileref)}">

      <xsl:choose>

        <xsl:when test="$inline">
          <xsl:copy-of select="@width"/>
        </xsl:when>

        <xsl:otherwise>
          <xsl:attribute name="width" select="if (exists(@width)) then @width else '75%'"/>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:if test="string($figure-title) ne ''">

        <xsl:attribute name="title" select="$figure-title"/>

        <xsl:attribute name="alt" select="$figure-title"/>
      </xsl:if>
    </img>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- TABLES: -->

  <xsl:template match="db5:table | db5:informaltable" mode="mode-process-block-contents">

    <xsl:call-template name="do-anchor"/>
    <table class="table table-striped table-condensed">

      <xsl:apply-templates select="db5:* except db5:title" mode="mode-process-table"/>

      <xsl:if test="exists(db5:title)">
        <caption>
          <xsl:value-of select="db5:table"/>
        </caption>
      </xsl:if>
    </table>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:tgroup" mode="mode-process-table">
    <xsl:apply-templates select="db5:*" mode="#current"/>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:colspec" mode="mode-process-table">
    <col width="{@colwidth}"/>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:thead | db5:tbody" mode="mode-process-table">

    <xsl:element name="{local-name()}">
      <xsl:apply-templates select="db5:*" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:row" mode="mode-process-table">
    <tr>
      <xsl:apply-templates select="db5:*" mode="#current"/>
    </tr>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:entry" mode="mode-process-table">

    <xsl:element name="{if (exists(ancestor::db5:thead)) then 'th' else 'td'}">

      <xsl:call-template name="process-block-contents">
        <xsl:with-param name="block-elements" select="db5:*"/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- INLINE CONTENTS: -->

  <xsl:template name="process-inline-contents">

    <xsl:param name="nodes" as="node()*" required="yes"/>

    <xsl:apply-templates select="$nodes" mode="mode-process-inline-contents"/>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:emphasis" mode="mode-process-inline-contents">

    <xsl:variable name="element-name" as="xs:string">

      <xsl:choose>

        <xsl:when test="empty(@role)">
          <xsl:sequence select="'em'"/>
        </xsl:when>

        <xsl:when test="local:has-role(., 'bold')">
          <xsl:sequence select="'b'"/>
        </xsl:when>

        <xsl:when test="local:has-role(., 'italic')">
          <xsl:sequence select="'i'"/>
        </xsl:when>

        <xsl:when test="local:has-role(., 'underline')">
          <xsl:sequence select="'u'"/>
        </xsl:when>

        <xsl:otherwise>
          <xsl:sequence select="'em'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:element name="{$element-name}">
      <xsl:apply-templates mode="#current"/>
    </xsl:element>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:guimenuitem" mode="mode-process-inline-contents">
    <i>
      <xsl:apply-templates mode="#current"/>
    </i>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:code | db5:literal" mode="mode-process-inline-contents">
    <code>
      <xsl:apply-templates mode="#current"/>
    </code>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:tag" mode="mode-process-inline-contents">
    <code>
      <xsl:text>&lt;</xsl:text>

      <xsl:value-of select="."/>
      <xsl:text>&gt;</xsl:text>
    </code>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:xref" mode="mode-process-inline-contents">
    <xsl:variable name="id" as="xs:string" select="string(@linkend)"/>
    <xsl:variable name="linked-element" as="element()?" select="//*[@xml:id eq $id]"/>

    <xsl:choose>

      <xsl:when test="empty($linked-element)">
        <span style="color: red; font-weight: bold;">?<xsl:value-of select="$id"/>?</span>
      </xsl:when>

      <xsl:when test="exists($linked-element/@xreflabel)">
        <a href="#{$id}">
          <xsl:value-of select="$linked-element/@xreflabel"/>
        </a>
      </xsl:when>

      <xsl:when test="exists($linked-element/db5:title)">
        <a href="#{$id}">
          <xsl:value-of select="$linked-element/db5:title"/>
        </a>
      </xsl:when>

      <xsl:otherwise>
        <a href="#{$id}">
          <xsl:value-of select="local-name($linked-element)"/>
        </a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:link" mode="mode-process-inline-contents">
    <a href="{@xlink:href}">

      <xsl:if test="exists(@condition)">
        <xsl:attribute name="target" select="@condition"/>
      </xsl:if>

      <xsl:apply-templates mode="#current"/>
    </a>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="text()" mode="mode-process-inline-contents">
    <xsl:copy/>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="db5:*" mode="mode-process-inline-contents" priority="-1000">
    <!-- Error catch all for block mode: -->
    <span style="color: red; font-weight: bold;">*** Unrecognized inline element:

      <xsl:value-of select="local-name(.)"/>
    </span>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- INDEXES: -->

  <xsl:template name="create-indexonkeyword">
    <xsl:param name="base-element" as="element()" required="no" select="."/>
    <xsl:param name="keyword" as="xs:string" required="yes"/>

    <xsl:variable name="base-id" as="xs:string" select="generate-id($base-element)"/>
    <xsl:variable name="docs" as="element(doc)*" select="/*/index/doc"/>
    <xsl:variable name="all-keywords" as="xs:string*" select="for $kw in distinct-values($docs/db5:info/db5:keywordset/db5:keyword) return lower-case(normalize-space($kw))"/>
    <xsl:variable name="keywords-to-process" as="xs:string*">

      <xsl:choose>

        <xsl:when test="$keyword eq ''">
          <xsl:sequence select="$all-keywords"/>
        </xsl:when>

        <xsl:when test="lower-case($keyword) = $all-keywords">
          <xsl:sequence select="lower-case($keyword)"/>
        </xsl:when>

        <xsl:otherwise>
          <xsl:sequence select="()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- The code below will generate a header line with all the keywords, clickable. Probably not necessary and quit ugly. -->
    <!--<p> <xsl:for-each select="$keywords-to-process"> <a href="#{$base-id}-{.}"> <b> <xsl:value-of select="local:capitalize(.)"/> </b> </a> <xsl:text> </xsl:text> </xsl:for-each> </p>-->

    <xsl:for-each select="$keywords-to-process">
      <xsl:sort select="."/>
      <xsl:variable name="current-keyword" as="xs:string" select="."/>
      <xsl:if test="$keyword eq ''">
        <!-- Do not generate a header when we requested a specific keyword. -->
        <p>
          <a name="{$base-id}-{$current-keyword}"/>
          <b>
            <xsl:value-of select="local:capitalize($current-keyword)"/>:</b>
        </p>
      </xsl:if>
      <ul>

        <xsl:for-each select="$docs[$current-keyword = local:normalized-docs-keyword-list(.)]">
          <xsl:sort select="upper-case(normalize-space(db5:info/db5:title))"/>
          <li>
            <a href="{substring-before(tokenize(@ref, '/')[last()], '.xml')}">
              <xsl:value-of select="string(db5:info/db5:title)"/>
            </a>
          </li>
        </xsl:for-each>
      </ul>
    </xsl:for-each>

  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:function name="local:normalized-docs-keyword-list" as="xs:string*">
    <xsl:param name="docs" as="element(doc)*"/>
    <xsl:sequence select="for $kw in distinct-values($docs/db5:info/db5:keywordset/db5:keyword) return lower-case(normalize-space($kw))"/>
  </xsl:function>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template name="create-indexontitle">
    <xsl:param name="base-element" as="element()" required="no" select="."/>

    <xsl:variable name="base-id" as="xs:string" select="generate-id($base-element)"/>
    <!-- Header: -->
    <p>
      <xsl:for-each-group select="/*/index/doc" group-by="upper-case(substring(normalize-space(db5:info/db5:title), 1, 1))">
        <xsl:sort select="current-grouping-key()"/>
        <a href="#{$base-id}-{current-grouping-key()}">
          <b>
            <xsl:value-of select="current-grouping-key()"/>
          </b>
        </a>
        <xsl:text> </xsl:text>
      </xsl:for-each-group>
    </p>
    <!-- Article links: -->

    <xsl:for-each-group select="/*/index/doc" group-by="upper-case(substring(normalize-space(db5:info/db5:title), 1, 1))">
      <xsl:sort select="current-grouping-key()"/>
      <p>
        <a name="{$base-id}-{current-grouping-key()}"/>
        <b>
          <xsl:value-of select="current-grouping-key()"/>
          <xsl:text>:</xsl:text>
        </b>
      </p>
      <ul>

        <xsl:for-each select="current-group()">
          <xsl:sort select="upper-case(normalize-space(db5:info/db5:title))"/>
          <li>
            <a href="{substring-before(tokenize(@ref, '/')[last()], '.xml')}">
              <xsl:value-of select="string(db5:info/db5:title)"/>
            </a>
          </li>
        </xsl:for-each>
      </ul>
    </xsl:for-each-group>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- SUPPORT: -->

  <xsl:template match="processing-instruction() | comment()" mode="#all">
    <!-- Ignore -->
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:function name="local:get-full-uri" as="xs:string">
    <xsl:param name="uri" as="xs:string"/>
    <xsl:choose>

      <xsl:when test="contains($uri, '://')">
        <xsl:sequence select="$uri"/>
      </xsl:when>

      <xsl:when test="starts-with($uri, '/')">
        <xsl:sequence select="concat($uri-relative-from-app, $uri)"/>
      </xsl:when>

      <xsl:otherwise>
        <xsl:sequence select="concat($uri-relative-from-document, '/', $uri)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:function name="local:get-internal-uri" as="xs:string">
    <xsl:param name="uri" as="xs:string"/>
    <xsl:choose>

      <xsl:when test="starts-with($uri, '/')">
        <xsl:sequence select="concat('xmldb:exist:///db', local:get-full-uri($uri))"/>
      </xsl:when>

      <xsl:otherwise>
        <xsl:sequence select="concat('xmldb:exist:///db', $uri-relative-from-app, '/', local:get-full-uri($uri))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template name="do-anchor">
    <!-- Adds an anchor. This is done when an @xml:id is present or when it is a section. On sections an anchor is forced because the TOC must be able to refer to them. -->
    <xsl:param name="elm" as="element()" required="no" select="."/>

    <xsl:if test="exists($elm/@xml:id) or starts-with(local-name($elm), 'sect')">
      <a name="{db5sup:get-id($elm)}"/>
    </xsl:if>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:function name="local:has-role" as="xs:boolean">
    <xsl:param name="elm" as="element()"/>
    <xsl:param name="role" as="xs:string"/>
    <xsl:sequence select="$role = tokenize(string($elm/@role), '\s+')"/>
  </xsl:function>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:function name="local:capitalize" as="xs:string">
    <xsl:param name="in" as="xs:string"/>
    <xsl:sequence select="concat(upper-case(substring($in, 1, 1)), substring($in, 2))"/>
  </xsl:function>

</xsl:stylesheet>
