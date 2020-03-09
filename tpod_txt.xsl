<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:my="functions" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:digest="java:org.apache.commons.codec.digest.DigestUtils" xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:rel="http://schemas.openxmlformats.org/package/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup" xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" xmlns:a14="http://schemas.microsoft.com/office/drawing/2010/main" xmlns:asvg="http://schemas.microsoft.com/office/drawing/2016/SVG/main" mc:Ignorable="w14 wp14">
  <xsl:output method="xml" version="1.0" indent="yes" encoding="UTF-8" standalone="yes"/>

  <xsl:param name="base.dir"/>
  <xsl:param name="input.name"/>

  <!-- gebruikte directories -->
  <xsl:param name="word.dir" select="fn:string-join((fn:tokenize($base.dir,'\\'),'temp','template','word'),'/')"/>
  <xsl:param name="text.dir" select="fn:string-join((fn:tokenize($base.dir,'\\'),'temp','text'),'/')"/>

  <!-- gebruikte documenten -->
  <xsl:param name="endnotes" select="fn:string-join(($word.dir,'endnotes.xml'),'/')"/>
  <xsl:param name="footnotes" select="fn:string-join(($word.dir,'footnotes.xml'),'/')"/>

  <!-- splits bestand op op basis van inhoudsopgave -->
  <xsl:param name="TOC" select="('Kop1','Kop2','Kop3','Kop4','Kop5','Kop2bijlage','Kop3bijlage')"/>

  <xsl:template name="tekstfragmenten">
    <xsl:param name="group"/>
    <xsl:for-each-group select="$group" group-starting-with="w:p[fn:index-of($TOC,(w:pPr/w:pStyle/@w:val,'Geen')[1]) gt 0]">
      <xsl:variable name="index" select="position()"/>
      <xsl:variable name="href">
        <xsl:variable name="check">
          <xsl:apply-templates select="current-group()[self::w:p][1]"/>
        </xsl:variable>
        <xsl:value-of select="fn:string-join((fn:format-number($index,'000'),my:uri($check)),'_')"/>
      </xsl:variable>
      <!-- maak document.txt -->
      <xsl:result-document href="{concat(fn:string-join(($text.dir,$href),'/'),'.txt')}" method="text">
        <xsl:apply-templates select="current-group()"/>
      </xsl:result-document>
    </xsl:for-each-group>
  </xsl:template>

  <!-- verwerk de root -->

  <xsl:template match="/">
    <xsl:for-each-group select="w:document/w:body/*" group-starting-with="w:p[w:pPr/w:pStyle/@w:val eq $TOC[1]][1]">
      <xsl:choose>
        <xsl:when test="position() eq 1">
          <!-- colofon -->
          <!--xsl:call-template name="colofon">
              <xsl:with-param name="group" select="current-group()"/>
            </xsl:call-template-->
        </xsl:when>
        <xsl:otherwise>
          <!-- tekstfragmenten -->
          <xsl:call-template name="tekstfragmenten">
            <xsl:with-param name="group" select="current-group()"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <!-- verwerk elementen voor berekening van de checksum -->

  <xsl:template match="element()">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="w:tc">
    <xsl:apply-templates/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="w:p">
    <xsl:for-each-group select="*" group-starting-with="w:r[w:fldChar]">
      <xsl:choose>
        <xsl:when test="current-group()[w:fldChar/@w:fldCharType='begin']">
          <xsl:value-of select="concat('[',fn:string-join((tokenize(fn:string-join(current-group()//w:instrText),'\s+|&quot;|\* MERGEFORMAT')[. ne '']),' '),']')"/>
        </xsl:when>
        <xsl:when test="current-group()[w:fldChar/@w:fldCharType='separate']">
          <!-- doe niets -->
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
    <xsl:if test="following-sibling::w:p">
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="w:r">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="w:t">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="w:tab">
    <xsl:text>&#9;</xsl:text>
  </xsl:template>

  <xsl:template match="w:instrText">
    <!-- doe niets -->
  </xsl:template>

  <xsl:template match="w:fldSimple">
    <xsl:value-of select="concat('[',normalize-space(@w:instr),']')"/>
  </xsl:template>

  <xsl:template match="w:EndnoteReference">
    <xsl:variable name="id" select="@w:id"/>
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="fn:document($endnotes,.)/w:Endnotes/w:Endnote[@w:id=$id]"/>
    <xsl:text>]</xsl:text>
  </xsl:template>

  <xsl:template match="w:EndnoteRef">
    <xsl:text>ENDNOTEREF</xsl:text>
  </xsl:template>

  <xsl:template match="w:footnoteReference">
    <xsl:variable name="id" select="@w:id"/>
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="fn:document($footnotes,.)/w:footnotes/w:footnote[@w:id=$id]"/>
    <xsl:text>]</xsl:text>
  </xsl:template>

  <xsl:template match="w:footnoteRef">
    <xsl:text>FOOTNOTEREF</xsl:text>
  </xsl:template>

  <xsl:template match="w:drawing">
    <xsl:text>[IMAGEREF]</xsl:text>
  </xsl:template>

  <!-- functies -->

  <xsl:function name="my:uri">
    <xsl:param name="string"/>
    <xsl:variable name="check_string">
      <!-- controleer op velden, noten, enzovoorts -->
      <xsl:for-each select="tokenize($string,'\[|\]')">
        <xsl:choose>
          <xsl:when test="contains(.,'NOTEREF')">
            <!-- doe niets -->
          </xsl:when>
          <xsl:otherwise>
            <xsl:for-each select="fn:string-to-codepoints(.)">
              <xsl:choose>
                <xsl:when test="(. ge 48) and (. le 57)">
                  <!-- cijfers -->
                  <node><xsl:value-of select="."/></node>
                </xsl:when>
                <xsl:when test="((. ge 65) and (. le 90)) or ((. ge 97) and (. le 122))">
                  <!-- letters -->
                  <node><xsl:value-of select="."/></node>
                </xsl:when>
                <xsl:when test="(. eq 45)">
                  <!-- dash -->
                  <node><xsl:value-of select="."/></node>
                </xsl:when>
                <xsl:when test="(. ge 224) and (. le 229)">
                  <!-- leestekens a -->
                  <node><xsl:value-of select="97"/></node>
                </xsl:when>
                <xsl:when test="(. eq 231)">
                  <!-- leestekens c -->
                  <node><xsl:value-of select="99"/></node>
                </xsl:when>
                <xsl:when test="(. ge 232) and (. le 235)">
                  <!-- leestekens e -->
                  <node><xsl:value-of select="101"/></node>
                </xsl:when>
                <xsl:when test="(. ge 236) and (. le 239)">
                  <!-- leestekens i -->
                  <node><xsl:value-of select="105"/></node>
                </xsl:when>
                <xsl:when test="(. eq 241)">
                  <!-- leestekens n -->
                  <node><xsl:value-of select="110"/></node>
                </xsl:when>
                <xsl:when test="(. ge 242) and (. le 246)">
                  <!-- leestekens o -->
                  <node><xsl:value-of select="111"/></node>
                </xsl:when>
                <xsl:when test="(. ge 249) and (. le 252)">
                  <!-- leestekens u -->
                  <node><xsl:value-of select="117"/></node>
                </xsl:when>
                <xsl:when test="(. eq 253) and (. eq 255)">
                  <!-- leestekens y -->
                  <node><xsl:value-of select="121"/></node>
                </xsl:when>
                <xsl:when test="(. eq 32)">
                  <!-- spatie -->
                  <node><xsl:value-of select="95"/></node>
                </xsl:when>
              </xsl:choose>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="fn:codepoints-to-string($check_string/node)"/>
  </xsl:function>

</xsl:stylesheet>