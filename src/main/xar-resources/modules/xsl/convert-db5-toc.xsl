<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:db5sup="http://exist.sourceforge.net/NS/exist/db5-support" xmlns:db5="http://docbook.org/ns/docbook" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="#local.o5w_njz_lcb" version="2.0" exclude-result-prefixes="#all">
  <!-- ================================================================== -->
  <!-- 
      Will create the TOC for the DB5 document. Will only go two levels deep (deeper is not very useful for a TOC).       
  -->
  <!-- ================================================================== -->
  <!-- SETUP: -->

  <xsl:output method="xml" indent="no" encoding="UTF-8"/>

  <xsl:include href="convert-db5-lib.xsl"/>

  <!-- ================================================================== -->

  <xsl:template match="/">
    <xsl:if test="exists(/*/db5:sect1)">
      <ul class="toc">
        <xsl:for-each select="/*/db5:sect1">
          <li>
            <a href="#{db5sup:get-id(.)}">
              <xsl:value-of select="db5:title"/>
            </a>
            <xsl:if test="exists(db5:sect2)">
              <ul class="toc">
                <xsl:for-each select="db5:sect2">
                  <li>
                    <a href="#{db5sup:get-id(.)}">
                      <xsl:value-of select="db5:title"/>
                    </a>
                  </li>
                </xsl:for-each>
              </ul>
            </xsl:if>
          </li>
        </xsl:for-each>
      </ul>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>