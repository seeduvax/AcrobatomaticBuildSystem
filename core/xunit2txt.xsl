<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:param name="mode"></xsl:param>

<!-- ############################################################## -->
<xsl:template match="error|failure"
><xsl:value-of select="@message"/><xsl:text>
</xsl:text><xsl:value-of select="text()"/>
</xsl:template>
<!-- ############################################################## -->
<xsl:template match="testcase">- <xsl:if test="@classname!=''"><xsl:value-of select="@classname"/>.</xsl:if><xsl:value-of select="@name"/>
<xsl:if test="@time!=''"><xsl:text>	</xsl:text><xsl:value-of select="@time"/> s (<xsl:value-of select="number(@time) * 1000"/> ms)</xsl:if>.<xsl:text>
</xsl:text><xsl:apply-templates select="*"/></xsl:template>

<!-- ############################################################## -->
<xsl:template match="testsuites|testsuite" mode="stat"
>- Tests: <xsl:value-of select="@tests"/>
- Total Successes: <xsl:value-of select="count(//testcase[count(skipped)=0 and count(error)=0 and count(failure)=0])"/>
- Total Failures: <xsl:value-of select="@failures"/>
- Total Errors: <xsl:value-of select="@errors"/>
- Total Disabled: <xsl:value-of select="count(//skipped)"/>
- Total time: <xsl:value-of select="sum(//testcase/@time)"/> s (<xsl:value-of select="sum(//testcase/@time) * 1000"/> ms)
</xsl:template>

<!-- ############################################################## -->
<xsl:template match="/">
<xsl:choose>
<xsl:when test="$mode='short'"
>Successes: <xsl:value-of select="count(//testcase[count(skipped)=0 and count(error)=0 and count(failure)=0])"
/>, Failures: <xsl:value-of select="testsuites/@failures"
/>, Errors: <xsl:value-of select="testsuites/@errors"
/>, Disabled: <xsl:value-of select="count(//skipped)"/><xsl:text>
</xsl:text>
<xsl:apply-templates select=".//testcase[count(failure)!=0 or count(error)!=0]"/>
</xsl:when>
<xsl:otherwise>
# ---------------------------------------------------------------------
# Successful tests
# ---------------------------------------------------------------------
<xsl:apply-templates select=".//testcase[count(error)=0 and count(failure)=0 and count(skipped)=0]"/>
# ---------------------------------------------------------------------
# Disabled tests
# ---------------------------------------------------------------------
<xsl:apply-templates select=".//testcase[count(skipped)!=0]"/>
# ---------------------------------------------------------------------
# Failed tests
# ---------------------------------------------------------------------
<xsl:apply-templates select=".//testcase[count(failure)!=0 or count(error)!=0]"/>
# ---------------------------------------------------------------------
# Statistics
# ---------------------------------------------------------------------
<xsl:apply-templates select="/testsuites|/testsuite" mode="stat"/><xsl:text>
</xsl:text>
</xsl:otherwise>
</xsl:choose>
</xsl:template>

</xsl:stylesheet>
