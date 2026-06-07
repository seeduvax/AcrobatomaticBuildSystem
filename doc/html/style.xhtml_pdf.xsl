<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:import href="style.xhtml.xsl"/>
	<xsl:param name="htmlToBookVersion"/>
	<xsl:template name="additionnalMeta">
		<meta name="numberedSections" content="false"/>
	</xsl:template>
	<xsl:template name="additionnalStylesPdf">
	</xsl:template>
	<xsl:template name="additionnalStyles">
        <link rel="stylesheet" href="./HtmlToBook-{$htmlToBookVersion}/htmlToBook.css"/>
		<link rel="stylesheet" href="{$root}/{$mainCss}"/>
        <link rel="stylesheet" href="./css/style_pdf.css"/>
		<xsl:call-template name="additionnalStylesPdf"/>
	</xsl:template>
	<xsl:template name="additionnalStylesPres">
		<style>:root { 
			--page_orientation: landscape; 
			--width: 700px;
			--height: 1280px; 
		}</style>
        <link rel="stylesheet" href="./HtmlToBook-{$htmlToBookVersion}/htmlToBook.css"/>
		<link rel="stylesheet" href="{$root}/{$slidesCss}"/>
        <link rel="stylesheet" href="./css/slides_pdf.css"/>
	</xsl:template>
	<xsl:template name="additionnalScriptsPdf">
	</xsl:template>
	<!-- remove impress part in html -->
	<xsl:template name="impress_part">
	</xsl:template>
	<xsl:template name="additionnalScripts">
		<script type="text/javascript" src="{$root}/HtmlToBook-{$htmlToBookVersion}/htmlToBook_all.js">
		<xsl:text> </xsl:text></script>
		<xsl:call-template name="additionnalScriptsPdf"/>
	</xsl:template>
	<xsl:template name="toc">
		<xsl:call-template name="title-page"/>
		<break_page><xsl:text> </xsl:text></break_page>
		<xsl:apply-templates select="/document/history"/>
		<break_page><xsl:text> </xsl:text></break_page>
		<div class="toc_pdf">
			<h3>Table of Content</h3>
			<div id="toc"><xsl:text> </xsl:text></div>
		</div>
		<break_page><xsl:text> </xsl:text></break_page>
	</xsl:template>
	<xsl:template name="page-head">
		<xsl:param name="title"></xsl:param>
		<header>
			<div class="head">
				<xsl:apply-templates select="head"/>
				<h1><a name="top"><xsl:value-of select="$title"/></a></h1>
				<p aligh="right"><xsl:value-of select="/document/author/@sigle"/> n°<xsl:value-of select="/document/reference"/>, Issue <xsl:value-of select="/document/history/edition[1]/@version"/> - Revision <xsl:value-of select="/document/revision"/><xsl:value-of select="$revision"/> - <xsl:value-of select="/document/history/edition[1]/@date"/></p>
			</div>
		</header>
	</xsl:template>
	<xsl:template name="page-foot">
		<footer>
		<div class="foot">
			<p><xsl:apply-templates select="/document/copyright"/>Context: <xsl:value-of select="$context"/> - Generated: <xsl:value-of select="$buildinfo"/></p>
			<div>Page <span class="pageNumber"><xsl:text> </xsl:text></span> / <span class="pagesCount"><xsl:text> </xsl:text></span></div>
		</div>
		</footer>
	</xsl:template>
	<xsl:template name="title-page">
		<div id="titlePage">
			<div style="text-align: right">
				<div style="font-weight: bold"><xsl:value-of select="/document/reference"/></div>
				<div>Issue <xsl:value-of select="/document/history/edition[1]/@version"/> - Revision <xsl:value-of select="/document/revision"/><xsl:value-of select="$revision"/> - <xsl:value-of select="/document/history/edition[1]/@date"/></div>
				<div>Page <span class="pageNumber"><xsl:text> </xsl:text></span> / <span class="pagesCount"><xsl:text> </xsl:text></span></div>
			</div>
			<div class="titlePart" style="text-align: center">
				<h1><xsl:value-of select="/document/title"/></h1>
				<img src="images/abslogo.png"/>
			</div>
			<div>
				<table>
					<tr>
						<td>Author</td>
						<td><xsl:value-of select="/document/author/@sigle"/></td>
					</tr>
					<tr>
						<td>Abstract</td>
						<td><xsl:value-of select="/document/abstract"/></td>
					</tr>
					<tr>
						<td>Keywords</td>
						<td><xsl:value-of select="/document/keywords"/></td>
					</tr>
					<tr>
						<td>Context</td>
						<td><xsl:value-of select="$context"/></td>
					</tr>
					<tr>
						<td>Processed</td>
						<td><xsl:value-of select="$buildinfo"/></td>
					</tr>
				</table>
			</div>
		</div>
	</xsl:template>
</xsl:stylesheet>
