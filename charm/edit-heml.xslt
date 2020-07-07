<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>


<xsl:template name="indent"
><xsl:value-of select="substring('                                          ',1,count(ancestor::*))"
/></xsl:template>
<xsl:template name="indent-bullet"
><xsl:value-of select="substring('                                          ',1,count(ancestor::ul|li))"
/></xsl:template>
<!-- paragrah -->
<xsl:template match="p">
<xsl:apply-templates select="*|text()"/><xsl:text>
</xsl:text></xsl:template>

<!-- bullets -->
<xsl:template match="ul">
<xsl:apply-templates select="*"/>
</xsl:template>
<xsl:template match="li">
<xsl:call-template name="indent-bullet"/>- <xsl:apply-templates select="*|text()"/>
</xsl:template>

<!-- inline elements -->
<xsl:template match="i|b|kw|a|td|th"
>{<xsl:value-of select="name()"/><xsl:if test="count(@*)&gt;0"
 ><xsl:apply-templates select="@*"/> %%</xsl:if><xsl:text> </xsl:text><xsl:value-of select="text()"
/>}</xsl:template>
<!-- mono-line elements -->
<xsl:template match="title|link|link|creation|cf|reporter|assignee"
><xsl:call-template name="indent"/>{<xsl:value-of select="name()"/><xsl:if test="count(@*)&gt;0"
 ><xsl:apply-templates select="@*"/> %%</xsl:if><xsl:text> </xsl:text><xsl:value-of select="normalize-space(text())"
/>}<xsl:text>
</xsl:text></xsl:template>

<!-- defaults -->
<xsl:template match="@*"> %<xsl:value-of select="name()"/>=<xsl:value-of select="."
/><xsl:text> </xsl:text></xsl:template>
<xsl:template match="text()"><xsl:if test="normalize-space(.)!=''"><xsl:value-of select="."
/></xsl:if></xsl:template>
<xsl:template match="*">
<xsl:call-template name="indent"/>{<xsl:value-of select="name()"/>  <xsl:apply-templates select="@*"/><xsl:text>
</xsl:text><xsl:apply-templates select="*|text()"/><xsl:if test="count(*|text())&gt;0"><xsl:text>
</xsl:text></xsl:if><xsl:call-template name="indent"/>}<xsl:text>
</xsl:text></xsl:template>

</xsl:stylesheet>
