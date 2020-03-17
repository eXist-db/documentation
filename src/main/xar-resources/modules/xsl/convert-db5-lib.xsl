<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:db5sup="http://exist.sourceforge.net/NS/exist/db5-support" xmlns:db5="http://docbook.org/ns/docbook" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="#local.jgf_y4c_mcb" version="2.0" exclude-result-prefixes="#all">
  <!-- ================================================================== -->
  <!-- 
       Small support library with shared functions for the DB5 conversions.
       
       Main reason is to centralize the identifier computation. This must be the same when generating the TOC and the main contents, 
       otherwise the links from the TOC to the contents don't work.
  -->
  <!-- ================================================================== -->

  <xsl:function name="db5sup:get-id" as="xs:string">
    <xsl:param name="elm" as="element()"/>
      
    <xsl:choose>
      <xsl:when test="exists($elm/@xml:id)">
        <xsl:sequence select="$elm/@xml:id"/> 
      </xsl:when>
      <xsl:when test="exists($elm/@exist:id)">
        <xsl:sequence select="concat('D', $elm/@exist:id)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="generate-id($elm)"/>
      </xsl:otherwise>  
    </xsl:choose>  
  </xsl:function>

</xsl:stylesheet>