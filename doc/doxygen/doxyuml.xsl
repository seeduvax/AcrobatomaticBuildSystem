<!-- XSLT script to combine the generated output into a single file. 
     If you have xsltproc you could use:
     xsltproc combine.xslt index.xml >all.xml
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
	xmlns:str="http://exslt.org/strings">

  <xsl:output method="xml" version="1.0" indent="yes" standalone="yes" />
<xsl:template match="/">
    <umlmodel>
      <!-- Load all doxgen generated xml files -->
      <xsl:for-each select="doxygenindex/compound[@kind='namespace']">
        <xsl:apply-templates select="document( concat( @refid, '.xml' ) )/doxygen/compounddef" mode="package"/>
      </xsl:for-each>
    </umlmodel>
</xsl:template>

<xsl:template match="compounddef" mode="package">
    <package>
		<xsl:attribute name="name"><xsl:apply-templates select="str:split(string(compoundname),'::')" mode="package"/></xsl:attribute>
      <!-- Load all doxgen generated xml files -->
	  <xsl:for-each select="innerclass">
        <xsl:apply-templates select="document( concat( @refid, '.xml' ) )/doxygen/compounddef" mode="class"/>
      </xsl:for-each>
    </package>
</xsl:template>

<xsl:template match="compounddef" mode="class">
	<class>
		<xsl:attribute name="name"><xsl:value-of select="str:split(string(compoundname),'::')[position() = last()]"/></xsl:attribute>
		<xsl:attribute name="visibility"><xsl:value-of select="@prot"/></xsl:attribute>
		<xsl:attribute name="stereotype">
			<xsl:if test="@kind!='class'">
				<xsl:value-of select="@kind"/><xsl:text> </xsl:text>
			</xsl:if>
			<xsl:apply-templates select="detaileddescription//uml.stereotype"/>
		</xsl:attribute>
		<xsl:apply-templates select="basecompoundref"/>
		<xsl:apply-templates select="detaileddescription//uml.link"/>
		<xsl:apply-templates select="detaileddescription//uml.extends"/>
		<xsl:apply-templates select="sectiondef/memberdef[@kind='function']" mode="method"/>
		<xsl:apply-templates select="sectiondef/memberdef[@kind='variable']" mode="field"/>
	</class>
</xsl:template>

<xsl:template match="token" mode="package"><xsl:value-of select="."/><xsl:if test="position()!=last()">.</xsl:if></xsl:template> 

<xsl:template match="basecompoundref">
	<extends>
		<xsl:attribute name="name"><xsl:value-of select="str:split(string(.),'::')[position() = last()]"/></xsl:attribute>
		<xsl:attribute name="package"><xsl:apply-templates select="str:split(string(.),'::')[position() != last()]" mode="package"/></xsl:attribute>
	</extends>
</xsl:template>
<xsl:template match="uml.extends">
	<extends>
		<xsl:attribute name="name"><xsl:value-of select="str:split(string(@type),'.')[position() = last()]"/></xsl:attribute>
		<xsl:attribute name="package"><xsl:apply-templates select="str:split(string(@type),'.')[position() != last()]" mode="package"/></xsl:attribute>
	</extends>
</xsl:template>

<xsl:template match="uml.stereotype">
	<xsl:value-of select="@name"/><xsl:text> </xsl:text>
</xsl:template>

<xsl:template match="uml.link">
	<relation stereotype="{@name}">
		<xsl:attribute name="type"><xsl:value-of select="str:split(@class,'.')[position() = last()]"/></xsl:attribute>
		<xsl:attribute name="package"><xsl:apply-templates select="str:split(@class,'.')[position() != last()]" mode="package"/></xsl:attribute>
		
	</relation>
</xsl:template>

<xsl:template match="memberdef" mode="method">
	<method>
		<xsl:attribute name="name"><xsl:value-of select="name"/></xsl:attribute>
		<xsl:attribute name="return"><xsl:value-of select="type"/></xsl:attribute>
		<xsl:attribute name="visibility"><xsl:value-of select="@prot"/></xsl:attribute>
		<xsl:apply-templates select="param"/>
	</method>
</xsl:template>
<xsl:template match="memberdef" mode="field">
	<field>
		<xsl:attribute name="name"><xsl:value-of select="name"/></xsl:attribute>
		<xsl:attribute name="visibility"><xsl:value-of select="@prot"/></xsl:attribute>
		<xsl:if test="count(detaileddescription/para/uml.relation)=1">
			<xsl:attribute name="relation"><xsl:value-of 
					select="detaileddescription/para/uml.relation/@type"/></xsl:attribute>
			<xsl:attribute name="fromCard"><xsl:value-of 
					select="detaileddescription/para/uml.relation/@from"/></xsl:attribute>
			<xsl:attribute name="toCard"><xsl:value-of 
					select="detaileddescription/para/uml.relation/@to"/></xsl:attribute>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="detaileddescription/para/uml.relation/@class!=''">
				<xsl:attribute name="type"><xsl:value-of 
						select="str:split(string(detaileddescription/para/uml.relation/@class),'.')[position() = last()]"/></xsl:attribute>
				<xsl:attribute name="package"><xsl:apply-templates
						select="str:split(string(detaileddescription/para/uml.relation/@class),'.')[position() != last()]"
						mode="package"/></xsl:attribute>
			</xsl:when>
			<xsl:when test="count(type/ref[@kindref='member'])=1">
				<xsl:attribute name="type"><xsl:value-of select="str:split(string(/doxygen/compounddef/compoundname),'::')[position()=last()]"/>.<xsl:value-of select="type/ref"/></xsl:attribute>
				<xsl:attribute name="package"><xsl:apply-templates select="str:split(string(/doxygen/compounddef/compoundname),'::')[position()!=last()]" mode="package"/></xsl:attribute>
			</xsl:when>
			<xsl:when test="count(type/ref)=1">
				<xsl:attribute name="type"><xsl:value-of select="type/ref"/></xsl:attribute>
				<xsl:attribute name="package"><xsl:apply-templates select="str:split(string(document(concat(type/ref/@refid, '.xml' ))/doxygen/compounddef/compoundname),'::')[position()!=last()]" mode="package"/></xsl:attribute>
			</xsl:when>
			<xsl:otherwise>
				<xsl:attribute name="type"><xsl:value-of select="str:split(string(type),'.')[position()=last()]"/></xsl:attribute>
				<xsl:attribute name="package"><xsl:apply-templates select="str:split(string(type),'.')[position()!=last()]"
					mode="package"/></xsl:attribute>
			</xsl:otherwise>
		</xsl:choose>
	</field>
</xsl:template>

<xsl:template match="param">
	<parameter>
		<xsl:attribute name="name"><xsl:value-of select="declname"/></xsl:attribute>
		<xsl:attribute name="type"><xsl:value-of select="type"/></xsl:attribute>
	</parameter>
</xsl:template>

</xsl:stylesheet>
