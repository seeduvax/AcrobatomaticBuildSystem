<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"
	    encoding="utf-8"/>
<xsl:param name="app"/>
<xsl:param name="version"/>
<xsl:param name="revision"/>
<xsl:param name="date"/>
<xsl:param name="user"/>
<xsl:param name="host"/>
<xsl:param name="srcdir"/>
<xsl:param name="srcfilename"/>
<xsl:param name="style">heml.sty</xsl:param>
<xsl:param name="slideStyle">hemlSlide.sty</xsl:param>
<xsl:param name="context">Component <xsl:value-of select="$app"/>-<xsl:value-of select="$version"/></xsl:param>
<xsl:param name="buildinfo"><xsl:value-of select="$date"/> / <xsl:value-of select="$user"/>@<xsl:value-of select="$host"/></xsl:param>
<xsl:param name="draftStatus"><xsl:choose>
 <xsl:when test="substring($version,string-length($version))='d'">true</xsl:when>
 <xsl:otherwise>false</xsl:otherwise>
</xsl:choose></xsl:param>
<xsl:param name="showComments">true</xsl:param>
<xsl:variable name="upperCase">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
<xsl:variable name="lowerCase">abcdefghijklmnopqrstuvwxyz</xsl:variable>

<!--************************************************
     Str replace template
-->     
<xsl:template name="strreplace">
    <xsl:param name="text"/>
    <xsl:param name="from"/>
    <xsl:param name="to"/>
    <xsl:choose>
      <xsl:when test="contains($text,$from)">
        <xsl:value-of select="substring-before($text,$from)"/>
        <xsl:value-of select="$to"/>
        <xsl:call-template name="strreplace">
          <xsl:with-param name="text"
select="substring-after($text,$from)"/>
          <xsl:with-param name="from" select="$from"/>
          <xsl:with-param name="to" select="$to"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
<!--************************************************
    In latex & must become \\ampersand, and many other
    should be escpaed. 
-->
<xsl:template name="formatText">
 <xsl:param name="text"/>
 <xsl:param name="step1"><xsl:call-template name="strreplace">
  <xsl:with-param name="text" select="$text"/>      
  <xsl:with-param name="from" select="'&amp;'"/>        
  <xsl:with-param name="to" select="'\&amp;'"/>     
 </xsl:call-template></xsl:param>
 <xsl:param name="step2"><xsl:call-template name="strreplace">
  <xsl:with-param name="text" select="$step1"/>     
  <xsl:with-param name="from" select="'_'"/>        
  <xsl:with-param name="to" select="'\_'"/>     
 </xsl:call-template></xsl:param>
 <xsl:param name="step3"><xsl:call-template name="strreplace">
  <xsl:with-param name="text" select="$step2"/>     
  <xsl:with-param name="from" select="'$'"/>        
  <xsl:with-param name="to" select="'\$'"/>     
 </xsl:call-template></xsl:param>
 <xsl:param name="step4"><xsl:call-template name="strreplace">
  <xsl:with-param name="text" select="$step3"/>     
  <xsl:with-param name="from" select="'^'"/>        
  <xsl:with-param name="to" select="'\^'"/>     
 </xsl:call-template></xsl:param>
 <xsl:param name="step5"><xsl:call-template name="strreplace">
  <xsl:with-param name="text" select="$step4"/>     
  <xsl:with-param name="from" select="'#'"/>        
  <xsl:with-param name="to" select="'\#'"/>     
 </xsl:call-template></xsl:param>
 <xsl:param name="step6"><xsl:call-template name="strreplace">
  <xsl:with-param name="text" select="$step5"/>     
  <xsl:with-param name="from" select="'&lt;'"/>     
  <xsl:with-param name="to" select="'{\textless}'"/>        
 </xsl:call-template></xsl:param>
 <xsl:param name="step7"><xsl:call-template name="strreplace">
  <xsl:with-param name="text" select="$step6"/>     
  <xsl:with-param name="from" select="'&gt;'"/>     
  <xsl:with-param name="to" select="'{\textgreater}'"/>     
 </xsl:call-template></xsl:param>
 <xsl:param name="step8"><xsl:call-template name="strreplace">
  <xsl:with-param name="text" select="$step7"/>     
  <xsl:with-param name="from" select="'§'"/>     
  <xsl:with-param name="to" select="'{\S}'"/>     
 </xsl:call-template></xsl:param>
 <xsl:value-of select="$step8"/>
</xsl:template>

<xsl:template match="text()|@*">
 <xsl:call-template name="formatText">
  <xsl:with-param name="text" select="."/>      
 </xsl:call-template>
</xsl:template>
<!--************************************************
	tete de section
		$id id de la section
		$title titre de la section
		$level niveau de section
-->
<xsl:template name="sectionHead">
	<xsl:param name="id">none</xsl:param>
	<xsl:param name="title"></xsl:param>
	<xsl:param name="level">1</xsl:param>
<xsl:choose>
  <xsl:when test="$level=1">\chapter</xsl:when>
  <xsl:when test="$level=2">\section</xsl:when>
  <xsl:when test="$level=3">\subsection</xsl:when>
  <xsl:when test="$level=4">\subsubsection</xsl:when>
  <xsl:when test="$level=5">\paragraph</xsl:when>
  <xsl:when test="$level=6">\subparagraph</xsl:when>
  <xsl:when test="$level=7">\subsubparagraph</xsl:when>
  <xsl:when test="$level=8">\subsubsubparagraph</xsl:when>
  <xsl:when test="$level=9">\subsubsubsubparagraph</xsl:when>
  </xsl:choose>{<xsl:value-of select="$title"/>} 
  <xsl:if test="$level&gt;4">~\\</xsl:if>
</xsl:template>
<!--************************************************
	Prise en charge d'une section
-->	
<xsl:template match="section">
	<xsl:choose>
		<xsl:when test="count(ancestor::chapter)&gt;0">
			<xsl:call-template name="sectionHead">
				<xsl:with-param name="id"><xsl:number level="multiple" count="section|article"/></xsl:with-param> 
				<xsl:with-param name="title"><xsl:apply-templates select="@title"/></xsl:with-param> 
				<xsl:with-param name="level"><xsl:value-of select="count(ancestor-or-self::section)+count(ancestor-or-self::article)"/></xsl:with-param> 
			</xsl:call-template>	
		</xsl:when>
		<xsl:otherwise>
			<xsl:call-template name="sectionHead">
				<xsl:with-param name="title"><xsl:apply-templates select="@title"/></xsl:with-param> 
				<xsl:with-param name="level"><xsl:value-of select="count(ancestor-or-self::section)+count(ancestor-or-self::article)+1"/></xsl:with-param> 
			</xsl:call-template>	
		</xsl:otherwise>
	</xsl:choose>
	<xsl:if test="@xref!=''">\label{<xsl:value-of select="@xref"/>}</xsl:if>
	<xsl:apply-templates/>
</xsl:template>
<!--************************************************
        Appendices
-->
<xsl:template match="appendices">
<xsl:apply-templates select="section" mode="appendix"/>
</xsl:template>

<xsl:template match="section" mode="appendix">
<xsl:apply-templates select="."/>
\newpage
</xsl:template>

<!--************************************************
     	paragraph, emphasis, quotes, ...
-->
<xsl:template match="p">
	<xsl:apply-templates/><xsl:text>
</xsl:text>
</xsl:template>
<xsl:template match="a"
 >\href{<xsl:apply-templates select="@href"
 />}{<xsl:apply-templates/>}\footnote{<xsl:apply-templates select="@href"
 />}</xsl:template>
<xsl:template match="kw"
 >\HEMLkw{<xsl:apply-templates/>}</xsl:template>
<xsl:template match="em"
 >\emph{<xsl:apply-templates/>}</xsl:template>
<xsl:template match="q">
 \begin{quote}
<xsl:apply-templates/>
 \end{quote}
</xsl:template>
<xsl:template match="todo"
>\hl{<xsl:apply-templates/>}</xsl:template>
<!--************************************************
   TBC/TBD
-->
<xsl:template match="tbc"
>\HEMLtbc{<xsl:apply-templates/>}{<xsl:value-of select="count(preceding::tbc)+1"/>}</xsl:template>
<xsl:template match="tbd"
> \HEMLtbd{<xsl:apply-templates/>}{<xsl:value-of select="count(preceding::tbd)+1"/>}</xsl:template>
<xsl:template match="tbc" mode="index">
<xsl:choose>
  <xsl:when test="position() mod 2 = 1">
\HEMLoddRow
  </xsl:when>
  <xsl:otherwise>
\HEMLevenRow
  </xsl:otherwise>
</xsl:choose>
TBC<xsl:value-of select="count(preceding::tbc)+1"/> &amp; \S\ref{tbc.<xsl:value-of select="count(preceding::tbc)+1"/>}, p\pageref{tbc.<xsl:value-of select="count(preceding::tbc)+1"/>} &amp; <xsl:apply-templates/> \\
</xsl:template>
<xsl:template match="tbd" mode="index">
<xsl:choose>
  <xsl:when test="position() mod 2 = 1">
\HEMLoddRow
  </xsl:when>
  <xsl:otherwise>
\HEMLevenRow
  </xsl:otherwise>
</xsl:choose>
TBD<xsl:value-of select="count(preceding::tbd)+1"/> &amp; \S\ref{tbd.<xsl:value-of select="count(preceding::tbd)+1"/>}, p\pageref{tbd.<xsl:value-of select="count(preceding::tbd)+1"/>} &amp; <xsl:apply-templates/> \\
</xsl:template>
<!--************************************************
   comments
-->
<xsl:template match="comment">
<xsl:if test="$showComments='true'">
\HEMLcommentref{<xsl:value-of select="@id"/>}{<xsl:value-of select="@state"/>}
</xsl:if>
</xsl:template>
<xsl:template match="comment" mode="detail">
<xsl:if test="$showComments='true'">
\HEMLcommentdetailbegin{<xsl:value-of select="@id"/>}{<xsl:value-of select="@state"/>}{<xsl:value-of select="@author"/>}

<xsl:apply-templates/>

\HEMLcommentdetailend
</xsl:if>
</xsl:template>
<xsl:template match="reply">
\HEMLreplybegin{<xsl:value-of select="@author"/>}
<xsl:apply-templates/>
\HEMLreplyend
</xsl:template>

<!--************************************************
     	figure
-->
<xsl:template match="fig">
  <xsl:param name="figpath"> 
    <xsl:choose>
      <xsl:when test="$srcdir='src'"><xsl:value-of select="@src"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="substring-after($srcdir,'src/')"/>/<xsl:value-of select="@src"/></xsl:otherwise>
    </xsl:choose>
  </xsl:param>
\begin{figure}[H]
\begin{center}
\includegraphics[scale=\HEMLfigScale, min width=3cm, max width=\linewidth, min height=3cm, max height=\textheight, keepaspectratio]{<xsl:value-of select="$figpath"/>}
\end{center}
<xsl:if test="@title!=''">
\caption{<xsl:apply-templates select="@title"/>}
</xsl:if>
<xsl:if test="@xref!=''">\label{<xsl:value-of select="@xref"/>}</xsl:if>
\end{figure}
</xsl:template>
<!--************************************************
     	requirements
-->
<xsl:template match="req">
<xsl:choose>
<xsl:when test="@id!=''">
\HEMLrequirement{<xsl:value-of select="@id"/>}{
<xsl:apply-templates/>
}
</xsl:when>
<xsl:otherwise>\HEMLreqReference{<xsl:value-of select="."/>}</xsl:otherwise>
</xsl:choose>
</xsl:template>
<xsl:template match="req" mode="ref">
<xsl:value-of select="text()"/><xsl:text> </xsl:text>
</xsl:template>
<!--************************************************
     	tables
-->
<xsl:template match="table">
<xsl:if test="@type='wide'">
\begin{landscape}
{\small
</xsl:if>
<xsl:if test="@title!=''">\captionof{table}{<xsl:apply-templates select="@title"/>}</xsl:if>
<xsl:if test="@xref!=''">\label{<xsl:value-of select="@xref"/>}</xsl:if>
\begin{HEMLtable}{|<xsl:apply-templates select="tr[1]/*" mode="tablespec"
  />}
\hline
<xsl:apply-templates select="tr"/>
\hline
\end{HEMLtable}
<xsl:if test="@type='wide'">
}
\end{landscape}
</xsl:if>
</xsl:template>
<xsl:template match="tr">
<xsl:choose>
  <xsl:when test="position() mod 2 = 1">\HEMLoddRow</xsl:when>
  <xsl:otherwise>\HEMLevenRow</xsl:otherwise>
</xsl:choose>
<xsl:apply-templates mode="cellcontent"
 ><xsl:with-param name="rowpos"><xsl:value-of select="position()"/></xsl:with-param
 ></xsl:apply-templates>\\
<xsl:if test="position()=1 and count(td)=0">
\endhead
</xsl:if>
</xsl:template>
<xsl:template match="th|td" mode="tablespec">L|</xsl:template>
<xsl:template match="td" mode="cellcontent"
><xsl:apply-templates select="."/><xsl:if test="count(following-sibling::*)&gt;0">&amp;
</xsl:if></xsl:template>
<xsl:template match="th" mode="cellcontent">
<xsl:param name="rowpos">0</xsl:param>
<xsl:choose>
  <xsl:when test="$rowpos mod 2 = 1">\HEMLoddHeadCell</xsl:when>
  <xsl:otherwise>\HEMLevenHeadCell</xsl:otherwise>
</xsl:choose
>\textbf{<xsl:apply-templates select="."/>}<xsl:if test="count(following-sibling::*)&gt;0"> &amp;</xsl:if
></xsl:template>
<!--************************************************
     Reference table
-->
<xsl:template match="references">
\subsection{<xsl:apply-templates select="@title"/>}
\begin{HEMLtable}{LL}
\hline
\HEMLoddHeadCell
&amp; \HEMLoddHeadCell \textbf{Authors}\hspace{1cm}\textbf{\emph{Title}} \\
\HEMLoddHeadCell
&amp; \HEMLoddHeadCell \textbf{\emph{Reference}}\hspace{1cm}\textbf{Edition} \\
\endhead
<xsl:apply-templates select="ref" mode="detail"/>
\hline
\end{HEMLtable}
</xsl:template>
<xsl:template match="ref" mode="detail">
<xsl:param name="hhref"><xsl:value-of select="@href"/></xsl:param>
<xsl:param name="rowcolor"><xsl:choose>
  <xsl:when test="position() mod 2 = 0">
\HEMLoddRow
  </xsl:when>
  <xsl:otherwise>
\HEMLevenRow
  </xsl:otherwise>
</xsl:choose></xsl:param>
<xsl:value-of select="$rowcolor"/>
<xsl:param name="refName"><xsl:apply-templates select="../@id"/><xsl:value-of select="count(preceding-sibling::ref)+1"/></xsl:param>
\textbf{<xsl:value-of select="$refName"/>}\refstepcounter{absCounter}\namedlabel{<xsl:value-of select="@id"/>}{[<xsl:value-of select="$refName"/>]} &amp; 
  <xsl:if test="@authors!=''"><xsl:apply-templates select="@authors"/>:</xsl:if>\hspace{1cm}\emph{<xsl:apply-templates select="."/>} \\
<xsl:if test="$hhref!=''">
 <xsl:value-of select="$rowcolor"/>
 &amp; \small <xsl:apply-templates select="@href"/> \\</xsl:if>
<xsl:value-of select="$rowcolor"/>
  &amp; \emph{<xsl:apply-templates select="@ref"/>}\hspace{1cm}<xsl:apply-templates select="@edition"/><xsl:text> </xsl:text><xsl:apply-templates select="@date"/> \\
</xsl:template>
<!--************************************************
     Definition table
-->
<xsl:template match="definitions">
\subsection{<xsl:apply-templates select="@title"/>}
\begin{HEMLtable}{LL}
\hline
<xsl:apply-templates select="def" mode="detail">
 <xsl:sort select="@entry"/>
</xsl:apply-templates>
\hline
\end{HEMLtable}
</xsl:template>
<xsl:template match="def" mode="detail">
<xsl:choose>
  <xsl:when test="position() mod 2 = 0">
\HEMLoddRow
  </xsl:when>
  <xsl:otherwise>
\HEMLevenRow
  </xsl:otherwise>
</xsl:choose>
\textbf{<xsl:apply-templates select="@entry"/>} &amp; <xsl:apply-templates select="."/> \\
</xsl:template>
<!--************************************************
     	enumerations
-->
<xsl:template match="ul">
\begin{HEMLitemize}
<xsl:apply-templates/>
\end{HEMLitemize}
</xsl:template>
<xsl:template match="li">
\item{} <xsl:apply-templates/>
</xsl:template>
<!--
    Code citation
-->
<xsl:template match="code">
 <xsl:param name="lng"><xsl:choose>
   <xsl:when test="@language='javascript'">java</xsl:when>
   <xsl:when test="@language='lua'">[5.0]lua</xsl:when>
   <xsl:otherwise><xsl:value-of select="@language"/></xsl:otherwise>
 </xsl:choose></xsl:param>
\lstset{language=<xsl:value-of select="$lng"/>}
\begin{lstlisting}[<xsl:if 
    test="@title!=''">caption=<xsl:apply-templates select="@title"/>,</xsl:if><xsl:if test="@size!=''">basicstyle=\<xsl:value-of select="@size"/>,</xsl:if><xsl:if test="@xref!=''">label=<xsl:value-of select="@xref"/></xsl:if>]<xsl:text>
</xsl:text><xsl:value-of select="pre/text()"/><xsl:text>
</xsl:text>\end{lstlisting}
</xsl:template>
<!-- **************************************************
     Notes
-->     
<xsl:template match="note">
\begin{bclogo}[<xsl:choose>
<xsl:when test="@type='warning'">logo=\bcattention, couleur=orange!10</xsl:when>
<xsl:otherwise>logo=\bcinfo, couleur=green!10</xsl:otherwise>
</xsl:choose>, couleurBord=white]{<xsl:apply-templates select="@title"/>}
<xsl:apply-templates/>
\end{bclogo}
</xsl:template>
<!-- ************************************************************************
    Edition history
-->
<xsl:template match="edition">
\hline
<xsl:apply-templates select="@version"/> &amp; <xsl:apply-templates select="@date"/> &amp; <xsl:apply-templates/> \\
</xsl:template>
<!-- ************************************************************************
    Cross reference
-->
<xsl:template match="xref">\ref{<xsl:value-of select="."/>}</xsl:template>
<!-- ************************************************************************
    Main
-->

<xsl:template name="mainArticleInclude">\input{<xsl:value-of select="$style"/>}</xsl:template>
<xsl:template name="mainArticleOverrides"></xsl:template>

<xsl:template match="/document|/article">
    <xsl:call-template name="mainArticleInclude"/>
    \renewcommand{\HEMLsrcFileName}{<xsl:call-template name="formatText"><xsl:with-param name="text" select="$srcfilename"/></xsl:call-template>}
    \renewcommand{\HEMLdraft}{<xsl:value-of select="$draftStatus"/>}
    \renewcommand{\HEMLbuildinfo}{<xsl:call-template name="formatText"><xsl:with-param name="text" select="$buildinfo"/></xsl:call-template>}
    \renewcommand{\HEMLorgName}{<xsl:value-of select="author/@sigle"/>}
    \renewcommand{\HEMLserviceName}{<xsl:value-of select="author/@service"/>}
    \renewcommand{\HEMLreference}{<xsl:apply-templates select="reference"/>}
    \renewcommand{\HEMLauthor}{<xsl:value-of select="author"/>}
<xsl:if test="count(copyright)=1">
    \renewcommand{\HEMLcopyright}{<xsl:value-of select="copyright/@year"/><xsl:text> </xsl:text><xsl:value-of select="copyright/@holder"/><xsl:text> </xsl:text><xsl:value-of select="copyright"/>}
</xsl:if>
    \renewcommand{\HEMLedition}{<xsl:value-of select="history/edition[1]/@version"/>}
    \renewcommand{\HEMLrevision}{<xsl:call-template name="strreplace">
      <xsl:with-param name="text"><xsl:call-template name="strreplace">
        <xsl:with-param name="text"><xsl:value-of select="revision"/></xsl:with-param>
        <xsl:with-param name="from" select="'$Rev: '"/>
        <xsl:with-param name="to" select="'r'"/>
      </xsl:call-template></xsl:with-param>
      <xsl:with-param name="from" select="'$'"/>
      <xsl:with-param name="to" select="' '"/>
    </xsl:call-template><xsl:value-of select="$revision"/>}
    \renewcommand{\HEMLdate}{<xsl:value-of select="history/edition[1]/@date"/>}
    
    <xsl:call-template name="mainArticleOverrides"/>
    
    <xsl:if test="confidentiality/@military='CD'">
        \renewcommand{\HEMLsecuritydefenseCD}{true}
        \renewcommand{\HEMLsecuritydefenseNP}{false}
    </xsl:if>
    <xsl:if test="confidentiality/@military='SD'">
        \renewcommand{\HEMLsecuritydefenseSD}{true}
        \renewcommand{\HEMLsecuritydefenseNP}{false}
    </xsl:if>
    <xsl:if test="confidentiality/@military='DR'">
        \renewcommand{\HEMLsecurityrestrictionDR}{true}
        \renewcommand{\HEMLsecuritydefenseNP}{false}
    </xsl:if>
    <xsl:if test="confidentiality/@company='R'">
        \renewcommand{\HEMLsecuritycompanyR}{true}
        \renewcommand{\HEMLsecuritycompanyU}{false}
    </xsl:if>
    <xsl:if test="confidentiality/@company='C'">
        \renewcommand{\HEMLsecuritycompanyC}{true}
        \renewcommand{\HEMLsecuritycompanyU}{false}
    </xsl:if>
    <xsl:if test="confidentiality/@company='S'">
        \renewcommand{\HEMLsecuritycompanyS}{true}
        \renewcommand{\HEMLsecuritycompanyU}{false}
    </xsl:if>
    <xsl:if test="confidentiality/@program='I'">
        \renewcommand{\HEMLsecurityprogramI}{true}
        \renewcommand{\HEMLsecurityprogramGP}{false}
    </xsl:if>
    <xsl:if test="confidentiality/@program='R'">
        \renewcommand{\HEMLsecurityprogramR}{true}
        \renewcommand{\HEMLsecurityprogramGP}{false}
    </xsl:if>
    <xsl:if test="confidentiality/@program='C'">
        \renewcommand{\HEMLsecurityprogramC}{true}
        \renewcommand{\HEMLsecurityprogramGP}{false}
    </xsl:if>
    <xsl:if test="confidentiality/@restricted='true'">
       \renewcommand{\HEMLsecurityrestrictionDR}{<xsl:value-of select="confidentiality/@restricted"/>}
    </xsl:if>
    <xsl:if test="confidentiality/@specialFrance='true'">
       \renewcommand{\HEMLsecuritynationalitySF}{<xsl:value-of select="confidentiality/@specialFrance"/>}
    </xsl:if>
    \renewcommand{\HEMLabstract}{<xsl:apply-templates select="abstract"/>}
    \renewcommand{\HEMLkeywords}{<xsl:apply-templates select="keywords"/>}
    \renewcommand{\HEMLcontext}{<xsl:call-template name="formatText"><xsl:with-param name="text" select="$context"/></xsl:call-template>}
    \renewcommand{\HEMLrevisiontable}{
    <xsl:apply-templates select="history/edition"/>
    }
    
    \renewcommand{\HEMLtitle}{<xsl:apply-templates select="@title"/><xsl:apply-templates select="title/text()"/>}
    \title{<xsl:apply-templates select="@title"/><xsl:apply-templates select="title/text()"/>}
    \begin{document}
    \maketitle
    \input{code.sty}
    
    <xsl:apply-templates select="section|comment"/>
    <xsl:if test="count(appendices)&gt;0">
            \clearpage
            \appendix
        <xsl:apply-templates select="appendices"/> 
    </xsl:if>
    \end{document}
</xsl:template>

<xsl:template match="include">
  <xsl:if test="document(@src)">
  <xsl:apply-templates select="document(@src)/*" mode="include">
	  <xsl:with-param name="mode"><xsl:value-of select="@mode"/></xsl:with-param>
	  <xsl:with-param name="level"><xsl:value-of select="count(ancestor-or-self::section)+count(ancestor-or-self::article)"/></xsl:with-param>
	  <xsl:with-param name="include" select="."/>
  </xsl:apply-templates>
  </xsl:if>
</xsl:template>
<!-- **********************************************************
     svn diff
-->     
<xsl:template match="diff" mode="include">
{\small
\begin{HEMLtable}{|L|L|}
\hline
\rowcolor{blue!14}
\textbf{File} &amp; \textbf{Change} \\
\endhead
<xsl:apply-templates select="paths/path" mode="include">
   <xsl:sort select="."/>
</xsl:apply-templates>
\hline
\end{HEMLtable}
}
</xsl:template>
<xsl:template match="path" mode="include">
<xsl:choose>
  <xsl:when test="position() mod 2 = 0">
\rowcolor{blue!8}
  </xsl:when>
  <xsl:otherwise>
\rowcolor{blue!4}
  </xsl:otherwise>
</xsl:choose>
<xsl:apply-templates select="."/> &amp; <xsl:value-of select="@item"/> \\
</xsl:template>
<!-- **********************************************************
     svn ls
-->     
<xsl:template match="lists" mode="include">
{\small
\begin{HEMLtable}{|L|L|}
\hline
\rowcolor{blue!14}
\textbf{File} &amp; \textbf{Revision} \\
\endhead
 <xsl:apply-templates select="list/entry" mode="include">
   <xsl:sort select="name"/>
 </xsl:apply-templates>
\hline
\end{HEMLtable}
}
</xsl:template>
<xsl:template match="entry" mode="include">
<xsl:choose>
  <xsl:when test="position() mod 2 = 0">
\rowcolor{blue!8}
  </xsl:when>
  <xsl:otherwise>
\rowcolor{blue!4}
  </xsl:otherwise>
</xsl:choose>
<xsl:apply-templates select="name"/> &amp; <xsl:apply-templates select="commit/@revision"/> \\
</xsl:template>
<!-- **********************************************************
     svn log
-->     
<xsl:template match="log" mode="include">
{\small
\begin{HEMLtable}{|L|L|}
\hline
\rowcolor{blue!14}
\textbf{Revision} &amp; \textbf{Author, date,} 

\textbf{description} \\
\endhead
<xsl:apply-templates select="logentry" mode="include"/>
\hline
\end{HEMLtable}
}
</xsl:template>
<xsl:template match="logentry" mode="include">
<xsl:choose>
  <xsl:when test="position() mod 2 = 0">
\rowcolor{blue!8}
  </xsl:when>
  <xsl:otherwise>
\rowcolor{blue!4}
  </xsl:otherwise>
</xsl:choose>
<xsl:apply-templates select="@revision"/> &amp; <xsl:apply-templates select="author"/>, <xsl:apply-templates select="date"/><xsl:text>

</xsl:text><xsl:apply-templates select="msg"/> \\
</xsl:template>
<!-- **********************************************************
     checksum
-->     
<xsl:template match="checksum" mode="include">
\begin{landscape}
Checksum function: <xsl:value-of select="@type"/>
{\small
\begin{HEMLtable}{|L|L|}
\hline
\rowcolor{blue!14}
\textbf{File} &amp; \textbf{Checksum} \\
\endhead
<xsl:apply-templates select="entry" mode="crc">
 <xsl:sort select="@path"/> 
</xsl:apply-templates>
\hline
\end{HEMLtable}
}
\end{landscape}
</xsl:template>
<xsl:template match="entry" mode="crc">
<xsl:choose>
  <xsl:when test="position() mod 2 = 0">
\rowcolor{blue!8}
  </xsl:when>
  <xsl:otherwise>
\rowcolor{blue!4}
  </xsl:otherwise>
</xsl:choose>
<xsl:apply-templates select="@path"/> &amp; <xsl:apply-templates select="@checksum"/> \\
</xsl:template>
<!-- **********************************************************
     issues
-->     
<xsl:template match="issues" mode="include">
  <xsl:param name="mode"/>
  <xsl:param name="wontfix">Won't Fix</xsl:param>
{\small
\begin{HEMLtable}{|L|L|L|L|}
\hline
\rowcolor{blue!14}
\textbf{id} &amp; \textbf{Type} &amp; \textbf{Completion} &amp; \textbf{Summary} \\ 
\endhead
<xsl:if test="$mode='applied'">
<xsl:apply-templates select="issue[@completion!=$wontfix]" mode="include">
  <xsl:sort select="@key" data-type="number"/>
</xsl:apply-templates>
</xsl:if>
<xsl:if test="$mode='bugs_not_fixed'">
<xsl:apply-templates select="issue[@completion=$wontfix and @type='Bug']" mode="include">
  <xsl:sort select="@key" data-type="number"/>
</xsl:apply-templates>
</xsl:if>
\hline
\end{HEMLtable}
}
</xsl:template>
<xsl:template match="issue" mode="include">
<xsl:choose>
  <xsl:when test="position() mod 2 = 0">
\rowcolor{blue!8}
  </xsl:when>
  <xsl:otherwise>
\rowcolor{blue!4}
  </xsl:otherwise>
</xsl:choose>
 <xsl:apply-templates select="@key"/> &amp;
 <xsl:apply-templates select="@type"/> &amp;
 <xsl:apply-templates select="@completion"/> &amp;
 <xsl:apply-templates select="."/> \\
</xsl:template>
<!-- **********************************************************
     Checks
-->     
<xsl:template match="check|procedure">
<xsl:call-template name="sectionHead">
	<xsl:with-param name="title"><xsl:if test="name()='check'">Control </xsl:if>procedure <xsl:value-of select="@id"/> - <xsl:apply-templates select="@title"/></xsl:with-param> 
	<xsl:with-param name="level"><xsl:value-of select="count(ancestor-or-self::section)+count(ancestor-or-self::article)+2"/></xsl:with-param> 
</xsl:call-template>	
<xsl:if test="count(req)&gt;0">
\HEMLreqref{
\textbf{Checked requirements}
<xsl:apply-templates select="req" mode="ref"/> 
}
</xsl:if>
<xsl:apply-templates select="*[not(self::req)]"/>
</xsl:template>

<xsl:template match="operation">
\HEMLoperationBegin
\textbf{Operation \#<xsl:value-of select="count(preceding-sibling::operation)+1"/> <xsl:value-of select="@id"/>} <xsl:apply-templates select="@title"/>
<xsl:apply-templates/>
\HEMLoperationEnd
</xsl:template>

<xsl:template match="assert">
  <xsl:param name="aid"><xsl:number count="section|references|definitions|check|procedure|assert" level="multiple" format="1.1"/></xsl:param>
\HEMLassertBegin
\textbf{Assert \#<xsl:value-of select="count(preceding-sibling::assert)+1"/> <xsl:value-of select="@id"/> <xsl:apply-templates select="@title"/>} 
 
<xsl:apply-templates select="*[not(self::req)]"/>

<xsl:if test="count(req)&gt;0">
\textbf{Checked req.:} <xsl:apply-templates select="req" mode="ref"/><xsl:text>
</xsl:text>
</xsl:if> 
\HEMLassertEnd
</xsl:template>

<!-- **********************************************************
     Procedures and check reports
-->     
<xsl:template match="report">
  <xsl:apply-templates/>
\begin{HEMLtable}{|L|L|}
\hline
  <xsl:apply-templates select="check|procedure" mode="synthesis"/>
\hline
\end{HEMLtable}
  
</xsl:template>
<xsl:template match="report/context">
\begin{HEMLtable}{|L|L|}
\hline
\HEMLoddRow
\textbf{Procedures specification} &amp; <xsl:call-template name="formatText"><xsl:with-param name="text" select="@reference"/></xsl:call-template>, edition: <xsl:value-of select="@edition"/> \\
\HEMLevenRow
\textbf{Operator} &amp; <xsl:call-template name="formatText"><xsl:with-param name="text" select="@operator"/></xsl:call-template> \\
\HEMLoddRow
\textbf{Start} &amp; <xsl:call-template name="formatText"><xsl:with-param name="text" select="@start"/></xsl:call-template> \\
\HEMLevenRow
\textbf{End} &amp; <xsl:call-template name="formatText"><xsl:with-param name="text" select="@end"/></xsl:call-template> \\
\HEMLoddRow
\textbf{Comments} &amp; <xsl:apply-templates/> \\
\hline
\end{HEMLtable}
</xsl:template>
<xsl:template match="report/check|report/procedure">
\begin{HEMLtable}{|L|L|L|}
\hline
\HEMLoddHeadCell &amp; \HEMLoddHeadCell \textbf{Procedure <xsl:value-of select="@id"/> [<xsl:call-template name="formatText"><xsl:with-param name="text" select="../context/@reference"/></xsl:call-template> {\S}<xsl:value-of select="@ref"/>]: <xsl:value-of select="@title"/>}<xsl:text>

</xsl:text><xsl:apply-templates select="req"/> &amp; \HEMLoddHeadCell \\
\HEMLevenHeadCell \textbf{step} &amp; \HEMLevenHeadCell \textbf{Comment} &amp; \HEMLevenHeadCell \textbf{Status} \\
\endhead
<xsl:apply-templates select="operation|assert"/>
\hline
\end{HEMLtable}
</xsl:template>

<xsl:template match="report/check/operation|report/procedure/operation">
<xsl:param name="lStatus"><xsl:value-of select="translate(@status,$upperCase,$lowerCase)"/></xsl:param>
<xsl:param name="statusColor"><xsl:choose>
  <xsl:when test="$lStatus='ok' or $lStatus='done'">hemlOkTextColor</xsl:when>
  <xsl:otherwise>hemlWarnTextColor</xsl:otherwise>
</xsl:choose></xsl:param>
<xsl:choose>
  <xsl:when test="(count(preceding-sibling::operation) + count(preceding-sibling::assert)) mod 2 = 1">
\HEMLoddRow
  </xsl:when>
  <xsl:otherwise>
\HEMLevenRow
  </xsl:otherwise>
</xsl:choose>
Operation \#<xsl:value-of select="@id"/> &amp;
\emph{<xsl:value-of select="@summary"/>}<xsl:text>

</xsl:text><xsl:apply-templates/>
&amp; \textbf{\color{<xsl:value-of select="$statusColor"/>}<xsl:value-of select="@status"/>} \\
</xsl:template>
<xsl:template match="report/check/assert|report/procedure/assert">
<xsl:param name="lStatus"><xsl:value-of select="translate(@status,$upperCase,$lowerCase)"/></xsl:param>
<xsl:param name="statusColor"><xsl:choose>
  <xsl:when test="$lStatus='pass' or $lStatus='ok'">hemlOkTextColor</xsl:when>
  <xsl:when test="$lStatus='ko' or $lStatus='nok' or starts-with($lStatus,'fail') or starts-with($lStatus,'err')">hemlKoTextColor</xsl:when>
  <xsl:otherwise>hemlWarnTextColor</xsl:otherwise>
</xsl:choose></xsl:param>
<xsl:choose>
  <xsl:when test="(count(preceding-sibling::operation) + count(preceding-sibling::assert)) mod 2 = 1">
\HEMLoddRow
  </xsl:when>
  <xsl:otherwise>
\HEMLevenRow
  </xsl:otherwise>
</xsl:choose>
Assert \#<xsl:value-of select="@id"/> &amp;
\emph{<xsl:value-of select="@summary"/>}<xsl:text>

</xsl:text><xsl:apply-templates select="req"/><xsl:text>

</xsl:text><xsl:apply-templates select="*[not(self::req)]"/>
&amp; \textbf{\color{<xsl:value-of select="$statusColor"/>}<xsl:value-of select="@status"/>} \\
</xsl:template>

<xsl:template match="report/check|report/procedure" mode="synthesis">
<xsl:param name="failures"><xsl:value-of select="count(assert[translate(@status,$upperCase,$lowerCase)!='ok' and translate(@status,$upperCase,$lowerCase)!='pass'])"/></xsl:param>
<xsl:choose>
  <xsl:when test="position() mod 2 = 0">
\HEMLoddRow
  </xsl:when>
  <xsl:otherwise>
\HEMLevenRow
  </xsl:otherwise>
</xsl:choose>
\textbf{<xsl:value-of select="@id"/> [<xsl:call-template name="formatText"><xsl:with-param name="text" select="../context/@reference"/></xsl:call-template> {\S}<xsl:value-of select="@ref"/>]} &amp;
<xsl:choose>
   <xsl:when test="$failures!=0">\textbf{\color{hemlKoTextColor}Failures: <xsl:value-of select="$failures"/>}<xsl:if test="count(.//req)&gt;0"><xsl:text>

Unchecked requirements: <xsl:apply-templates select="req|assert[translate(@status,$upperCase,$lowerCase)!='ok' and translate(@status,$upperCase,$lowerCase)!='pass']/req"/></xsl:text></xsl:if></xsl:when>
   <xsl:otherwise>\textbf{\color{hemlOkTextColor}Pass}</xsl:otherwise>
</xsl:choose> \\
</xsl:template>
<!-- **********************************************************
     indexs
-->     
<xsl:template match="index[@type='req']">
\begin{HEMLtable}{|L|L|}
\hline
\HEMLoddHeadCell
\textbf{Requirement}&amp; \HEMLoddHeadCell \textbf{Referenced by} \\
\endhead
  <xsl:apply-templates select="/document/section//req" mode="index"/>
\hline
\end{HEMLtable}
</xsl:template>
<xsl:template match="req" mode="index">
  <xsl:param name="rid"><xsl:value-of select="@id"/></xsl:param>
<xsl:if test="@id!=''">
<xsl:choose>
  <xsl:when test="position() mod 2 = 0">
\HEMLoddRow
  </xsl:when>
  <xsl:otherwise>
\HEMLevenRow
  </xsl:otherwise>
</xsl:choose>
  <xsl:value-of select="@id"/>&amp;
    <xsl:choose>
      <xsl:when test="count(//req[text()=$rid])&gt;0">
	<xsl:apply-templates select="//req[text()=$rid]/.." mode="index"/>
      </xsl:when>
      <xsl:otherwise>No reference.</xsl:otherwise>
    </xsl:choose>
  \\  
</xsl:if>
</xsl:template>
<xsl:template match="*" mode="index">
<xsl:param name="num"><xsl:number count="section|references|definitions" level="multiple" format="1.1"/></xsl:param>
\S<xsl:value-of select="$num"/><xsl:text> </xsl:text>
</xsl:template>
<xsl:template match="check|procedure" mode="index">
<xsl:param name="num"><xsl:number count="section|references|definitions|check|procedure" level="multiple" format="1.1"/></xsl:param>
  <xsl:value-of select="name()"/><xsl:text> </xsl:text><xsl:value-of select="$num"/>
</xsl:template>
<xsl:template match="assert" mode="index">
<xsl:param name="num"><xsl:number count="section|references|definitions|check|procedure|assert" level="multiple" format="1.1"/></xsl:param>
  assert <xsl:value-of select="$num"/>
</xsl:template>

<xsl:template match="index[@type='tbc']">
\begin{HEMLtable}{|L|L|L|}
\hline
\HEMLoddHeadCell \textbf{ref} &amp; \HEMLoddHeadCell \textbf{location} &amp; \HEMLoddHeadCell \textbf{entitled}
\endhead
           <xsl:apply-templates select="//tbc" mode="index"/>
\hline
\end{HEMLtable}
</xsl:template>
<xsl:template match="index[@type='tbd']">
\begin{HEMLtable}{|L|L|L|}
\hline
\HEMLoddHeadCell \textbf{ref} &amp; \HEMLoddHeadCell \textbf{location} &amp; \HEMLoddHeadCell \textbf{entitled}
\endhead
           <xsl:apply-templates select="//tbd" mode="index"/>
\hline
\end{HEMLtable}
</xsl:template>
<xsl:template match="index[@type='comment']">
    <xsl:apply-templates select="//comment" mode="detail">
        <xsl:sort select="@id"/>
    </xsl:apply-templates>
</xsl:template>
<!--
     ##########################################################################
                Presentation/slides transformations
     ##########################################################################
-->
<xsl:template match="section" mode="slide">
<xsl:apply-templates mode="slide"/>
</xsl:template>
<xsl:template match="pnotes|speech"/>
<xsl:template match="slide" mode="slide">
\section*{<xsl:apply-templates select="@title"/>}
<xsl:apply-templates/>
\newpage
</xsl:template>
<!-- layout handling, resize, multi column, ... -->
<xsl:template match="layout">
<xsl:if test="@size!=''">
\begin{<xsl:value-of select="@size"/>}
<xsl:apply-templates/>
\end{<xsl:value-of select="@size"/>}
</xsl:if>
<xsl:if test="@col!=''">
\begin{multicols}{<xsl:value-of select="@col"/>}
<xsl:apply-templates/>
\end{multicols}
</xsl:if>
</xsl:template>
<!-- column break handling -->
<xsl:template match="break">
<!-- TODO should check parent is layout[@col>1] -->
\columnbreak
</xsl:template>
<!-- Presentation main -->
<xsl:template match="/presentation">
\input{<xsl:value-of select="$slideStyle"/>}
\renewcommand{\HEMLbuildinfo}{<xsl:call-template name="formatText"><xsl:with-param name="text" select="$buildinfo"/></xsl:call-template>}
\renewcommand{\HEMLorgName}{<xsl:value-of select="author/@sigle"/>}
\renewcommand{\HEMLreference}{<xsl:apply-templates select="reference"/>}
\renewcommand{\HEMLauthor}{<xsl:value-of select="author|authors"/>}
\renewcommand{\HEMLedition}{<xsl:value-of select="version"/>}
<xsl:if test="count(copyright)=1">
\renewcommand{\HEMLcopyright}{<xsl:value-of select="copyright/@year"/><xsl:text> </xsl:text><xsl:value-of select="copyright/@holder"/><xsl:text> </xsl:text><xsl:value-of select="copyright"/>}
</xsl:if>
\renewcommand{\HEMLrevision}{<xsl:call-template name="strreplace">
  <xsl:with-param name="text"><xsl:call-template name="strreplace">
    <xsl:with-param name="text"><xsl:value-of select="revision"/></xsl:with-param>
    <xsl:with-param name="from" select="'$Rev: '"/>		
    <xsl:with-param name="to" select="'r'"/>		
  </xsl:call-template></xsl:with-param>
  <xsl:with-param name="from" select="'$'"/>		
  <xsl:with-param name="to" select="' '"/>		
</xsl:call-template>}
\renewcommand{\HEMLdate}{<xsl:value-of select="date"/>}
\renewcommand{\HEMLtitle}{<xsl:apply-templates select="@title"/><xsl:apply-templates select="title/text()"/>}
<xsl:if test="count(titleImage)=1">\renewcommand{\HEMLtitleImage}{<xsl:value-of select="titleImage"/>}</xsl:if>
\title{<xsl:apply-templates select="@title"/><xsl:apply-templates select="title/text()"/>}
\author{\HEMLauthor}
\begin{document}
\maketitle
\input{code.sty}
\renewcommand{\HEMLcurSlideBG}{\HEMLslideBG}
<xsl:apply-templates select="section|slide" mode="slide"/>
\end{document}
</xsl:template>

</xsl:stylesheet>
