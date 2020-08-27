<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>

<!-- ############################################################## -->
<xsl:template match="/cr">
===============================================================================
<xsl:value-of select="substring(@id,1,7)"/> [<xsl:value-of select="@state"/>]<xsl:text>	</xsl:text><xsl:value-of select="title"/>
-------------------------------------------------------------------------------
Creation: <xsl:value-of select="creation"/>
Reporter: <xsl:value-of select="reporter"/>
-------------------------------------------------------------------------------
<xsl:apply-templates select="description"/>
-------------------------------------------------------------------------------
<xsl:apply-templates select="links/link"/>
-------------------------------------------------------------------------------
</xsl:template>

<xsl:template match="link"
><xsl:param name="src"><xsl:value-of select="normalize-space(.)"/>.cr</xsl:param
> - <xsl:value-of select="@name"/>: <xsl:value-of select="substring(normalize-space(.),1,7)"/><xsl:text>  </xsl:text><xsl:value-of select="document($src)/cr/title"/><xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="li"
>- <xsl:apply-templates/>
</xsl:template>
</xsl:stylesheet>
