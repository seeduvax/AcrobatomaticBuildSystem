<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>

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
- Total Failures: <xsl:value-of select="@failures"/>
- Total Errors: <xsl:value-of select="@errors"/>
- Total Disabled: <xsl:value-of select="count(//skipped)"/>
- Total time: <xsl:value-of select="sum(//testcase/@time)"/> s (<xsl:value-of select="sum(//testcase/@time) * 1000"/> ms)
</xsl:template>

<!-- ############################################################## -->
<xsl:template match="/">
# ---------------------------------------------------------------------
# Successful tests
# ---------------------------------------------------------------------
<xsl:apply-templates select=".//testcase[@status='pass']"/>
<xsl:apply-templates select=".//testcase[not(@status) and count(failure)=0]"/>
# ---------------------------------------------------------------------
# Disabled tests
# ---------------------------------------------------------------------
<xsl:apply-templates select=".//testcase[@status='skipped']"/>
# ---------------------------------------------------------------------
# Failed tests
# ---------------------------------------------------------------------
<xsl:apply-templates select=".//testcase[@status='failure' or @status='error']"/>
<xsl:apply-templates select=".//testcase[count(failure)&gt;0]"/>
# ---------------------------------------------------------------------
# Statistics
# ---------------------------------------------------------------------
<xsl:apply-templates select="/testsuites|/testsuite" mode="stat"/><xsl:text>
</xsl:text>
</xsl:template>

</xsl:stylesheet>
