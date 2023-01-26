<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t x saxon local" version="2.0">

    <!-- ================================================================== 
       MAJLIS custom srophe XSLT
       For main record display, manuscript
       
       ================================================================== -->

<!-- 
    <xsl:choose>
            <xsl:when test="//t:text/t:body/t:listBibl/t:msDesc">
                <xsl:apply-templates mode="majlis"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    -->
     
    <xsl:template match="t:TEI" mode="majlis">
        <!-- teiHeader -->
        <div class="row titleStmt">
            <div class="col-md-8">
                <h1>
                    <xsl:choose>
                        <xsl:when test="t:teiHeader/t:fileDesc/t:titleStmt/t:title[@level='a']"><xsl:apply-templates select="t:teiHeader/t:fileDesc/t:titleStmt/t:title[@level='a']"/></xsl:when>
                        <xsl:otherwise><xsl:apply-templates select="t:teiHeader/t:fileDesc/t:titleStmt/t:title[1]"/></xsl:otherwise>
                    </xsl:choose>
                </h1>
            </div>
            <div class="col-md-4 actionButtons">
                <xsl:if test="//t:TEI/t:facsimile/t:graphic/@url">
                    <button type="button" class="btn btn-default btn-grey btn-sm">Scan</button>                    
                </xsl:if>
                <button type="button" class="btn btn-default btn-grey btn-sm">Feedback</button>
                <button type="button" class="btn btn-default btn-grey btn-sm">XML</button>
                <button type="button" class="btn btn-default btn-grey btn-sm">Print</button>
            </div>
        </div>
        <xsl:choose>
            <xsl:when test="//t:text/t:body/t:listBibl/t:msDesc">
                <xsl:apply-templates select="//t:body" mode="majlis-mss"/>
            </xsl:when>
            <xsl:otherwise>
                <div class="whiteBoxwShadow">
                    <xsl:apply-templates select="//t:body"/>
                    <xsl:apply-templates select="//t:teiHeader"/>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:body" mode="majlis majlis-mss">
        <xsl:if test="t:listBibl/t:msDesc/t:msContents/t:msItem">
            <xsl:for-each select="t:listBibl/t:msDesc[1]">
                <div class="mainDesc row">
                    <div class="col-md-6">
                        <xsl:for-each select="t:msContents/t:msItem[1]/t:title[@xml:lang='en'] | t:msContents/t:msItem[1]/t:author | t:msContents/t:msItem[1]/t:textLang ">
                            <div class="item row">
                                <span class="inline-h4 col-md-3">
                                    <xsl:choose>
                                        <xsl:when test="self::t:title">Title</xsl:when>
                                        <xsl:when test="self::t:author">Author</xsl:when>
                                        <xsl:when test="self::t:textLang">Language</xsl:when>
                                    </xsl:choose>
                                </span>
                                <span class="col-md-9">
                                    <xsl:apply-templates select="."/>
                                </span>
                            </div>
                            <!-- 
                           WS: NOTE - missing xpath for script heading
                            -->
                        </xsl:for-each>
                        <xsl:for-each select="t:history/t:origin/t:persName[@role='scribe']">
                            <div class="item row">
                                <span class="inline-h4 col-md-3">Scribe</span>
                                <span class="col-md-9">
                                    <xsl:apply-templates select="."/>
                                </span>
                            </div>
                        </xsl:for-each>
                    </div>
                    <div class="col-md-6">
                        <!-- 
                            /TEI/text/body/listBibl/msDesc/history/origin/origDate
                            /TEI/text/body/listBibl/msDesc/history/origin/origPlace
                            /TEI/text/body/listBibl/msDesc/physDesc/objectDesc/@form
                            /TEI/text/body/listBibl/msDesc/physDesc/objectDesc/supportDesc/support/material
                            /TEI/text/body/listBibl/msDesc/physDesc/objectDesc/supportDesc/extent/measure
                        -->
                        <xsl:for-each select="t:history/t:origin/t:origDate">
                            <div class="item row">
                                <span class="inline-h4 col-md-3">Date</span>
                                <span class="col-md-9">
                                    <xsl:apply-templates select="."/>
                                </span>
                            </div>
                        </xsl:for-each>
                        <xsl:for-each select="t:history/t:origin/t:origPlace">
                            <div class="item row">
                                <span class="inline-h4 col-md-3">Place</span>
                                <span class="col-md-9">
                                    <xsl:apply-templates select="."/>
                                </span>
                            </div>
                        </xsl:for-each>
                        <xsl:for-each select="t:physDesc/t:objectDesc/@form">
                            <div class="item row">
                                <span class="inline-h4 col-md-3">Object Type</span>
                                <span class="col-md-9">
                                    <xsl:apply-templates select="."/>
                                </span>
                            </div>
                        </xsl:for-each>
                        <xsl:for-each select="t:physDesc/t:objectDesc/t:supportDesc/t:support/t:material">
                            <div class="item row">
                                <span class="inline-h4 col-md-3">Material</span>
                                <span class="col-md-9">
                                    <xsl:apply-templates select="."/>
                                </span>
                            </div>
                        </xsl:for-each>
                        <xsl:for-each select="physDesc/objectDesc/supportDesc/extent/measure">
                            <div class="item row">
                                <span class="inline-h4 col-md-3">Extent</span>
                                <span class="col-md-9">
                                    <xsl:apply-templates select="."/>
                                </span>
                            </div>
                        </xsl:for-each>
                    </div>
                </div>
            </xsl:for-each>
        </xsl:if>
        <div class="listEntities row">
            <div class="col-md-4 text-left">
                <button aria-expanded="true" type="button" class="btn btn-default btn-lg" href="#personEntities" data-toggle="collapse">Persons</button>
                <xsl:call-template name="personEntities"/>
            </div>
            <div class="col-md-4 text-center">
                <button aria-expanded="true" type="button" class="btn btn-default btn-lg" href="#placeEntities" data-toggle="collapse">Places</button>
                <xsl:call-template name="placeEntities"/>
            </div>
            <div class="col-md-4 text-right">
                <button aria-expanded="true" type="button" class="btn btn-default btn-lg" href="#workEntities" data-toggle="collapse">Works</button>
                <xsl:call-template name="workEntities"/>
            </div>
        </div>
        <!-- Menu items for record contents -->
        <!-- aria-expanded="false" -->
        <div id="mainMenu">
            <div class="btn-group btn-group-justified">
                <div class="btn-group">
                    <button aria-expanded="true" type="button" class="btn btn-default btn-grey btn-lg" href="#mainMenuContent" data-toggle="collapse">Content</button>
                </div>
                <div class="btn-group">
                    <button type="button" class="btn btn-default btn-grey btn-lg" data-toggle="collapse" href="#mainMenuCodicology">Codicology</button>
                </div>
                <div class="btn-group">
                    <button type="button" class="btn btn-default btn-grey btn-lg" href="#mainMenuPaleography" data-toggle="collapse">Paleography</button>
                </div>
                <div class="btn-group">
                    <button type="button" class="btn btn-default btn-grey btn-lg" href="#mainMenuAdditions" data-toggle="collapse">Additions</button>
                </div>
                <div class="btn-group">
                    <button type="button" class="btn btn-default btn-grey btn-lg" href="#mainMenuHistory" data-toggle="collapse">History</button>
                </div>
                <div class="btn-group">
                    <button type="button" class="btn btn-default btn-grey btn-lg" href="#mainMenuHeritage" data-toggle="collapse">Heritage Data</button>
                </div>
                <div class="btn-group">
                    <button type="button" class="btn btn-default btn-grey btn-lg" href="#mainMenuBibliography" data-toggle="collapse">Bibliography</button>
                </div>
                <div class="btn-group">
                    <button type="button" class="btn btn-default btn-grey btn-lg" href="#mainMenuCredits" data-toggle="collapse">Credits</button>
                </div>
            </div>
            <div class="mainMenuContent clearfix">
                <xsl:apply-templates select="t:listBibl/t:msDesc/t:msContents" mode="majlis"/>
                <xsl:apply-templates select="t:listBibl/t:msDesc/t:physDesc/t:objectDesc" mode="majlis"/>
                <xsl:apply-templates select="t:listBibl/t:msDesc/t:physDesc/t:handDesc" mode="majlis"/>
                <xsl:apply-templates select="t:listBibl/t:msDesc/t:physDesc/t:additions" mode="majlis"/>
                <xsl:apply-templates select="t:listBibl/t:msDesc/t:history" mode="majlis"/>
                <xsl:apply-templates select="t:listBibl/t:msDesc/t:physDesc/t:accMat" mode="majlis"/>
                <xsl:apply-templates select="t:listBibl/t:additional/t:listBibl" mode="majlis"/>
                <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:titleStmt" mode="majlis-credits"/>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:msContents" mode="majlis">
        <div class="whiteBoxwShadow">
            <h3><a aria-expanded="true" href="#mainMenuContent" data-toggle="collapse">Content</a></h3>
            <div class="collapse in" id="mainMenuContent">
            <xsl:for-each select="t:msItem">
                <div class="row">
                    <div class="col-md-1"><h4>Text <xsl:value-of select="position()"/></h4></div>
                    <div class="col-md-11">
                        <!-- 
                            /TEI/text/body/listBibl/msDesc/msContents/msItem/locus
                            /TEI/text/body/listBibl/msDesc/msContents/msItem/title/@xml:lang="en"
                            /TEI/text/body/listBibl/msDesc/msContents/msItem/author/persName
                            /TEI/text/body/listBibl/msDesc/msContents/msItem/textLang
                            /TEI/text/body/listBibl/msDesc/msContents/msItem/rubric
                            /TEI/text/body/listBibl/msDesc/msContents/msItem/incipit
                            /TEI/text/body/listBibl/msDesc/msContents/msItem/explicit
                            /TEI/text/body/listBibl/msDesc/msContents/msItem/colophon
                            /TEI/text/body/listBibl/msDesc/msContents/msItem/note
                        -->
                        <xsl:for-each select="child::*">
                            <div class="row">
                                <div class="col-md-2 inline-h4 ">
                                    <xsl:variable name="label" select="local-name(.)"/>
                                    <xsl:choose>
                                        <xsl:when test="$label = 'locus'">Folios</xsl:when>
                                        <xsl:when test="$label = 'title'">Title <xsl:if test="@xml:lang != ''">[<xsl:value-of select="upper-case(@xml:lang)"/>]</xsl:if></xsl:when>
                                        <xsl:when test="$label = 'textLang'">Language</xsl:when>
                                        <xsl:when test="$label = 'rubric'">Text Division</xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="concat(upper-case(substring($label,1,1)),substring($label,2))"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </div>
                                <div class="col-md-10">
                                    <xsl:apply-templates/>
                                </div>
                            </div>    
                        </xsl:for-each>
                    </div>
                </div>
            </xsl:for-each>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:objectDesc" mode="majlis">
        <div class="whiteBoxwShadow">
            <h3><a aria-expanded="true" href="#mainMenuCodicology" data-toggle="collapse">Codicology</a></h3>
            <div class="collapse" id="mainMenuCodicology">
        <div class="row">
            <div class="col-md-2 inline-h4">Form </div>
            <div class="col-md-10"><xsl:value-of select="@form"/></div>    
        </div>
        <xsl:for-each select="t:supportDesc/t:support/t:material">
            <div class="row">
                <div class="col-md-2 inline-h4">Material </div>
                <div class="col-md-10"><xsl:apply-templates select="."/></div>    
            </div>
        </xsl:for-each>
        <xsl:for-each select="t:supportDesc/t:extent/t:measure">
            <div class="row">
                <div class="col-md-2 inline-h4">Extent </div>
                <div class="col-md-10"><xsl:apply-templates select="."/></div>    
            </div>
        </xsl:for-each>
        <xsl:for-each select="t:supportDesc/t:extent/t:dimensions">
            <div class="row">
                <div class="col-md-2 inline-h4">Dimensions <xsl:if test="@type != ''">(<xsl:value-of select="@type"/>)</xsl:if></div>
                <div class="col-md-10"><xsl:apply-templates select="."/></div>    
            </div>
        </xsl:for-each>
        <xsl:for-each select="t:supportDesc/t:foliation | t:supportDesc/t:collation |  t:supportDesc/t:condition">
            <xsl:variable name="label" select="local-name(.)"/>
            <div class="row">
                <div class="col-md-2 inline-h4"><xsl:value-of select="concat(upper-case(substring($label,1,1)),substring($label,2))"/> </div>
                <div class="col-md-10"><xsl:apply-templates select="."/></div>    
            </div>
        </xsl:for-each>
        <!-- WS:Note will need to check formatting  -->
        <xsl:for-each select="t:layoutDesc/t:layout/t:dimensions">
            <div class="row">
                <div class="col-md-2 inline-h4">Layout</div>
                <div class="col-md-10"><xsl:apply-templates select="."/></div>    
            </div>
        </xsl:for-each>
        <!-- 
            /TEI/text/body/listBibl/msDesc/physDesc/objectDesc/@form
            /TEI/text/body/listBibl/msDesc/physDesc/objectDesc/supportDesc/support/material
            /TEI/text/body/listBibl/msDesc/physDesc/objectDesc/supportDesc/extent/measure
            /TEI/text/body/listBibl/msDesc/physDesc/objectDesc/supportDesc/extent/dimensions
            /TEI/text/body/listBibl/msDesc/physDesc/objectDesc/supportDesc/foliation
            /TEI/text/body/listBibl/msDesc/physDesc/objectDesc/supportDesc/collation
            /TEI/text/body/listBibl/msDesc/physDesc/objectDesc/supportDesc/condition
            /TEI/text/body/listBibl/msDesc/physDesc/objectDesc/layoutDesc/layout/dimensions
            /TEI/text/body/listBibl/msDesc/physDesc/objectDesc/layoutDesc/layout/@columns
            /TEI/text/body/listBibl/msDesc/physDesc/objectDesc/layoutDesc/layout/@writtenLines
            /TEI/text/body/listBibl/msDesc/physDesc/bindingDesc/binding
        -->
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:handDesc" mode="majlis">
        <div class="whiteBoxwShadow">
            <h3><a aria-expanded="true" href="#mainMenuPaleography" data-toggle="collapse">Paleography</a></h3>
            <div class="collapse" id="mainMenuPaleography">
       <xsl:for-each select="t:handNote">
           <div class="row">
               <div class="col-md-1 inline-h4">Hand <xsl:value-of select="position()"/> </div>
               <div class="col-md-10">
                   <div class="row">
                       <div class="col-md-2 inline-h4">Script </div>
                       <div class="col-md-10"><xsl:value-of select="@script | @mode | @quality"/></div>
                   </div>
                   <div class="row">
                       <div class="col-md-2 inline-h4">Description </div>
                       <div class="col-md-10">
<!--                           <xsl:apply-templates select="." mode="text-normal"/>--> 
                           <xsl:apply-templates select="."/>
                       </div>
                   </div>
                   
               </div>    
           </div>    
       </xsl:for-each>
       <!-- 
                    TEI/text/body/listBibl/msDesc/physDesc/handDesc/handNote/@script and @mode and @quality
                    /TEI/text/body/listBibl/msDesc/physDesc/handDesc/handNote
                    
       -->
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:additions" mode="majlis">
        <div class="whiteBoxwShadow">
            <h3><a aria-expanded="true" href="#mainMenuAdditions" data-toggle="collapse">Additions</a></h3>
            <div class="collapse" id="mainMenuAdditions">
        <xsl:for-each select="t:list/t:item">
            <div class="row">
                <div class="col-md-1 inline-h4">Addition <xsl:value-of select="position()"/> </div>
                <div class="col-md-10">
                    <xsl:apply-templates select="."/>
                </div>    
            </div>    
        </xsl:for-each>
        <!-- 
        /TEI/text/body/listBibl/msDesc/physDesc/additions/list/item
        -->
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:history" mode="majlis">
        <div class="whiteBoxwShadow">
            <h3><a aria-expanded="true" href="#mainMenuHistory" data-toggle="collapse">History</a></h3>
            <div class="collapse" id="mainMenuHistory">
        <xsl:for-each select="t:origin">
            <div class="row">
                <div class="col-md-1 inline-h4">Production </div>
                <div class="col-md-10">
                    <xsl:apply-templates select="."/>
                </div>    
            </div>    
        </xsl:for-each>
        <xsl:for-each select="t:provenance">
            <div class="row">
                <div class="col-md-1 inline-h4">Provenance <xsl:value-of select="position()"/></div>
                <div class="col-md-10">
                    <xsl:apply-templates select="."/>
                </div>    
            </div>    
        </xsl:for-each>
        <xsl:for-each select="t:acquisition">
            <div class="row">
                <div class="col-md-1 inline-h4">Acquisition</div>
                <div class="col-md-10">
                    <xsl:apply-templates select="."/>
                </div>    
            </div>    
        </xsl:for-each>
        <!-- 
            /TEI/text/body/listBibl/msDesc/history/origin
            /TEI/text/body/listBibl/msDesc/history/provenance
            /TEI/text/body/listBibl/msDesc/history/acquisition
        -->
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:accMat" mode="majlis">
        <div class="whiteBoxwShadow">
            <h3><a aria-expanded="true" href="#mainMenuHeritage" data-toggle="collapse">Heritage Data</a></h3>
            <div class="collapse" id="mainMenuHeritage">

            <div class="row">
                <div class="col-md-1 inline-h4"> </div>
                <div class="col-md-10">
                    <xsl:apply-templates select="."/>
                </div>    
            </div>    
        <!-- 
            /TEI/text/body/listBibl/msDesc/physDesc/accMat
        -->
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:listBibl" mode="majlis">
        <div class="whiteBoxwShadow">
            <h3><a aria-expanded="true" href="#mainMenuBibliography" data-toggle="collapse">Bibliography</a></h3>
            <div class="collapse" id="mainMenuBibliography">
        <div class="row">
            <div class="col-md-1 inline-h4"> </div>
            <div class="col-md-10">
                <xsl:apply-templates select="."/>
            </div>    
        </div>    
        <!-- 
/TEI/text/body/listBibl/additional/listBibl/bibl        -->
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:titleStmt" mode="majlis-credits">
        <div class="whiteBoxwShadow">
            <h3><a aria-expanded="true" href="#mainMenuCredits" data-toggle="collapse">Credits</a></h3>
            <div class="collapse" id="mainMenuCredits">
                Need layout
                <!-- <xsl:apply-templates select="."/> -->
            </div>
        </div>
    </xsl:template>
    
    <xsl:template name="personEntities">
        <div class="collapse" id="personEntities">
            <div class="whiteBoxwShadow entityList">
            <h4>Persons referenced</h4>
            <ul>
                <xsl:for-each select="//t:persName">
                    <li><xsl:apply-templates select="."/></li>    
                </xsl:for-each>
            </ul>
            </div>
        </div>
    </xsl:template>
    <xsl:template name="placeEntities">
        <div class="collapse" id="placeEntities">
            <div class="whiteBoxwShadow entityList">
            <h4>Places referenced</h4>
            <ul>
                <xsl:for-each select="//t:placeName">
                    <li><xsl:apply-templates select="."/></li>    
                </xsl:for-each>
            </ul>
            </div>
        </div>
    </xsl:template>
    <xsl:template name="workEntities">
        <div class="collapse" id="workEntities">
            <div class="whiteBoxwShadow entityList">
            <h4>Works referenced</h4>
            <ul>
                <xsl:for-each select="//t:bibl">
                    <li><xsl:apply-templates select="."/></li>    
                </xsl:for-each>
            </ul>
            </div>
        </div>
    </xsl:template>
</xsl:stylesheet>