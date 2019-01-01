<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml"
	encoding="utf-8"
	indent="yes"/>

<xsl:template match="p">
  <para><xsl:apply-templates/></para>
</xsl:template>

<xsl:template match="ul">
  <itemizedlist>
    <xsl:apply-templates/>
  </itemizedlist>
</xsl:template>

<xsl:template match="li">
  <listitem><para>
    <xsl:apply-templates/>
  </para></listitem>
</xsl:template>

<xsl:template match="fig">
  <figure>
    <title><xsl:value-of select="@title"/></title>
    <mediaobject><imageobject>
      <imagedata fileref="@src"/>
    </imageobject></mediaobject>
  </figure>
</xsl:template>

<xsl:template match="section">
  <section>
    <title><xsl:value-of select="@title"/></title>
    <xsl:apply-templates/>
  </section>
</xsl:template>


<xsl:template match="/document">
  <article version="5.0" xmlns="http://docbook.org/ns/docbook"
         xmlns:ns5="http://www.w3.org/2000/svg"
         xmlns:ns42="http://www.w3.org/1999/xhtml"
         xmlns:ns4="http://www.w3.org/1999/xlink"
         xmlns:ns3="http://www.w3.org/1998/Math/MathML"
         xmlns:ns="http://docbook.org/ns/docbook">
    <info>
      <title><xsl:value-of select="@title"/></title>
      <copyright>
      	<year><xsl:value-of select="copyright/@year"/></year>
      	<holder><xsl:value-of select="copyright/@holder"/></holder>
      	<author>
      	  <xsl:value-of select="author"/>
      	</author>
      </copyright>
    </info>
    <xsl:apply-templates select="section"/>
  </article>
</xsl:template>

<xsl:template match="author">
  <personname>
    <firstname><xsl:value-of select="@firstname"/></firstname>
    <surname><xsl:value-of select="@surname"/></surname>
  </personname>
</xsl:template>

</xsl:stylesheet>
