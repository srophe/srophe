<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t x saxon local" version="2.0">
    
    <!-- =================================================================== -->
    <!-- Helper Functions  -->
    <!-- =================================================================== -->
    <xsl:variable name="odd">
        <xsl:if test="doc-available(concat('xmldb:exist://',$app-root,'/documentation/syriaca-tei-main.odd'))">
            <xsl:sequence select="doc(concat('xmldb:exist://',$app-root,'/documentation/syriaca-tei-main.odd'))"/>
        </xsl:if>
    </xsl:variable>
    
    <!-- Add a lang attribute to HTML elements -->
    <xsl:function name="local:attributes">
        <xsl:param name="node"/>
        <!-- Add lang attribute and direction attributes -->
        <xsl:if test="$node/@xml:lang">
            <xsl:copy-of select="$node/@xml:lang"/>
            <xsl:attribute name="lang">
                <xsl:value-of select="$node/@xml:lang"/>
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="$node/@xml:lang='en'">
                    <xsl:attribute name="dir">
                        <xsl:value-of select="'ltr'"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="$node/@xml:lang = ('syr','ar','syc','syr-Syrj')">
                    <xsl:attribute name="dir">
                        <xsl:value-of select="'rtl'"/>
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
        
        <!-- Add id attributes as html attributes -->
        <xsl:choose>
            <xsl:when test="$node/@xml:id">
                <xsl:attribute name="id">
                    <xsl:value-of select="$node/@xml:id"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:when test="$node/@id">
                <xsl:attribute name="id">
                    <xsl:value-of select="$node/@xml:id"/>
                </xsl:attribute>
            </xsl:when>
        </xsl:choose>

        <!-- Handle n attributes as span elements -->
        <xsl:if test="$node/@n">
            <span class="tei-attr-n">
                <xsl:value-of select="string($node/@n)"/>
            </span>
        </xsl:if>
    </xsl:function>
    
    <!-- Function for adding footnotes -->
    <xsl:function name="local:add-footnotes">
        <xsl:param name="refs"/>
        <xsl:param name="lang"/>
        <xsl:if test="$refs != ''">
            <span class="tei-footnote-refs" dir="ltr">
                <xsl:if test="$lang != 'en'">
                    <xsl:attribute name="lang">en</xsl:attribute>
                    <xsl:attribute name="xml:lang">en</xsl:attribute>
                </xsl:if>
                <xsl:for-each select="tokenize($refs,' ')">
                    <span class="tei-footnote-ref">
                        <a href="{.}">
                            <xsl:value-of select="substring-after(.,'-')"/>
                        </a>
                        <xsl:if test="position() != last()">,<xsl:text> </xsl:text>
                        </xsl:if>
                    </span>
                </xsl:for-each>
                <xsl:text> </xsl:text>
            </span>
        </xsl:if>
    </xsl:function>
    
    <!-- Process names editors/authors orint max in function call -->
    <xsl:function name="local:emit-responsible-persons">
        <!-- node passed by refering stylesheet -->
        <xsl:param name="current-node"/>
        <!-- mode, footnote or biblist -->
        <xsl:param name="moded"/>
        <!-- max number of authors -->
        <xsl:param name="maxauthors"/>
        <!-- count number of relevant persons -->
        <xsl:variable name="ccount">
            <xsl:value-of select="count($current-node)"/>
        </xsl:variable> 
        <!-- process based on above parameters -->
        <xsl:choose>
            <xsl:when test="$ccount=1 and $moded='footnote'">
                <xsl:apply-templates select="$current-node[1]" mode="footnote"/>
            </xsl:when>
            <xsl:when test="$ccount=1 and $moded='biblist'">
                <xsl:apply-templates select="$current-node[1]" mode="lastname-first"/>
            </xsl:when>
            <xsl:when test="$ccount &gt; $maxauthors and $moded='footnote'">
                <xsl:apply-templates select="$current-node[1]" mode="footnote"/>
                <xsl:text> et al.</xsl:text>
            </xsl:when>
            <xsl:when test="$ccount &gt; $maxauthors and $moded='biblist'">
                <xsl:apply-templates select="$current-node[1]" mode="lastname-first"/>
                <xsl:text> et al.</xsl:text>
            </xsl:when>
            <xsl:when test="$ccount = 2 and $moded='footnote'">
                <xsl:apply-templates select="$current-node[1]" mode="footnote"/>
                <xsl:text> and </xsl:text>
                <xsl:apply-templates select="$current-node[2]" mode="footnote"/>
            </xsl:when>
            <xsl:when test="$ccount = 2 and $moded='biblist'">
                <xsl:apply-templates select="$current-node[1]" mode="lastname-first"/>
                <xsl:text> and </xsl:text>
                <xsl:apply-templates select="$current-node[2]" mode="biblist"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$current-node[position() &lt; $maxauthors+1]">
                    <xsl:choose>
                        <xsl:when test="position() = $maxauthors">
                            <xsl:text> and </xsl:text>
                        </xsl:when>
                        <xsl:when test="position() = last()">
                            <xsl:text> and </xsl:text>
                        </xsl:when>
                        <xsl:when test="position() &gt; 1">
                            <xsl:text>, </xsl:text>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="$moded='footnote'">
                            <xsl:apply-templates mode="footnote"/>
                        </xsl:when>
                        <xsl:when test="$moded='biblist'">
                            <xsl:apply-templates mode="biblist"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Process names editors/authors print all -->
    <xsl:function name="local:emit-responsible-persons-all">
        <!-- node passed by refering stylesheet -->
        <xsl:param name="current-node"/>
        <!-- mode, footnote or biblist -->
        <xsl:param name="moded"/>
        <!-- count number of relevant persons -->
        <xsl:variable name="ccount">
            <xsl:value-of select="count($current-node)"/>
        </xsl:variable>  
        <!-- process based on above parameters -->
        <xsl:choose>
            <xsl:when test="$ccount=1 and $moded='footnote'">
                <xsl:apply-templates select="$current-node[1]" mode="footnote"/>
            </xsl:when>
            <xsl:when test="$ccount=1 and $moded='biblist'">
                <xsl:apply-templates select="$current-node[1]" mode="lastname-first"/>
            </xsl:when>
            <xsl:when test="$ccount = 2 and $moded='footnote'">
                <xsl:apply-templates select="$current-node[1]" mode="footnote"/>
                <xsl:text> and </xsl:text>
                <xsl:apply-templates select="$current-node[2]" mode="footnote"/>
            </xsl:when>
            <xsl:when test="$ccount = 2 and $moded='biblist'">
                <xsl:apply-templates select="$current-node[1]" mode="lastname-first"/>
                <xsl:text> and </xsl:text>
                <xsl:apply-templates select="$current-node[2]" mode="biblist"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$current-node">
                    <xsl:choose>
                        <xsl:when test="position() = $ccount">
                            <xsl:if test="$ccount &gt; 2">
                                <xsl:text>,</xsl:text>
                            </xsl:if>
                            <xsl:text> and </xsl:text>
                        </xsl:when>
                        <xsl:when test="position() &gt; 1">
                            <xsl:text>, </xsl:text>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="$moded='footnote'">
                            <xsl:apply-templates mode="footnote"/>
                        </xsl:when>
                        <xsl:when test="$moded='biblist'">
                            <xsl:apply-templates mode="biblist"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Function to add correct ordinal suffix to numbers used in citation creation.  -->
    <xsl:function name="local:ordinal">
        <xsl:param name="num" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="number($num) = number($num)">
                <xsl:choose>
                    <xsl:when test="ends-with($num,'1') and not($num = '11')">
                        <xsl:value-of select="concat($num, 'st ed.')"/>
                    </xsl:when>
                    <xsl:when test="ends-with($num,'2') and not($num = '12')">
                        <xsl:value-of select="concat($num, 'nd ed.')"/>
                    </xsl:when>
                    <xsl:when test="ends-with($num,'3') and not($num = '13')">
                        <xsl:value-of select="concat($num, 'rd ed.')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($num, 'th ed.')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$num"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- 
     Function to output dates in correct formats passes whole element to function, 
     function also uses trim-date to strip leading 0
    -->
    <xsl:function name="local:do-dates">
        <xsl:param name="element" as="node()"/>
        <xsl:if test="$element/@when or $element/@notBefore or $element/@notAfter or $element/@from or $element/@to">
            <xsl:choose>
                <!-- Formats to and from dates -->
                <xsl:when test="$element/@from">
                    <xsl:choose>
                        <xsl:when test="$element/@to">
                            <xsl:value-of select="local:trim-date($element/@from)"/>-<xsl:value-of select="local:trim-date($element/@to)"/>
                        </xsl:when>
                        <xsl:otherwise>from <xsl:value-of select="local:trim-date($element/@from)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$element/@to">to <xsl:value-of select="local:trim-date($element/@to)"/>
                </xsl:when>
            </xsl:choose>
            <!-- Formats notBefore and notAfter dates -->
            <xsl:if test="$element/@notBefore">
                <!-- Adds comma if there are other dates -->
                <xsl:if test="$element/@to or $element/@from">, </xsl:if>not before <xsl:value-of select="local:trim-date($element/@notBefore)"/>
            </xsl:if>
            <xsl:if test="$element/@notAfter">
                <!-- Adds comma if there are other dates -->
                <xsl:if test="$element/@to or $element/@from or $element/@notBefore">, </xsl:if>not after <xsl:value-of select="local:trim-date($element/@notAfter)"/>
            </xsl:if>
            <!-- Formats when, single date -->
            <xsl:if test="$element/@when">
                <!-- Adds comma if there are other dates -->
                <xsl:if test="$element/@to or $element/@from or $element/@notBefore or $element/@notAfter">, </xsl:if>
                <xsl:value-of select="local:trim-date($element/@when)"/>
            </xsl:if>
        </xsl:if>
    </xsl:function>
    
    <!-- Date function to remove leading 0s -->
    <xsl:function name="local:trim-date">
        <xsl:param name="date"/>
        <xsl:choose>
            <!-- NOTE: This can easily be changed to display BCE instead -->
            <!-- removes leading 0 but leaves -  -->
            <xsl:when test="starts-with($date,'-0')">
                <xsl:value-of select="concat(substring($date,3),' BCE')"/>
            </xsl:when>
            <!-- removes leading 0 -->
            <xsl:when test="starts-with($date,'0')">
                <xsl:value-of select="local:trim-date(substring($date,2))"/>
            </xsl:when>
            <!-- passes value through without changing it -->
            <xsl:otherwise>
                <xsl:value-of select="$date"/>
            </xsl:otherwise>
        </xsl:choose>
        <!--  <xsl:value-of select="string(number($date))"/>-->
    </xsl:function>
    
    <!-- Function to tranlate xml:lang attributes to full lang label -->
    <xsl:function name="local:expand-lang">
        <xsl:param name="lang" as="xs:string"/>
        <xsl:param name="type" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$lang='la'">
                <xsl:text>Latin</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='grc'">
                <xsl:text>Greek</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='ar'">
                <xsl:text>Arabic</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='hy'">
                <xsl:text>Armenian</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='ka'">
                <xsl:text>Georgian</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='sog'">
                <xsl:text>Soghdian</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='cu'">
                <xsl:text>Slavic</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='cop'">
                <xsl:text>Coptic</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='gez'">
                <xsl:text>Ethiopic</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='syr-pal'">
                <xsl:text>Syro-Palestinian</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='ar-syr'">
                <xsl:text>Karshuni</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='de'">
                <xsl:text>German</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='fr'">
                <xsl:text>French</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='en'">
                <xsl:text>English</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='it'">
                <xsl:text>Italian</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='pt'">
                <xsl:text>Portugese</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='ru'">
                <xsl:text>Russian</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='nl'">
                <xsl:text>Dutch</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='ar'">
                <xsl:text>Arabic</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='es'">
                <xsl:text>Spanish</xsl:text>
            </xsl:when>
            <xsl:when test="$lang='tr'">
                <xsl:text>Turkish</xsl:text>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:function>
    
    <!-- Translate labels to human readable labels via odd -->
    <xsl:function name="local:translate-label">
        <xsl:param name="label"/>
        <xsl:param name="count"/>
        <xsl:choose>
            <xsl:when test="$odd/descendant::t:valItem[@ident=$label]/t:gloss">
                <xsl:choose>
                    <xsl:when test="$count &gt; 1 and $odd/descendant::t:valItem[@ident=$label]/t:gloss[@type='pl']">
                        <xsl:value-of select="$odd/descendant::t:valItem[@ident=$label]/t:gloss[@type='pl'][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="$odd/descendant::t:valItem[@ident=$label]/t:gloss[@type='sg']">
                                <xsl:value-of select="$odd/descendant::t:valItem[@ident=$label]/t:gloss[@type='sg'][1]"/>                                
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$odd/descendant::t:valItem[@ident=$label]/t:gloss[1]"/>                        
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="concat(upper-case(substring($label,1,1)),substring($label,2))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Translate labels to human readable labels via odd, passes on element and label value -->
    <xsl:function name="local:translate-label">
        <xsl:param name="element"/>
        <xsl:param name="label"/>
        <xsl:param name="count"/>
        <xsl:variable name="element" select="$odd/descendant::t:elementSpec[@ident = name($element)]"/>
        <xsl:choose>
            <xsl:when test="$element/descendant::t:valItem[@ident=$label]/t:gloss">
                <xsl:choose>
                    <xsl:when test="$count &gt; 1 and $element/descendant::t:valItem[@ident=$label]/t:gloss[@type='pl']">
                        <xsl:value-of select="$element/descendant::t:valItem[@ident=$label]/t:gloss[@type='pl'][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="$element/descendant::t:valItem[@ident=$label]/t:gloss[@type='sg']">
                                <xsl:value-of select="$element/descendant::t:valItem[@ident=$label]/t:gloss[@type='sg'][1]"/>                                
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$element/descendant::t:valItem[@ident=$label]/t:gloss[1]"/>                        
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat(upper-case(substring($label,1,1)),substring($label,2))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Translate labels to human readable labels via specified xml file, passes on element and label value -->
    <xsl:function name="local:translate-label">
        <xsl:param name="ref"/>
        <xsl:param name="element"/>
        <xsl:param name="label"/>
        <xsl:param name="count"/>
        <xsl:variable name="file-name">
            <xsl:choose>
                <xsl:when test="contains($ref,'#')">
                    <xsl:value-of select="substring-before($ref,'#')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$ref"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="file">
            <xsl:choose>
                <xsl:when test="contains($file-name,$base-uri)">
                    <xsl:value-of select="replace($file-name,$base-uri,concat('xmldb:exist://',$nav-base))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="doc($ref)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$file/descendant::*[@xml:id=$label]/t:gloss">
                <xsl:value-of select="$file/descendant::*[@xml:id=$label]/t:gloss[1]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat(upper-case(substring($label,1,1)),substring($label,2))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="local:bibl-type-order">
        <xsl:param name="label"/>
        <xsl:choose>
            <xsl:when test="$label = 'lawd:Edition'">a</xsl:when>
            <xsl:when test="$label = 'syriaca:Apparatus'">b</xsl:when>
            <xsl:when test="$label = 'syriaca:Manuscript'">c</xsl:when>
            <xsl:when test="$label = 'syriaca:AncientVersion'">d</xsl:when>
            <xsl:when test="$label = 'syriaca:ModernTranslation'">e</xsl:when>
            <xsl:when test="$label = 'syriaca:DigitalCatalogue'">f</xsl:when>
            <xsl:when test="$label = 'syriaca:PrintCatalogue'">g</xsl:when>
            <xsl:when test="$label = 'syriaca:Glossary'">h</xsl:when>
            <xsl:when test="$label = 'lawd:WrittenWork'">i</xsl:when>
        </xsl:choose>
    </xsl:function>
    
    
    <!-- =================================================================== -->
    <!-- Helper templates -->
    <!-- =================================================================== -->
    <!-- Wrap text with @rend in appropriate html elements or html classes -->
    <xsl:template name="rend">
        <xsl:choose>
            <xsl:when test="@rend">
                <xsl:choose>
                    <xsl:when test="@rend = 'bold'">
                        <b>
                            <xsl:call-template name="ref"/>
                        </b>
                    </xsl:when>
                    <xsl:when test="@rend = 'italic'">
                        <i>
                            <xsl:call-template name="ref"/>
                        </i>
                    </xsl:when>
                    <xsl:when test="@rend = ('superscript','sup')">
                        <sup>
                            <xsl:call-template name="ref"/>
                        </sup>
                    </xsl:when>
                    <xsl:when test="@rend = ('subscript','sub')">
                        <sub>
                            <xsl:call-template name="ref"/>
                        </sub>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="tei-rend-{string(@rend)}">
                            <xsl:call-template name="ref"/>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="ref"/> 
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="ref">
        <xsl:choose>
            <xsl:when test="parent::t:ref or parent::t:ptr or parent::*[1]/@ref">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="@ref">
                <a href="{@ref}">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>