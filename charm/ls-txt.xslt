<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>

<!-- ############################################################## -->
<xsl:template match="/cr">
<xsl:value-of select="substring(@id,1,7)"/> [<xsl:value-of select="@state"/>]<xsl:text>	</xsl:text><xsl:value-of select="title"/><xsl:text>
</xsl:text>
<xsl:apply-templates select="links/link[@name='child']"/>
</xsl:template>

<xsl:template match="link">
  <xsl:param name="src"><xsl:value-of select="."/>.cr</xsl:param>
  <xsl:apply-templates select="document($src)/cr"/>
</xsl:template>
</xsl:stylesheet>
