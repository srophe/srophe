<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t x saxon local" version="2.0">
    
    <!-- ================================================================== 
       citation.xsl
       
       This XSLT provides templates for output of citation guidance. 
       
       code by: 
       + Winona Salesky (wsalesky@gmail.com)
          for use with eXist-db
        + Tom Elliott (http://www.paregorios.org) 
          for the Institute for the Study of the Ancient World, New York
          University, under contract to Vanderbilt University for the
          NEH-funded Syriac Reference Portal project.
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->
    <xsl:variable name="uri" select="replace(//t:publicationStmt/t:idno[@type='URI'][1],'/tei','')"/>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate a footnote for the matched titleStmt element
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:titleStmt" mode="cite-foot">
        <!-- creator(s) of the entry -->
        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
        <xsl:sequence select="local:emit-responsible-persons(t:editor[@role='creator'],'footnote',1)"/>
        <xsl:text>, </xsl:text>
        
        <!-- title of the entry -->
        <xsl:text>“</xsl:text>
        <xsl:apply-templates select="t:title[@level='a'][1]" mode="footnote"/>
        <xsl:text>”</xsl:text>
        
        <!-- monographic title -->
        <xsl:text> in </xsl:text>
        <xsl:apply-templates select="../descendant::t:titleStmt/t:title[@level='m'][1]" mode="footnote"/>
        <xsl:text>, </xsl:text>
        
        <!-- publication date statement -->
        <xsl:text> last modified </xsl:text>
        <xsl:for-each select="../t:publicationStmt/t:date[1]">
            <xsl:choose>
                <xsl:when test=". castable as xs:date">
                    <xsl:value-of select="format-date(xs:date(.), '[MNn] [D], [Y]')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:text>,</xsl:text>
        
        <xsl:text> </xsl:text>
        <a href="{$uri}">
            <xsl:value-of select="$uri"/>
        </a>
        <xsl:text>.</xsl:text>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate a bibliographic entry for the matched titleStmt element
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:titleStmt" mode="cite-biblist">
        <!-- creator(s) of the entry -->
        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
        <xsl:sequence select="local:emit-responsible-persons(t:editor[@role='creator'],'biblist',1)"/>
        <xsl:text>, </xsl:text>
        
        <!-- title of the entry -->
        <xsl:text>“</xsl:text>
        <xsl:apply-templates select="t:title[@level='a'][1]" mode="biblist"/>
        <xsl:text>.”</xsl:text>
        
        <!-- monographic title -->
        <xsl:text> In </xsl:text>
        <xsl:apply-templates select="../descendant::t:titleStmt/t:title[@level='m'][1]" mode="footnote"/>
        
        <!-- general editors -->
        <xsl:text>, edited by </xsl:text>
        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
        <xsl:sequence select="local:emit-responsible-persons(t:editor[@role='general'],'footnote',20)"/>
        <xsl:text>.</xsl:text>
        <xsl:for-each select="../descendant::t:seriesStmt[1]">
            <!-- Add Series and Volumn -->
            <xsl:if test="t:biblScope[1]/@unit='vol'">
                <xsl:text> </xsl:text>
                <xsl:text>Vol. </xsl:text>
                <xsl:value-of select="../descendant::t:seriesStmt[1]/t:biblScope[1]/@from"/>
                <xsl:text> of </xsl:text>
                <xsl:value-of select="../descendant::t:seriesStmt[1]/t:title[@level='s'][1]"/>
            </xsl:if>
            <!-- general editors -->
            <xsl:text>, edited by </xsl:text>
            <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
            <xsl:sequence select="local:emit-responsible-persons(t:editor[@role='general'],'footnote',1)"/>
            <xsl:text>.</xsl:text>
        </xsl:for-each>
        <xsl:text> </xsl:text>
        <xsl:value-of select="../t:publicationStmt/t:authority"/>,
        <xsl:for-each select="../t:publicationStmt/t:date[1]">
            <xsl:choose>
                <xsl:when test=". castable as xs:date">
                    <xsl:value-of select="format-date(xs:date(.), '[Y]')"/>.
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>.
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <!-- publication date statement -->
        <xsl:text> Entry published </xsl:text>
        <xsl:for-each select="../t:publicationStmt/t:date[1]">
            <xsl:choose>
                <xsl:when test=". castable as xs:date">
                    <xsl:value-of select="format-date(xs:date(.), '[MNn] [D], [Y]')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:text>.</xsl:text>
        
        <xsl:text> </xsl:text>
        <a href="{$uri}">
            <xsl:value-of select="$uri"/>
        </a>
        <xsl:text>.</xsl:text>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate an "about this entry" section for the matched titleStmt element
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:titleStmt" mode="about">
        <p>
            <span class="heading-inline">Entry Title:</span>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="t:title[1]" mode="footnote"/>
        </p>
        <xsl:if test="t:publicationStmt/t:date">
            <p>
                <span class="heading-inline">Publication Date: </span>
                <xsl:text> </xsl:text>
                <xsl:for-each select="../t:publicationStmt/t:date[1]">
                    <xsl:choose>
                        <xsl:when test=". castable as xs:date">
                            <xsl:value-of select="format-date(xs:date(.), '[MNn] [D], [Y]')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </p>  
        </xsl:if>
        <xsl:if test="t:principal">
            <div>
                <h4>Authorial and Editorial Responsibility:</h4>
                <ul>
                    <li>
                        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
                        <xsl:sequence select="local:emit-responsible-persons-all(t:principal,'footnote')"/>
                        <xsl:text>, general editor</xsl:text>
                        <xsl:if test="count(t:principal) &gt; 1">s</xsl:if>
                        <xsl:text>, </xsl:text>
                        <xsl:value-of select="t:sponsor[1]"/>
                    </li>
                    <li>
                        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
                        <xsl:sequence select="local:emit-responsible-persons-all(t:editor[@role='general'],'footnote')"/>
                        <xsl:text>, editor</xsl:text>
                        <xsl:if test="count(t:editor[@role='general'])&gt; 1">s</xsl:if>
                        <xsl:text>, </xsl:text>
                        <xsl:apply-templates select="../descendant::t:titleStmt/t:title[@level='m'][1]" mode="footnote"/>
                    </li>
                    <li>
                        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
                        <xsl:sequence select="local:emit-responsible-persons-all(t:editor[@role= ('creator','contributor')],'biblist')"/>
                        <xsl:text>, entry contributor</xsl:text>
                        <xsl:if test="count(t:editor[@role='creator'])&gt; 1">s</xsl:if>
                        <xsl:text>, </xsl:text>
                        <xsl:text>“</xsl:text>
                        <xsl:apply-templates select="t:title[@level='a'][1]" mode="footnote"/>
                        <xsl:text>”</xsl:text>
                    </li>
                </ul>
            </div>            
        </xsl:if>
        <xsl:if test="t:respStmt">
            <div>
                <h4>Additional Credit:</h4>
                <ul>
                    <xsl:for-each select="t:respStmt">
                        <li>
                            <xsl:value-of select="t:resp"/>
                            <xsl:text> </xsl:text>
                            <xsl:apply-templates select="t:name" mode="footnote"/>
                        </li>
                    </xsl:for-each>
                </ul>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:titleStmt" mode="about-bibl">
        <xsl:variable name="entry-title" select="t:title[@level='a'][1]"/>
        <xsl:if test="t:publicationStmt/t:date">
            <p>
                <span class="heading-inline">Date Entry Added: </span>
                <xsl:text> </xsl:text>
                <xsl:for-each select="../t:publicationStmt/t:date[1]">
                    <xsl:choose>
                        <xsl:when test=". castable as xs:date">
                            <xsl:value-of select="format-date(xs:date(.), '[MNn] [D], [Y]')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </p>
        </xsl:if>
        <xsl:if test="t:principal">
            <div>
                <h4>Editorial Responsibility:</h4>
                <ul>
                    <li>
                        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
                        <xsl:sequence select="local:emit-responsible-persons-all(t:principal,'footnote')"/>
                        <xsl:text>, general editor</xsl:text>
                        <xsl:if test="count(t:principal) &gt; 1">s</xsl:if>
                        <xsl:text>, </xsl:text>
                        <xsl:value-of select="t:sponsor[1]"/>
                    </li>
                    <li>
                        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
                        <xsl:sequence select="local:emit-responsible-persons-all(t:editor[@role='general'],'footnote')"/>
                        <xsl:text>, editor</xsl:text>
                        <xsl:if test="count(t:editor[@role='general'])&gt; 1">s</xsl:if>
                        <xsl:text>, </xsl:text>
                        <em>
                            <xsl:value-of select="$collection-title"/>
                        </em>
                    </li>
                    <xsl:for-each select="t:editor[@role= ('creator','contributor')]">
                        <li>
                            <xsl:sequence select="local:emit-responsible-persons-all(.,'biblist')"/>
                            <xsl:text>, entry contributor</xsl:text>
                            <xsl:text>, </xsl:text>
                            <xsl:text>“</xsl:text>
                            <xsl:value-of select="//t:titleStmt/t:title[1]"/>
                            <xsl:text>”</xsl:text>
                        </li>
                    </xsl:for-each>
                </ul>
            </div>
        </xsl:if>
        <xsl:if test="t:respStmt">
            <div>
                <h4>Additional Credit:</h4>
                <ul>
                    <xsl:for-each select="t:respStmt">
                        <li>
                            <xsl:value-of select="t:resp"/>
                            <xsl:text> </xsl:text>
                            <xsl:apply-templates select="t:name" mode="footnote"/>
                        </li>
                    </xsl:for-each>
                </ul>
            </div>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>