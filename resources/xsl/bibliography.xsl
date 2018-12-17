<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t x saxon local" version="2.0">

    <!-- ================================================================== 
       Copyright 2013 New York University
       
       This file is part of the Syriac Reference Portal Places Application.
       
       The Syriac Reference Portal Places Application is free software: 
       you can redistribute it and/or modify it under the terms of the GNU 
       General Public License as published by the Free Software Foundation, 
       either version 3 of the License, or (at your option) any later 
       version.
       
       The Syriac Reference Portal Places Application is distributed in 
       the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
       even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
       PARTICULAR PURPOSE.  See the GNU General Public License for more 
       details.
       
       You should have received a copy of the GNU General Public License
       along with the Syriac Reference Portal Places Application.  If not,
       see (http://www.gnu.org/licenses/).
       
       ================================================================== -->

    <!-- ================================================================== 
       bibliography.xsl
       
       This XSLT provides templates for output of bibliographic material. 
       
       parameters:
       
       assumptions and dependencies:
        + transform has been tested with Saxon PE 9.4.0.6 with initial
          template (-it) option set to "do-index" (i.e., there is no 
          single input file)
        
       code by:
        + Winona Salesky (http://www.wsalesky.com) 
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


    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate a Chicago style footnote for the matched bibl entry; if it contains a 
     pointer, try to look up the master bibliography file and use that
     
     For footnote and bibliography style citations. 
     Syriaca.org definition: 
     'footnote' = Chicago notes style
     'biblography' = Chicago bibliography style 
     See: http://www.chicagomanualofstyle.org/tools_citationguide.html
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate a Chicago style footnote for the matched bibl entry; if it contains a 
     pointer, try to look up the master bibliography file and use that
     
     For footnote and bibliography style citations. 
     Syriaca.org definition: 
     'footnote' = Chicago notes style
     'biblography' = Chicago bibliography style 
     See: http://www.chicagomanualofstyle.org/tools_citationguide.html
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    
   <xsl:param name="editoruriprefix">http://syriaca.org/documentation/editors.xml#</xsl:param>
   <xsl:variable name="editorssourcedoc">
       <xsl:if test="doc-available(concat('xmldb:exist://',$app-root,'/documentation/editors.xml'))">
           <xsl:sequence select="doc(concat('xmldb:exist://',$app-root,'/documentation/editors.xml'))"/>
       </xsl:if>
   </xsl:variable>
   
   <xsl:template match="t:bibl" mode="footnote">
        <xsl:param name="footnote-number">-1</xsl:param>
        <xsl:variable name="thisnum">
            <!-- Isolates footnote number in @xml:id-->
            <xsl:choose>
                <xsl:when test="$footnote-number='-1'">
                    <xsl:value-of select="substring-after(@xml:id, '-')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$footnote-number"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- When ptr is available, use full bibl record (indicated by ptr) -->
        <li class="tei-bibl footnote">
            <span class="anchor" id="{@xml:id}"/>
            <!-- Display footnote number -->
            <span class="tei-footnote-tgt">
                <xsl:value-of select="$thisnum"/>
            </span>
            <xsl:text> </xsl:text>
            <span class="tei-footnote-content">
                <xsl:call-template name="footnote"/>
            </span>
        </li>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate a Chicago style footnote for the matched bibl entry; if it contains a 
     pointer, try to look up the master bibliography file and use that
     
     assumption: you want the footnote included in a text item such as a <p> or <note>
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:bibl" mode="inline">
        <xsl:choose>
            <xsl:when test="parent::t:note">
                <xsl:choose>
                    <xsl:when test="t:ptr[contains(@target,'/work/')]">
                        <a href="{t:ptr/@target}">
                            <xsl:apply-templates mode="footnote"/>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="footnote"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="text()">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="footnote"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     Named template used by inline and list style footnotes. 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="footnote">
        <xsl:variable name="passThrough">
            <xsl:if test="not(empty(t:biblScope))">
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="t:biblScope" mode="footnote"/>
            </xsl:if>
            <xsl:if test="not(empty(t:citedRange))">
                <xsl:text>, </xsl:text>
                <xsl:for-each select="t:citedRange">
                    <xsl:apply-templates select="." mode="footnote"/>
                    <xsl:if test="not(last())">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
            <xsl:if test="not(empty(t:date))">
                <xsl:text> (</xsl:text>
                <xsl:for-each select="t:date">
                    <xsl:apply-templates select="." mode="footnote"/>
                </xsl:for-each>
                <xsl:text>) </xsl:text>
            </xsl:if>
            <xsl:if test="not(empty(t:note))">
                <xsl:text> </xsl:text>
                <xsl:for-each select="t:note">
                    <span class="note">Note: <xsl:apply-templates select="." mode="plain"/>
                        <xsl:if test="not(ends-with(.,'.'))">
                            <xsl:text>.</xsl:text>
                        </xsl:if>
                    </span>
                </xsl:for-each>
            </xsl:if>
        </xsl:variable>
        <span class="footnote-content">
            <xsl:choose>
                <xsl:when test="descendant::t:ptr[@target and starts-with(@target, '#')]">
                    <xsl:variable name="target" select="substring-after(descendant::t:ptr/@target,'#')"/>
                    <xsl:for-each select="descendant::t:bibl[@xml:id = $target]">
                        <xsl:choose>
                            <xsl:when test="descendant::t:ptr[@target and starts-with(@target, concat($base-uri,'/bibl/'))]">
                                <!-- Find file path for bibliographic record -->
                                <xsl:variable name="biblfilepath">
                                    <xsl:value-of select="concat('xmldb:exist://',$data-root,'/bibl/tei/',substring-after(t:ptr/@target, concat($base-uri,'/bibl/')),'.xml')"/>
                                </xsl:variable>
                                <xsl:choose>
                                    <xsl:when test="doc-available($biblfilepath)">
                                        <xsl:variable name="rec" select="document($biblfilepath)"/>
                                        <xsl:for-each select="$rec/descendant::t:biblStruct">
                                            <xsl:apply-templates mode="footnote"/>
                                            <xsl:sequence select="$passThrough"/>
                                            <xsl:if test="descendant::t:idno[@type='URI']">
                                                <span class="footnote-links">
                                                  <xsl:apply-templates select="descendant::t:idno[@type='URI']" mode="links"/>
                                                  <xsl:apply-templates select="descendant::t:ref[not(ancestor::note)]" mode="links"/>
                                                </span>
                                            </xsl:if>
                                        </xsl:for-each>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:apply-templates mode="footnote"/>
                                        <xsl:sequence select="$passThrough"/>
                                        <xsl:if test="descendant::t:idno[@type='URI']">
                                            <span class="footnote-links">
                                                <xsl:apply-templates select="descendant::t:idno[@type='URI']" mode="links"/>
                                                <xsl:apply-templates select="descendant::t:ref[not(ancestor::note)]" mode="links"/>
                                            </span>
                                        </xsl:if>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="persons"/>
                                <xsl:text> </xsl:text>
                                <xsl:for-each select="t:title">
                                    <xsl:apply-templates select="self::*" mode="footnote"/>
                                    <xsl:if test="following-sibling::t:title[@level = 'j']">
                                        <xsl:text> In</xsl:text>
                                    </xsl:if>
                                    <xsl:if test="position() != last()">
                                        <xsl:text> </xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                                <xsl:sequence select="$passThrough"/>
                                <xsl:if test="descendant::t:idno[@type='URI']">
                                    <span class="footnote-links">
                                        <xsl:apply-templates select="descendant::t:idno[@type='URI']" mode="links"/>
                                        <xsl:apply-templates select="descendant::t:ref[not(ancestor::note)]" mode="links"/>
                                    </span>
                                </xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="descendant::t:ptr[@target and starts-with(@target, concat($base-uri,'/bibl/'))]">
                    <xsl:variable name="biblfilepath">
                        <xsl:value-of select="concat('xmldb:exist://',$data-root,'/bibl/tei/',substring-after(t:ptr/@target, concat($base-uri,'/bibl/')),'.xml')"/>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="doc-available($biblfilepath)">
                            <xsl:variable name="rec" select="document($biblfilepath)"/>
                            <xsl:for-each select="$rec/descendant::t:biblStruct">
                                <xsl:apply-templates mode="footnote"/>
                                <xsl:sequence select="$passThrough"/>
                                <xsl:if test="descendant::t:idno[@type='URI']">
                                    <span class="footnote-links">
                                        <xsl:apply-templates select="descendant::t:idno[@type='URI']" mode="links"/>
                                        <xsl:apply-templates select="descendant::t:ref[not(ancestor::note)]" mode="links"/>
                                    </span>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="footnote"/>
                            <xsl:sequence select="$passThrough"/>
                            <xsl:if test="descendant::t:idno[@type='URI']">
                                <span class="footnote-links">
                                    <xsl:apply-templates select="descendant::t:idno[@type='URI']" mode="links"/>
                                    <xsl:apply-templates select="descendant::t:ref[not(ancestor::note)]" mode="links"/>
                                </span>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="child::*">
                            <xsl:call-template name="persons"/>
                            <xsl:text> </xsl:text>
                            <xsl:for-each select="t:title">
                                <xsl:apply-templates select="self::*" mode="footnote"/>
                                <xsl:if test="following-sibling::t:title[@level = 'j']">
                                    <xsl:text> In</xsl:text>
                                </xsl:if>
                                <xsl:if test="position() != last()">
                                    <xsl:text> </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:apply-templates select="text()"/>
                            <xsl:sequence select="$passThrough"/>
                            <xsl:if test="descendant::t:idno[@type='URI']">
                                <span class="footnote-links">
                                    <xsl:apply-templates select="descendant::t:idno[@type='URI']" mode="links"/>
                                    <xsl:apply-templates select="descendant::t:ref[not(ancestor::note)]" mode="links"/>
                                </span>
                            </xsl:if>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </span>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     Main footnote templates for bibl records. 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:biblStruct" mode="footnote">
        <xsl:apply-templates mode="footnote"/>
    </xsl:template>
    <xsl:template match="t:biblStruct" mode="bibliography">
        <xsl:apply-templates mode="bibliography"/>
    </xsl:template>

    <!-- handle a biblist entry for a book -->
    <xsl:template match="t:biblStruct[t:monogr and not(t:analytic)]" mode="biblist">
        <!-- this is a monograph/book -->
        <xsl:apply-templates select="t:monogr" mode="footnote"/>
    </xsl:template>

    <!--  
        generate a bibl list entry for the matched bibl; if it contains a 
        pointer, try to look up the master bibliography file and use that 
    -->
    <xsl:template match="t:bibl" mode="biblist">
        <xsl:choose>
            <xsl:when test="t:ptr">
                <xsl:apply-templates select="t:ptr" mode="biblist"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="biblist"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- 
     handle a ptr inside a bibl: try to look up the corresponding item
     internally or externally and process that
     -->
    <xsl:template match="t:ptr[name(ancestor::t:*[1]) = 'bibl']" mode="biblist">
        <xsl:if test="starts-with(@target, '#')">
            <xsl:variable name="thistarget" select="substring-after(@target, '#')"/>
            <xsl:for-each select="//t:bibl[@xml:id=$thistarget]">
                <xsl:call-template name="footnote"/>
            </xsl:for-each>
            <!--<xsl:apply-templates select="//t:bibl[@xml:id=$thistarget]" mode="footnote"/>-->
        </xsl:if>
        <xsl:if test="starts-with(@target, concat($base-uri,'/bibl/'))">
            <!--<xsl:variable name="biblfilepath" select="replace(replace($base-uri, concat('xmldb:exist://',$data-root)),'/bibl/','/bibl/tei/')"/>-->
            <xsl:variable name="biblfilepath" select="concat(replace(replace(@target,$base-uri,concat('xmldb:exist://',$data-root)),'/bibl/','/bibl/tei/'),'.xml')"/>
            <!--
            <xsl:variable name="biblfilepath">
                <xsl:value-of select="concat(concat('xmldb:exist://',$data-root,'/bibl/tei/',substring-after(@target, concat($base-uri,'/bibl/')),'.xml')"/>
            </xsl:variable>
            -->
            <xsl:if test="doc-available($biblfilepath)">
                <xsl:apply-templates select="document($biblfilepath)/descendant::t:biblStruct[1]" mode="biblist"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- Structure of analytic section.  -->
    <xsl:template match="t:analytic" mode="footnote">
        <!-- Display authors/editors -->
        <xsl:call-template name="persons"/>
        <!-- Analytic title(s) -->
        <xsl:choose>
            <xsl:when test="t:title[starts-with(@xml:lang,'en')]">
                <xsl:text> "</xsl:text>
                <xsl:apply-templates select="t:title[starts-with(@xml:lang,'en')][1]" mode="footnote"/>
                <xsl:if test="not(ends-with(t:title[starts-with(@xml:lang,'en')][1],'.|:|,'))">.</xsl:if>
                <xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> "</xsl:text>
                <xsl:apply-templates select="t:title[1]" mode="footnote"/>
                <xsl:if test="not(ends-with(t:title[starts-with(@xml:lang,'en')][1],'.|:|,'))">.</xsl:if>
                <xsl:text>"</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <!-- If monograph is level='m' include 'in' -->
        <xsl:if test="following-sibling::t:monogr/t:title[1][@level='m']">
            <xsl:text> in</xsl:text>
        </xsl:if>
        <!-- Space if followed by monograph -->
        <xsl:if test="following-sibling::t:monogr">
            <xsl:text> </xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- Structure of analytic section.  -->
    <xsl:template match="t:analytic" mode="bibliography">
        <!-- Display authors/editors -->
        <xsl:call-template name="persons-bibliography"/>
        <xsl:text>, </xsl:text>
        <!-- Analytic title(s) -->
        <xsl:choose>
            <xsl:when test="t:title[starts-with(@xml:lang,'en')]">
                <xsl:text> "</xsl:text>
                <xsl:apply-templates select="t:title[starts-with(@xml:lang,'en')][1]" mode="footnote"/>
                <xsl:if test="not(ends-with(t:title[starts-with(@xml:lang,'en')][1],'.|:|,'))">.</xsl:if>
                <xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> "</xsl:text>
                <xsl:apply-templates select="t:title[1]" mode="footnote"/>
                <xsl:if test="not(ends-with(t:title[starts-with(@xml:lang,'en')][1],'.|:|,'))">.</xsl:if>
                <xsl:text>"</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <!-- If monograph is level='m' include 'in' -->
        <xsl:if test="following-sibling::*[1][self::t:monogr]/t:title[1][@level='m']">
            <xsl:text> In</xsl:text>
        </xsl:if>
        <!-- Space if followed by monograph -->
        <xsl:if test="following-sibling::*[1][self::t:monogr]">
            <xsl:text> </xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- Structure of monograph section.  -->
    <xsl:template match="t:monogr" mode="footnote">
        <!-- Display authors/editors -->
        <!-- Suppress duplicate authors for records with multiple t:monogr elements -->
        <xsl:choose>
            <xsl:when test="preceding-sibling::t:monogr">
                <xsl:choose>
                    <xsl:when test="deep-equal(t:editor | t:author, preceding-sibling::t:monogr/t:editor | preceding-sibling::t:monogr/t:author )"/>
                    <xsl:otherwise>
                        <xsl:call-template name="persons"/>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- Check authors against preceding, suppress if equivalent -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="persons"/>
            </xsl:otherwise>
        </xsl:choose>
        <!-- Titles -->
        <xsl:choose>
            <xsl:when test="t:title[starts-with(@xml:lang,'en')]">
                <xsl:apply-templates select="t:title[starts-with(@xml:lang,'en')][1]" mode="footnote"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="t:title[1]" mode="footnote"/>
            </xsl:otherwise>
        </xsl:choose>
        <!-- handle translator, if present -->
        <xsl:if test="count(t:editor[@role='translator']) &gt; 0">
            <xsl:text>, trans. </xsl:text>
            <!-- Process translator using local function in helper-functions.xsl local:emit-responsible-persons -->
            <xsl:sequence select="local:emit-responsible-persons(t:editor[@role='translator'],'footnote',3)"/>
        </xsl:if>
        <!-- Add edition  -->
        <xsl:if test="t:edition">
            <xsl:text>, </xsl:text>
            <xsl:choose>
                <xsl:when test="t:edition[starts-with(@xml:lang,'en')]">
                    <xsl:apply-templates select="t:edition[starts-with(@xml:lang,'en')][1]" mode="footnote"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="t:edition[1]" mode="footnote"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text> </xsl:text>
        </xsl:if>
        <!-- Add vol  -->
        <xsl:if test="t:biblScope[@unit='vol']">
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="t:biblScope[@unit='vol']" mode="footnote"/>
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="following-sibling::t:series">
                <xsl:apply-templates select="t:series" mode="footnote"/>
            </xsl:when>
            <xsl:when test="following-sibling::t:monogr">
                <xsl:text>, </xsl:text>
            </xsl:when>
            <xsl:when test="preceding-sibling::t:monogr and preceding-sibling::t:monogr/t:imprint[child::*[string-length(.) &gt; 0]]">
                <xsl:text> (</xsl:text>
                <xsl:apply-templates select="preceding-sibling::t:monogr/t:imprint" mode="footnote"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="t:imprint[child::*[string-length(.) &gt; 0]]">
                    <xsl:text> (</xsl:text>
                    <xsl:apply-templates select="t:imprint" mode="footnote"/>
                    <xsl:text>)</xsl:text>
                </xsl:if>
                <xsl:if test="following-sibling::t:monogr">
                    <xsl:text>, </xsl:text>
                </xsl:if>
                <xsl:if test="not(following-sibling::*)">
                    <xsl:text>.</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Structure of monograph section.  -->
    <xsl:template match="t:monogr" mode="bibliography">
        <!-- Display authors/editors -->
        <!-- Suppress duplicate authors for records with multiple t:monogr elements -->
        <xsl:choose>
            <xsl:when test="preceding-sibling::*[1][self::t:analytic]"/>
            <xsl:when test="preceding-sibling::*[1][self::t:monogr]">
                <xsl:choose>
                    <xsl:when test="deep-equal(t:editor | t:author, preceding-sibling::t:monogr[1]/t:editor | preceding-sibling::t:monogr[1]/t:author )"/>
                    <xsl:otherwise>
                        <xsl:call-template name="persons-bibliography"/>
                        <xsl:text>, </xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- Check authors against preceding, suppress if equivalent -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="persons-bibliography"/>
                <xsl:text>, </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <!-- Titles -->
        <xsl:choose>
            <xsl:when test="t:title[starts-with(@xml:lang,'en')]">
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="t:title[starts-with(@xml:lang,'en')][1]" mode="footnote"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="t:title[1]" mode="footnote"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="preceding-sibling::*[1][self::t:analytic]">
                <xsl:text>, </xsl:text>
                <xsl:call-template name="persons-bibliography"/>
                <xsl:if test="t:title[@level='m'] and t:biblScope[(@unit != 'vol' and @unit != 'series') or not(@unit)]">
                    <xsl:for-each select="t:biblScope[(@unit != 'vol' and @unit != 'series') or not(@unit)]">
                        <xsl:text>, </xsl:text>
                        <xsl:apply-templates select="." mode="footnote"/>
                    </xsl:for-each>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <!-- Suppress '.' based on feedback here: https://github.com/srophe/syriac-corpus-app/issues/111 open to re-evaluate -->
<!--                <xsl:text>. </xsl:text>-->
            </xsl:otherwise>
        </xsl:choose>

        <!-- handle translator, if present -->
        <xsl:if test="count(t:editor[@role='translator']) &gt; 0">
            <xsl:text> Translated by </xsl:text>
            <!-- Process translator using local function in helper-functions.xsl local:emit-responsible-persons -->
            <xsl:sequence select="local:emit-responsible-persons-all(t:editor[@role='translator'],'biblist')"/>
        </xsl:if>

        <!-- Add edition  -->
        <xsl:if test="t:edition">
            <xsl:text>. </xsl:text>
            <xsl:choose>
                <xsl:when test="t:edition[starts-with(@xml:lang,'en')]">
                    <xsl:apply-templates select="t:edition[starts-with(@xml:lang,'en')][1]" mode="footnote"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="t:edition[1]" mode="footnote"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text> </xsl:text>
        </xsl:if>

        <!-- Add vol  -->
        <xsl:if test="t:biblScope[@unit='vol']">
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="t:biblScope[@unit='vol']" mode="footnote"/>
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="following-sibling::*[1][self::t:series]">
                <xsl:apply-templates select="following-sibling::*[1][self::t:series]" mode="footnote"/>
            </xsl:when>
            <xsl:when test="following-sibling::*[1][self::t:monogr]">
                <xsl:text>, </xsl:text>
            </xsl:when>
            <xsl:when test="preceding-sibling::*[1][self::t:monogr]">
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="preceding-sibling::t:monogr[1]/t:imprint" mode="footnote"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="preceding-sibling::*[1][self::t:analytic]">
                        <xsl:choose>
                            <xsl:when test="t:title[@level='j'] and t:imprint[child::*[string-length(.) &gt; 0]]">
                                <xsl:text> (</xsl:text>
                                <xsl:apply-templates select="t:imprint" mode="footnote"/>
                                <xsl:text>)</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text> </xsl:text>
                                <xsl:apply-templates select="t:imprint" mode="footnote"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>, (</xsl:text>
                        <xsl:apply-templates select="t:imprint" mode="footnote"/>
                        <xsl:text>)</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="following-sibling::*[1][self::t:monogr]">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="t:title[@level='j'] and t:biblScope[(@unit != 'vol' and @unit != 'series') or not(@unit)]">
            <xsl:for-each select="t:biblScope[(@unit != 'vol' and @unit != 'series') or not(@unit)]">
                <xsl:text>: </xsl:text>
                <xsl:value-of select="."/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- Series output -->
    <xsl:template match="t:series" mode="footnote">
        <xsl:choose>
            <xsl:when test="preceding-sibling::t:monogr/t:title[@level='j']">
                <xsl:text> (=</xsl:text>
            </xsl:when>
            <xsl:when test="preceding-sibling::t:series">
                <xsl:text>; </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>, </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="t:title[starts-with(@xml:lang,'en')]">
                <xsl:apply-templates select="t:title[starts-with(@xml:lang,'en')][1]" mode="footnote"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="t:title[1]" mode="footnote"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="t:biblScope">
            <xsl:text>, </xsl:text>
            <xsl:for-each select="t:biblScope[@unit='series'] | t:biblScope[@unit='vol'] | t:biblScope[@unit='tomus']">
                <xsl:apply-templates select="." mode="footnote"/>
                <xsl:if test="position() != last()">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
        <xsl:if test="preceding-sibling::t:monogr/t:title[@level='j']">
            <xsl:text>)</xsl:text>
        </xsl:if>
        <xsl:if test="preceding-sibling::t:monogr/t:imprint and not(following-sibling::t:series)">
            <xsl:text> (</xsl:text>
            <xsl:apply-templates select="preceding-sibling::t:monogr/t:imprint" mode="footnote"/>
            <xsl:text>)</xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- Series output -->
    <xsl:template match="t:series" mode="bibliography">
        <xsl:choose>
            <xsl:when test="preceding-sibling::t:monogr"/>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="t:title[starts-with(@xml:lang,'en')]">
                        <xsl:apply-templates select="t:title[starts-with(@xml:lang,'en')][1]" mode="footnote"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="t:title[1]" mode="footnote"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="t:biblScope">
                    <xsl:text>, </xsl:text>
                    <xsl:for-each select="t:biblScope[@unit='series'] | t:biblScope[@unit='vol'] | t:biblScope[@unit='tomus']">
                        <xsl:apply-templates select="." mode="footnote"/>
                        <xsl:if test="position() != last()">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:if>
                <xsl:if test="preceding-sibling::t:monogr/t:imprint and not(following-sibling::t:series)">
                    <xsl:text>. </xsl:text>
                    <xsl:apply-templates select="preceding-sibling::t:monogr/t:imprint" mode="footnote"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="preceding-sibling::t:series">
            <xsl:text>; </xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     Template parses authors and editors for analytic and monograph sections
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="persons">
        <!-- If edited -->
        <xsl:variable name="edited" select="if (t:editor[not(@role) or @role!='translator']) then true() else false()"/>
        <!-- count editors/authors  -->
        <xsl:variable name="rcount">
            <xsl:choose>
                <xsl:when test="t:author">
                    <xsl:value-of select="count(t:author)"/>
                </xsl:when>
                <xsl:when test="$edited">
                    <xsl:value-of select="count(t:editor[not(@role) or @role!='translator'])"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="count(t:author)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="bookAuth">
            <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
            <xsl:choose>
                <xsl:when test="t:author">
                    <xsl:sequence select="local:emit-responsible-persons(t:author,'footnote',3)"/>
                </xsl:when>
                <xsl:when test="$edited">
                    <xsl:sequence select="local:emit-responsible-persons(t:editor[not(@role) or @role!='translator'],'footnote',3)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="local:emit-responsible-persons(t:author,'footnote',3)"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="not(t:author)">
                <xsl:if test="$edited">
                    <xsl:choose>
                        <xsl:when test="$rcount = 1">
                            <xsl:text> (ed.)</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text> (eds.)</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </xsl:if>
        </xsl:variable>
        <xsl:if test="$rcount &gt; 0">
            <xsl:value-of select="normalize-space($bookAuth)"/>
            <xsl:if test="$bookAuth != ''">
                <xsl:text>, </xsl:text>
            </xsl:if>
            <!--
            <xsl:choose>
                <xsl:when test="self::t:monogr and not(preceding-sibling::t:analytic)">
                    <xsl:text>. </xsl:text>
                </xsl:when>
                <xsl:when test="$bookAuth != ''">
                    <xsl:text>, </xsl:text>
                </xsl:when>
            </xsl:choose>
            -->
        </xsl:if>
    </xsl:template>
    <xsl:template name="persons-bibliography">
        <!-- If edited -->
        <xsl:variable name="edited" select="if(t:editor[not(@role) or @role != 'translator']) then true() else false()"/>
        <!-- count editors/authors  -->
        <xsl:variable name="rcount">
            <xsl:choose>
                <xsl:when test="t:author">
                    <xsl:value-of select="count(t:author)"/>
                </xsl:when>
                <xsl:when test="$edited">
                    <xsl:value-of select="count(t:editor[not(@role) or @role!='translator'])"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="count(t:author)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="bookAuth">
            <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
            <xsl:choose>
                <xsl:when test="preceding-sibling::t:analytic">
                    <xsl:choose>
                        <xsl:when test="t:author">
                            <xsl:sequence select="local:emit-responsible-persons(t:author,'footnote',3)"/>
                        </xsl:when>
                        <xsl:when test="$edited">
                            <xsl:sequence select="local:emit-responsible-persons(t:editor[not(@role) or @role!='translator'],'footnote',3)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="local:emit-responsible-persons(t:author,'footnote',3)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$edited">
                    <xsl:sequence select="local:emit-responsible-persons-all(t:editor[not(@role) or @role!='translator'],'footnote')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="local:emit-responsible-persons-all(t:author,'footnote')"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="not(t:author)">
                <xsl:if test="$edited">
                    <xsl:choose>
                        <xsl:when test="$rcount = 1">
                            <xsl:text>, ed.</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>, eds.</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </xsl:if>
        </xsl:variable>
        <xsl:if test="$rcount &gt; 0">
            <xsl:value-of select="normalize-space($bookAuth)"/>
            <!--
            <xsl:if test="not(ends-with(normalize-space($bookAuth),'.'))">
                <xsl:text>. </xsl:text>
            </xsl:if>
            -->
        </xsl:if>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle name components in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:forename | t:addName | t:surname" mode="footnote biblist" priority="1">
        <xsl:if test="preceding-sibling::t:*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates mode="footnote"/>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle authors and editors in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:author | t:editor | t:principal | t:person | t:persName | t:name" mode="footnote biblist" priority="1">
        <xsl:choose>
            <xsl:when test="@ref and starts-with(@ref, $editoruriprefix) and not(empty($editorssourcedoc))">
                <xsl:variable name="sought" select="substring-after(@ref, $editoruriprefix)"/>
                <xsl:choose>
                    <xsl:when test="$editorssourcedoc/descendant::t:body/t:listPerson[1]/t:person[@xml:id=$sought][1]">
                        <xsl:apply-templates select="$editorssourcedoc/descendant::t:body/t:listPerson[1]/t:person[@xml:id=$sought][1]" mode="footnote"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!--NOTE: Added preceding space for dealing with names in titles (ex: /bibl/670), check for issues.  -->
                        <span>
                            <xsl:text> </xsl:text>
                            <xsl:choose>
                                <xsl:when test="t:persName[starts-with(@xml:lang,'en')]">
                                    <xsl:apply-templates select="t:persName[starts-with(@xml:lang,'en')][1]" mode="footnote"/>
                                </xsl:when>
                                <xsl:when test="t:persName">
                                    <xsl:apply-templates select="t:persName[1]" mode="footnote"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates mode="footnote"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <!--<xsl:text> </xsl:text>-->
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!--NOTE: Added preceding space for dealing with names in titles (ex: /bibl/670), check for issues.  -->
                <span>
                    <xsl:text> </xsl:text>
                    <xsl:choose>
                        <xsl:when test="t:persName[starts-with(@xml:lang,'en')]">
                            <xsl:apply-templates select="t:persName[starts-with(@xml:lang,'en')][1]" mode="footnote"/>
                        </xsl:when>
                        <xsl:when test="t:persName">
                            <xsl:apply-templates select="t:persName[1]" mode="footnote"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="footnote"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!--<xsl:text> </xsl:text>-->
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle authors and editors in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:author | t:editor | t:principal | t:person | t:persName | t:name" mode="lastname-first" priority="1">
        <xsl:choose>
            <!-- if @ref exists use external editors.xml document from database -->
            <xsl:when test="@ref and starts-with(@ref, $editoruriprefix) and not(empty($editorssourcedoc))">
                <xsl:variable name="sought" select="substring-after(@ref, $editoruriprefix)"/>
                <xsl:choose>
                    <xsl:when test="$editorssourcedoc/descendant::t:body/t:listPerson[1]/t:person[@xml:id=$sought][1]">
                        <xsl:apply-templates select="$editorssourcedoc/descendant::t:body/t:listPerson[1]/t:person[@xml:id=$sought][1]" mode="footnote"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="{local-name()}">
                            <xsl:choose>
                                <xsl:when test="t:surname and t:forename">
                                    <xsl:value-of select="concat(normalize-space(t:surname/text()),', ')"/>
                                    <xsl:apply-templates select="t:*[local-name()!='surname']" mode="footnote"/>
                                </xsl:when>
                                <xsl:when test="t:persName">
                                    <xsl:for-each select="t:persName">
                                        <xsl:choose>
                                            <xsl:when test="t:surname and t:forename">
                                                <xsl:value-of select="concat(normalize-space(t:surname/text()),', ')"/>
                                                <xsl:apply-templates select="t:*[local-name()!='surname']" mode="footnote"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:apply-templates select="t:*" mode="footnote"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates mode="lastname-first"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- otherwise processes name as exists in place page -->
            <xsl:otherwise>
                <span class="{local-name()}">
                    <xsl:choose>
                        <xsl:when test="t:surname and t:forename">
                            <xsl:value-of select="concat(normalize-space(t:surname/text()),', ')"/>
                            <xsl:apply-templates select="t:*[local-name()!='surname']" mode="footnote"/>
                        </xsl:when>
                        <xsl:when test="t:persName">
                            <xsl:for-each select="t:persName">
                                <xsl:choose>
                                    <xsl:when test="t:surname and t:forename">
                                        <xsl:value-of select="concat(normalize-space(t:surname/text()),', ')"/>
                                        <xsl:apply-templates select="t:*[local-name()!='surname']" mode="footnote"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:apply-templates select="t:*" mode="footnote"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="lastname-first"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle date, publisher, place of publication, placenames and foreign
     tags (i.e., language+script changes) in footnote context (the main
     reason for this is to capture language and script changes at these
     levels)
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:date | t:publisher | t:pubPlace | t:placeName | t:foreign" mode="footnote" priority="1">
        <xsl:if test="(preceding-sibling::* and name(.) != 'pubPlace')">
            <xsl:text> </xsl:text>
        </xsl:if>
        <span class="{local-name()}">
            <xsl:sequence select="local:attributes(.)"/>
            <xsl:apply-templates mode="footnote"/>
        </span>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle the imprint component of a biblScope
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:edition" mode="footnote">
        <!--<xsl:text>(</xsl:text>-->
        <xsl:value-of select="local:ordinal(text())"/>
        <!--<xsl:text>)</xsl:text>-->
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle the imprint component of a biblScope
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:biblScope" mode="footnote">
        <xsl:variable name="unit">
            <xsl:choose>
                <xsl:when test="@unit = 'vol'">
                    <xsl:value-of select="concat(@unit,'.')"/>
                </xsl:when>
                <xsl:when test="@unit != ''">
                    <xsl:value-of select="@unit"/>
                </xsl:when>
                <xsl:when test="@type != ''">
                    <xsl:value-of select="@type"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="matches(text(),'^\d')">
                <xsl:value-of select="concat($unit,' ',text())"/>
            </xsl:when>
            <xsl:when test="not(text()) and (@to or @from)">
                <xsl:choose>
                    <xsl:when test="@to = @from">
                        <xsl:value-of select="concat($unit,' ',@to)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($unit,' ',@from,' - ',@to)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="text()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle the imprint component of a biblStruct
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:imprint" mode="footnote biblist" priority="1">
        <xsl:choose>
            <xsl:when test="t:pubPlace[starts-with(@xml:lang,'en')]">
                <xsl:apply-templates select="t:pubPlace[starts-with(@xml:lang,'en')]" mode="footnote"/>
            </xsl:when>
            <xsl:when test="t:pubPlace">
                <xsl:apply-templates select="t:pubPlace[1]" mode="footnote"/>
            </xsl:when>
        </xsl:choose>
        <xsl:if test="t:pubPlace and t:publisher">
            <xsl:text>: </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="t:publisher[starts-with(@xml:lang,'en')]">
                <xsl:apply-templates select="t:publisher[starts-with(@xml:lang,'en')]" mode="footnote"/>
            </xsl:when>
            <xsl:when test="t:publisher">
                <xsl:apply-templates select="t:publisher[1]" mode="footnote"/>
            </xsl:when>
        </xsl:choose>
        <!-- For Monographs only -->
        <xsl:if test="not(t:pubPlace) and not(t:publisher) and t:title[@level='m']">
            <abbr title="no publisher">n.p.</abbr>
        </xsl:if>
        <xsl:if test="t:date/preceding-sibling::*">
            <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="t:date">
                <xsl:apply-templates select="t:date" mode="footnote"/>
            </xsl:when>
            <xsl:otherwise>
                <abbr title="no date of publication">n.d.</abbr>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="following-sibling::t:biblScope[@unit='series']">
            <xsl:text>, </xsl:text>
            <xsl:apply-templates select="../t:biblScope[@unit='series']" mode="footnote"/>
        </xsl:if>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle cited ranges in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:citedRange[ancestor::t:bibl or ancestor::t:biblStruct]" mode="footnote" priority="1">
        <xsl:choose>
            <xsl:when test="@unit = preceding-sibling::*[1]/@unit"/>
            <xsl:when test="@unit='ff'"/>
            <xsl:otherwise>
                <xsl:value-of select="concat(@unit,': ')"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="@target">
                <a href="{@target}">
                    <xsl:choose>
                        <xsl:when test="@unit='ff'">
                            <xsl:text>, f. </xsl:text>
                            <xsl:apply-templates select="." mode="out-normal"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="." mode="out-normal"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="@unit='ff'">
                        <xsl:text>, f. </xsl:text>
                        <xsl:apply-templates select="." mode="out-normal"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="." mode="out-normal"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:for-each select="t:note[not(@type='flag')]">
            <xsl:text> (</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>) </xsl:text>
        </xsl:for-each>
        <xsl:choose>
            <xsl:when test="following-sibling::*[not(self::t:ptr)]">, </xsl:when>
            <xsl:otherwise>
                <xsl:if test="not(ends-with(.,'.'))">
                    <xsl:text>.</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:idno" mode="footnote">
        <!-- IDNO should use mode="links" not mode footnote. 
        <xsl:text> </xsl:text>
        <span class="footnote idno">
            <xsl:apply-templates/>
        </span>
        -->
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle bibliographic titles in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:title" mode="footnote biblist allbib" priority="1">
        <xsl:if test="not(contains(@xml:lang,'Latn-'))">
            <span>
                <xsl:attribute name="class">
                    <xsl:text>title</xsl:text>
                    <xsl:choose>
                        <xsl:when test="@level='a'">
                            <xsl:text>-analytic</xsl:text>
                        </xsl:when>
                        <xsl:when test="@level='m'">
                            <xsl:text>-monographic</xsl:text>
                        </xsl:when>
                        <xsl:when test="@level='j'">
                            <xsl:text>-journal</xsl:text>
                        </xsl:when>
                        <xsl:when test="@level='s'">
                            <xsl:text>-series</xsl:text>
                        </xsl:when>
                        <xsl:when test="@level='u'">
                            <xsl:text>-unpublished</xsl:text>
                        </xsl:when>
                        <xsl:when test="parent::t:persName">
                            <xsl:text>-person</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:for-each select="./node()">
                    <xsl:apply-templates select="."/>
                </xsl:for-each>
            </span>
        </xsl:if>
    </xsl:template>

    <!-- Templates for adding links and icons to uris -->
    <xsl:template match="t:idno | t:ref | t:ptr" mode="links">
        <xsl:variable name="ref">
            <xsl:choose>
                <xsl:when test="self::t:ref/@target">
                    <xsl:value-of select="@target"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="text()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="title">
            <xsl:variable name="title-string">
                <xsl:value-of select="preceding-sibling::t:title[1]//text()"/>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="@type='zotero'">
                    <xsl:text>Link to Zotero Bibliographic record</xsl:text>
                </xsl:when>
                <xsl:when test="starts-with($ref,$base-uri)">
                    <xsl:value-of select="concat('Link to ',$repository-title,' Bibliographic Record for', $title-string)"/>
                </xsl:when>
                <!-- glyphicon glyphicon-book -->
                <xsl:when test="starts-with($ref,'http://www.worldcat.org/')">
                    <xsl:text>Link to Worldcat Bibliographic record</xsl:text>
                </xsl:when>
                <xsl:when test="starts-with($ref,'http://catalog.hathitrust.org/')">
                    <xsl:text>Link to HathiTrust Bibliographic record</xsl:text>
                </xsl:when>
                <xsl:when test="starts-with($ref,'http://digitale-sammlungen.ulb.uni-bonn.de')">
                    <xsl:text>Link to UniversitätBonn Bibliographic record</xsl:text>
                </xsl:when>
                <xsl:when test="starts-with($ref,'https://archive.org')">
                    <xsl:text>Link to Archive.org Bibliographic record</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>External link to bibliographic record</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <span class="footnote-icon">
            <a href="{$ref}" title="{$title}" data-toggle="tooltip" data-placement="top" class="bibl-links">
                <xsl:call-template name="ref-icons">
                    <xsl:with-param name="ref" select="$ref"/>
                </xsl:call-template>
            </a>
        </span>
    </xsl:template>
    <xsl:template name="ref-icons">
        <xsl:param name="ref"/>
        <xsl:choose>
            <xsl:when test="@type='zotero' or contains($ref,'zotero.org/')">
                <img src="{$nav-base}/resources/images/zotero.png" alt="Link to Zotero Bibliographic Record" height="18px"/>
            </xsl:when>
            <xsl:when test="starts-with($ref,$base-uri)">
                <img src="{$nav-base}/resources/images/icons-syriaca-sm.png" alt="{concat('Link to ',$repository-title,' Bibliographic Record.')}" height="18px"/>
            </xsl:when>
            <!-- glyphicon glyphicon-book -->
            <xsl:when test="contains($ref,'worldcat.org/')">
                <img src="{$nav-base}/resources/images/worldCat-logo.jpg" alt="Link to Worldcat Bibliographic record" height="18px"/>
            </xsl:when>
            <xsl:when test="contains($ref,'hathitrust.org/')">
                <img src="{$nav-base}/resources/images/htrc_logo.png" alt="Link to HathiTrust Bibliographic record" height="18px"/>
            </xsl:when>
            <xsl:when test="contains($ref,'archive.org')">
                <img src="{$nav-base}/resources/images/ialogo.jpg" alt="Link to Archive.org Bibliographic record" height="18px"/>
            </xsl:when>
            <xsl:otherwise>
                <span class="glyphicon glyphicon-book"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle bibliographic records, output full record
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:idno" mode="full">
        <p>
            <span class="tei-label">
                <xsl:choose>
                    <xsl:when test="@type='URI'">URI: </xsl:when>
                    <xsl:when test="@type != ''">
                        <xsl:value-of select="concat(upper-case(substring(@type,1,1)),substring(@type,2))"/>: </xsl:when>
                    <xsl:otherwise>Other ID Number: </xsl:otherwise>
                </xsl:choose>
            </span>
            <xsl:choose>
                <xsl:when test="@type='URI'">
                    <a href="{text()}">
                        <xsl:value-of select="text()"/>  <xsl:call-template name="ref-icons">
                            <xsl:with-param name="ref" select="text()"/>
                        </xsl:call-template>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </p>
    </xsl:template>
    <xsl:template match="t:ref" mode="full">
        <p>
            <span class="tei-label">See Also: </span>
            <a href="{@target}">
                <xsl:choose>
                    <xsl:when test="text()">
                        <xsl:value-of select="text()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@target"/>
                    </xsl:otherwise>
                </xsl:choose>  <xsl:call-template name="ref-icons">
                    <xsl:with-param name="ref" select="text()"/>
                </xsl:call-template>
            </a>
        </p>
    </xsl:template>
    <xsl:template match="t:imprint" mode="full">
        <xsl:for-each select="child::*">
            <p>
                <span class="tei-label">
                    <xsl:choose>
                        <xsl:when test="self::t:publisher">Publisher: </xsl:when>
                        <xsl:when test="self::t:pubPlace">Place of Publication: </xsl:when>
                        <xsl:when test="self::t:date">Date of Publication: </xsl:when>
                    </xsl:choose>
                </span>
                <span>
                    <xsl:sequence select="local:attributes(.)"/>
                    <xsl:choose>
                        <xsl:when test="@ref">
                            <a href="{@ref}">
                                <xsl:apply-templates/>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates/>
                        </xsl:otherwise>
                    </xsl:choose>
                </span>
            </p>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="t:biblScope" mode="full">
        <p>
            <span class="tei-label">
                <xsl:choose>
                    <xsl:when test="@unit = 'pp'">Pages: </xsl:when>
                    <xsl:when test="@unit = 'vol'">Volume: </xsl:when>
                    <xsl:when test="@unit = 'entry'">Entry: </xsl:when>
                    <xsl:when test="@unit = 'col' or @unit = 'column'">Column: </xsl:when>
                    <xsl:when test="@unit = 'part'">Part: </xsl:when>
                    <xsl:when test="@unit = 'series'">Series: </xsl:when>
                    <xsl:when test="@unit = 'issue'">Issue: </xsl:when>
                    <xsl:when test="@unit = 'tomus'">Tome: </xsl:when>
                    <xsl:when test="@unit = 'fasc'">Pages: </xsl:when>
                    <xsl:when test="@unit = 'pp'">Fasicule: </xsl:when>
                    <xsl:when test="@type = 'vol'">Volume: </xsl:when>
                    <xsl:when test="@type = 'page'">Pages: </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@unit"/>
                    </xsl:otherwise>
                </xsl:choose>
            </span>
            <span>
                <xsl:sequence select="local:attributes(.)"/>
                <xsl:apply-templates mode="full"/>
            </span>
        </p>
    </xsl:template>
    <xsl:template match="t:biblStruct" mode="full">
        <xsl:apply-templates mode="full"/>
    </xsl:template>
    <xsl:template match="t:analytic" mode="full">
        <h4>Article</h4>
        <div class="indent">
            <xsl:apply-templates select="t:title" mode="full"/>
            <xsl:apply-templates select="*[not(self::t:title)]" mode="full"/>
        </div>
    </xsl:template>
    <xsl:template match="t:monogr" mode="full">
        <h4>Publication</h4>
        <div class="indent">
            <xsl:apply-templates select="t:title" mode="full"/>
            <xsl:apply-templates select="*[not(self::t:title)]" mode="full"/>
        </div>
    </xsl:template>
    <xsl:template match="t:series" mode="full">
        <h4>Series</h4>
        <div class="indent">
            <xsl:apply-templates select="t:title" mode="full"/>
            <xsl:apply-templates select="*[not(self::t:title)]" mode="full"/>
        </div>
    </xsl:template>
    <xsl:template match="*" mode="full">
        <p>
           <span class="tei-label">
                <xsl:value-of select="concat(upper-case(substring(name(.),1,1)),substring(name(.),2))"/>: </span>
           <span class="tei-{local-name(.)}">
              <xsl:sequence select="local:attributes(.)"/>
              <xsl:apply-templates mode="footnote"/>
           </span>
        </p>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     suppress otherwise unhandled descendent nodes and attibutes of bibl or 
     biblStruct in the context of a footnote 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="text()" mode="footnote bibliography biblist allbibl lastname-first">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
   
    <xsl:template match="t:* | @*" mode="footnote bibliography biblist allbibl lastname-first"/>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     emit the footnote number for a bibl
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:bibl" mode="footnote-ref">
        <xsl:param name="footnote-number">1</xsl:param>
        <span class="tei-footnote-ref">
            <a href="#{@xml:id}">
                <xsl:value-of select="$footnote-number"/>
            </a>
        </span>
    </xsl:template>
   
</xsl:stylesheet>