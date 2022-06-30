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

Fill context:
  - start: procedure execution start date
  - end: procedure execution end date
  - operator: name of operator running the procedure
  - free text insinde context element: anything to be reported describing the
    test execution detailed context: specific means and configuration.

During execution, define status for each operation/assert entry
  - status values for operation:
    - done: when operation has be done as specified.
    - adapted: when operation has been done but not exactly as specified.
    - skept: when operation has not been done.
  - status values for assert:
    - pass: observations match the expectations.
    - n/a: no observation because of previous operation was skept.
    - failed: observations do not match the expectation.

Add free text in operation/assert in the following cases:
  - operation with adapted status: details about what was exactly done that
    differs from the specification.
  - operation with skept status: details about the reason why the operation 
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
           %operator=
  }
  <xsl:apply-templates select="//check|//procedure"/>
}
</xsl:template>

<xsl:template match="check|procedure">
<xsl:param name="num"><xsl:number count="section|references|definitions|check|procedure" level="multiple" format="1.1"/></xsl:param>
{<xsl:value-of select="name()"/> %title=<xsl:value-of select="@title"/>
       %id=<xsl:value-of select="@id"/>
       %ref=<xsl:value-of select="$num"/>
<xsl:apply-templates select="operation|assert|req|section"/>
}
</xsl:template>

<xsl:template match="operation">
  <xsl:param name="norm"><xsl:value-of select="normalize-space(.//*[not(self::req)])"/></xsl:param>
  <xsl:param name="summary"><xsl:value-of select="substring($norm,1,80)"/></xsl:param>
  {operation %id=<xsl:number count="operation|check//section|procedure//section" level="multiple" format="1.1"/>
             %summary=<xsl:value-of select="normalize-space($summary)"/><xsl:if test="$norm!=$summary">...</xsl:if> 
             %status=
  }
</xsl:template>
<xsl:template match="assert">
  <xsl:param name="norm"><xsl:value-of select="normalize-space(.//*[not(self::req)])"/></xsl:param>
  <xsl:param name="summary"><xsl:value-of select="substring($norm,1,80)"/></xsl:param>
  {assert %id=<xsl:number count="assert|check//section|procedure//section" level="multiple" format="1.1"/>
          %summary=<xsl:value-of select="normalize-space($summary)"/><xsl:if test="$norm!=$summary">...</xsl:if> 
          %status= 
<xsl:apply-templates select="req"/>
  }
</xsl:template>
<xsl:template match="section">
{section %id=<xsl:number count="section|check|procedure" level="multiple" format="1.1"/> %title=<xsl:value-of select="normalize-space(@title)"/>
   <xsl:apply-templates select="operation|assert"/>
}
</xsl:template>

<xsl:template match="req">
    {req <xsl:value-of select="."/>}</xsl:template>

</xsl:stylesheet>
