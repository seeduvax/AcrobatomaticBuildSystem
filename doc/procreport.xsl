<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"
	    encoding="utf-8"/>
<xsl:template match="/document">
{# ----------------------------------------------------------------------------
Procedure execution report fill instructions
-------------------------------------------------------------------------------
Copy/paste this template into your heml report document (all from '{report' to 
final '}').

Define status for each operation/assert entry
  - status values for operation:
    - done: when operation has be done as specified.
    - adapted: when operation has been done but not exactly as specified.
    - skipped: when operation has not been done.
  - status values for assert:
    - pass: observations match the expectations.
    - n/a: no observation because of previous operation was skipped.
    - failed: observations do not match the expectation.

Add free text in operation/assert in the following cases:
  - operation with adapted status: details about what was exactly done that
    differs from the specification.
  - operation with skipped status: details about the reason why the operation 
    was not performed.
  - assert with failed status: detailed description of the observation not 
    matching the expectations.

leave req elements and other attributes unchange to enable proper document 
generation and traceability.

---------------------------------------------------------------------------- #}
{report 
  {context %reference=<xsl:value-of select="reference"/>
           %edition=<xsl:value-of select="history/edition[1]/@version"/>, <xsl:value-of select="history/edition[1]/@date"/>
           %start=
           %end=
  }
  <xsl:apply-templates select="//check"/>
}
</xsl:template>

<xsl:template match="check">
<xsl:param name="num"><xsl:number count="section|references|definitions|check" level="multiple" format="1.1"/></xsl:param>
{check %title=<xsl:value-of select="@title"/>
       %id=<xsl:value-of select="@id"/>
       %ref=<xsl:value-of select="$num"/>
<xsl:apply-templates select="operation|assert|req"/>
}
</xsl:template>

<xsl:template match="operation">
  <xsl:param name="norm"><xsl:value-of select="normalize-space(.//*[not(self::req)])"/></xsl:param>
  <xsl:param name="summary"><xsl:value-of select="substring($norm,1,80)"/></xsl:param>
  {operation %id=<xsl:value-of select="count(preceding-sibling::operation)+1"/>
             %summary=<xsl:value-of select="normalize-space($summary)"/><xsl:if test="$norm!=$summary">...</xsl:if> 
             %status=
  }
</xsl:template>
<xsl:template match="assert">
  <xsl:param name="norm"><xsl:value-of select="normalize-space(.//*[not(self::req)])"/></xsl:param>
  <xsl:param name="summary"><xsl:value-of select="substring($norm,1,80)"/></xsl:param>
  {assert %id=<xsl:value-of select="count(preceding-sibling::assert)+1"/>
          %summary=<xsl:value-of select="normalize-space($summary)"/><xsl:if test="$norm!=$summary">...</xsl:if> 
          %status= 
<xsl:apply-templates select="req"/>
  }
</xsl:template>

<xsl:template match="req">
    {req <xsl:value-of select="."/>}</xsl:template>

</xsl:stylesheet>
