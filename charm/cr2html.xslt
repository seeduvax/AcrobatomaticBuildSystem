<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml"
		encoding="utf-8"
		doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
		doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
	    indent="yes"/>

<!-- ############################################################## -->
<xsl:template match="/cr">
<html>
<head>
<title></title>
</head>
<body>
<h1><xsl:value-of select="substring(@id,1,7)"/>
<xsl:value-of select="title"/></h1>
<p>State: <xsl:value-of select="@state"/></p>
<p>Creation: <xsl:value-of select="creation"/></p>
<p>Reporter: <xsl:value-of select="reporter"/></p>
<p>Assignee: <xsl:value-of select="assignee"/></p>
<h2>Description</h2>
<xsl:value-of select="description"/>
<h2>Links</h2>
<ul>
<table>
<xsl:apply-templates select="links/link"/>
</table>
</ul>
</body>
</html>
</xsl:template>

<xsl:template match="link">
	<xsl:param name="src"><xsl:value-of select="."/>.cr</xsl:param>
	<xsl:param name="tid"><xsl:value-of select="."/></xsl:param>
<tr>
 <td><xsl:value-of select="@name"/></td>
 <td><a href="{$tid}.html"><xsl:value-of select="substring(.,1,7)"/></a></td>
 <td><xsl:value-of select="document($src)/cr/title"/></td>
</tr>
</xsl:template>
</xsl:stylesheet>
