<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:srophe="https://srophe.app" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t x saxon local" version="2.0">

 <!-- ================================================================== 
       Copyright 2021 Srophe.org  
       
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
      generateStaticSite.xsl
       
       This xslt generates a static site from the repo-config.xml and existing HTML pages and TEI records. 
        
       code by: 
        + Winona Salesky (wsalesky@gmail.com)
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->
 <!-- =================================================================== -->
 <!-- import component stylesheets for HTML page portions -->
 <!-- =================================================================== -->
    <xsl:import href="tei2html.xsl"/>
    
 <!-- =================================================================== -->
 <!-- set output so we get (mostly) indented HTML -->
 <!-- =================================================================== -->
    <xsl:output name="html" encoding="UTF-8" method="xhtml" indent="no" omit-xml-declaration="yes"/>    
    
 <!-- =================================================================== -->
 <!--  initialize top-level variables and transform parameters -->
 <!-- =================================================================== -->
    <xsl:param name="applicationPath" select="'/Users/wsalesky/syriaca/srophe'"/>
    <xsl:param name="dataPath" select="'/Users/wsalesky/syriaca/srophe-app-data/data/'"/>
    <xsl:param name="configPath" select="'/Users/wsalesky/syriaca/srophe/repo-config.xml'"/>
    <xsl:variable name="config" select="document(xs:anyURI($configPath))"/>
    <xsl:variable name="staticSitePath" select="concat($applicationPath,'/staticSite/')"/>
    <!-- 
     Run through static pages, wrap appropriate headers
     Run through TEI records, output HTML pages
     Create Browse pages
     Create Search with staticSearch
    -->
    <xsl:template match="/">
        <xsl:variable name="documentURI" select="document-uri(.)"/>
        <xsl:variable name="fileType">
            <xsl:choose>
                <xsl:when test="*:div[@data-template-with]">HTML</xsl:when>
                <xsl:when test="t:TEI">TEI</xsl:when>
                <xsl:otherwise>OTHER: <xsl:value-of select="name(root(.))"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="filename">
            <xsl:value-of select="replace(tokenize($documentURI,'/')[last()],'.xml','.html')"/>
        </xsl:variable>
        <xsl:variable name="path">
            <xsl:choose>
                <xsl:when test="$fileType = 'HTML'">
                    <xsl:value-of select="replace($documentURI,$applicationPath,$staticSitePath)"/>
                </xsl:when>
                <xsl:when test="$fileType = 'TEI'">
                    <xsl:value-of select="replace($documentURI,$dataPath,$staticSitePath)"/>
                </xsl:when>
                <xsl:otherwise><xsl:message>Unrecognizable file type <xsl:value-of select="$fileType"/></xsl:message></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:result-document href="{replace($path,'.xml','.html')}">
            <xsl:choose>
                <xsl:when test="$fileType = 'HTML'">
                    <xsl:call-template name="html2html"/>
                </xsl:when>
                <xsl:when test="$fileType = 'TEI'">
                    <xsl:call-template name="tei2html"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>Unrecognizable file type <xsl:value-of select="$fileType"/></xsl:message>
                </xsl:otherwise>    
            </xsl:choose>
        </xsl:result-document>
    </xsl:template>
    <xsl:template name="html2html">
        <xsl:variable name="templatePath" select="string(/*:div/@data-template-with)"/>
        <xsl:variable name="template" select="document(concat($applicationPath,'/',$templatePath))"/>
        <html data-template="app:get-work" lang="en">
            <xsl:copy-of select="$template//*:head"/>
            <body id="body">
                <xsl:copy-of select="$template//*:nav"/>
                <xsl:copy-of select="."/>
            </body>
            <xsl:copy-of select="$template//*:footer"/>
            <script type="text/javascript" src="/resources/js/jquery.validate.min.js"/>
            <script type="text/javascript" src="/resources/js/srophe.js"/>
        </html>
    </xsl:template>
    <xsl:template name="tei2html">
        <xsl:variable name="idno" select="replace(//t:publicationStmt/t:idno[@type='URI'][1],'/tei','')"/>
        <xsl:variable name="collection" select="$config//*:collection[starts-with($idno, @record-URI-pattern)]"/>
        <xsl:variable name="app-root" select="string($collection/@app-root)"/>
        <xsl:variable name="recordTemplate" select="document(xs:anyURI(concat($applicationPath,$app-root,'record.html')))"/>
        <xsl:variable name="templatePath" select="string($recordTemplate//*:div/@data-template-with)"/>
        <xsl:variable name="template" select="document(concat($applicationPath,'/',$templatePath))"/>
        <html data-template="app:get-work" lang="en">
            <xsl:copy-of select="$template//*:head"/>
            <body id="body">
                <xsl:copy-of select="$template//*:nav"/>
                <xsl:choose>
                    <xsl:when test="$collection[@name='places']">
                        <xsl:call-template name="places"/>
                    </xsl:when>
                    <xsl:when test="$collection[@name='persons']">
                        <xsl:call-template name="persons"/>
                    </xsl:when>
                    <xsl:when test="$collection[@name='bibl']">
                        <xsl:call-template name="bibl"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="record"/>
                    </xsl:otherwise>
                </xsl:choose>
            </body>
        </html>
        <!-- 
        <html xmlns="http://www.w3.org/1999/xhtml" data-template="app:get-work" lang="en">
            <xsl:copy-of select="$template//*:head"/>
            <body id="body">
                <h1>TEST TEI</h1>
                <xsl:copy-of select="$template//*:nav"/>
                <xsl:apply-templates select="root(.)"/>
            </body>
            <xsl:copy-of select="$template//*:footer"/>
            <script type="text/javascript" src="/resources/js/jquery.validate.min.js"/>
            <script type="text/javascript" src="/resources/js/srophe.js"/>
        </html>
        -->
    </xsl:template>
    <xsl:template name="places">
        <xsl:variable name="type" select="string(//t:place/@type)"/>
        <div xmlns:xi="http://www.w3.org/2001/XInclude">
            <div class="grey-dark">
                <div class="section main-content-block white">
                    <xsl:apply-templates select="/t:teiHeader/t:fileDesc/t:titleStmt"/>
                    <div class="row">
                        <!-- Column 1 -->
                        <div class="col-md-8 column1">
                            <xsl:apply-templates select="//t:place/t:desc[@type='abstract']"/>
                            <div class="well">
                                <xsl:apply-templates select="//t:place/t:desc[@type='abstract']"/>
                                <xsl:choose>
                                    <xsl:when test="//t:place/descendant-or-self::t:geo">
                                        <div class="row">
                                            <div class="col-md-7">
<!--                                                {maps:build-map($data,0)}-->
                                            </div>
                                            <div class="col-md-5">
                                               <xsl:call-template name="placeLocation">
                                                   <xsl:with-param name="type" select="$type"/>
                                               </xsl:call-template>
                                            </div>    
                                        </div>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:call-template name="placeLocation">
                                            <xsl:with-param name="type" select="$type"/>
                                        </xsl:call-template>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </div>
                            <div>
                                <xsl:apply-templates select="//t:place/t:desc[not(@type='abstract')]"/>
                                <xsl:apply-templates select="//t:place/t:note"/>
                                <xsl:apply-templates select="//t:place/event"/>
                            </div>
                            <!-- Include description, nested locations, events, confessions and notes. -->
                            <!-- Get confessons 
                              
                                let $nested-loc := 
                                        for $nested-loc in collection($config:data-root || "/places/tei")/descendant::t:location[@type="nested"]/t:*[@ref=$ref-id]
                                        let $parent-name := $nested-loc/descendant::t:placeName[1]
                                        let $place-id := substring-after($nested-loc/ancestor::*/t:place[1]/@xml:id,'place-')
                                        let $place-type := $nested-loc/ancestor::*/t:place[1]/@type
                                        return 
                                            <nested-place id="{$place-id}" type="{$place-type}">
                                                {$nested-loc/ancestor::*/t:placeName[1]}
                                            </nested-place>
                                let $confessions := 
                                        if($model("hits")/descendant::t:state[@type='confession']) then 
                                            let $confessions := doc($config:app-root || "/documentation/confessions.xml")//t:list
                                            return 
                                            <confessions xmlns="http://www.tei-c.org/ns/1.0">
                                               {(
                                                $confessions,
                                                for $event in $model("hits")/descendant::t:event
                                                return $event,
                                                for $state in $model("hits")/descendant::t:state[@type='confession']
                                                return $state)}
                                            </confessions>
                                        else () 
                                return 
                                     global:tei2html(<place xmlns="http://www.tei-c.org/ns/1.0">
                                         {($desc-nodes, $nested-loc, $events-nodes, $confessions, $notes-nodes)}
                                     </place>)
                            -->
<!--                            <div data-template="place:body"/>-->
                            
                            <!-- Contact forms -->
                            <div style="margin-bottom:1em;">  
                                <!-- Button trigger corrections email modal -->
                                <button class="btn btn-default" data-toggle="modal" data-target="#feedback">Corrections/Additions?</button> 
                                <!--<button class="btn btn-default" data-toggle="modal" data-target="#selection" id="showSection">Is this record complete?</button>-->
                                <a href="#" class="btn btn-default" data-toggle="modal" data-target="#selection" data-ref="../documentation/faq.html" id="showSection">
                                    Is this record complete?
                                </a>
                                <!-- Modal email form-->
                                <xsl:call-template name="contact-form">
                                    <xsl:with-param name="collection">places</xsl:with-param>
                                </xsl:call-template>
                                
                                <!-- Modal faq popup -->
                                <div class="modal fade" id="selection" tabindex="-1" role="dialog" aria-labelledby="selectionLabel" aria-hidden="true">
                                    <div class="modal-dialog">
                                        <div class="modal-content">
                                            <div class="modal-header">
                                                <button type="button" class="close" data-dismiss="modal">
                                                    <span aria-hidden="true"> x </span>
                                                    <span class="sr-only">Close</span>
                                                </button>
                                                <h2 class="modal-title" id="selectionLabel">Is this record complete?</h2>
                                            </div>
                                            <div class="modal-body">
                                                <div>
                                                    <div id="recComplete" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                                                </div>
                                            </div>
                                            <div class="modal-footer">
                                                <a class="btn" href="../documentation/faq.html" aria-hidden="true">See all FAQs</a>
                                                <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <!-- Citation -->
                            <xsl:call-template name="sources"/>
                        </div>
                        <!-- Column 2 -->
                        <div class="col-md-4 column2">
                                <div id="placenames" class="well">
                                    <h3>Names</h3>
                                    <ul>
                                        <xsl:apply-templates select="t:placeName[(@syriaca-tags='#syriaca-headword' or @srophe:tags='#headword') and @xml:lang='syr']" mode="list">
                                            <xsl:sort lang="syr" select="."/>
                                        </xsl:apply-templates>
                                        <xsl:apply-templates select="t:placeName[(@syriaca-tags='#syriaca-headword' or @srophe:tags='#headword') and @xml:lang='en']" mode="list">
                                            <xsl:sort collation="{$mixed}" select="."/>
                                        </xsl:apply-templates>
                                        <xsl:apply-templates select="t:placeName[((not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') or (not(@srophe:tags) or @srophe:tags!='#headword')) and starts-with(@xml:lang, 'syr')]" mode="list">
                                            <xsl:sort lang="syr" select="."/>
                                        </xsl:apply-templates>
                                        <xsl:apply-templates select="t:placeName[starts-with(@xml:lang, 'ar')]" mode="list">
                                            <xsl:sort lang="ar" select="."/>
                                        </xsl:apply-templates>
                                        <xsl:apply-templates select="t:placeName[((not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') or (not(@srophe:tags) or @srophe:tags!='#headword')) and not(starts-with(@xml:lang, 'syr') or starts-with(@xml:lang, 'ar')) and not(@syriaca-tags='#syriaca-simplified-script')]" mode="list">
                                            <xsl:sort collation="{$mixed}" select="."/>
                                        </xsl:apply-templates>
                                    </ul>
                                </div>
                            <!-- Work in progress
                            <div data-template="place:related-places"/>
                            <div data-template="place:link-icons-list"/>
                            -->
                        </div>
                    </div>
                    <xsl:call-template name="citationInfo"/>
                </div>
            </div>
        </div>
    </xsl:template>
    <xsl:template name="persons">
        <div xmlns:xi="http://www.w3.org/2001/XInclude">
            <div class="grey-dark">
                <div class="section main-content-block white">
                    <xsl:for-each select="//t:person">
                        <xsl:call-template name="persons-title"/>
                        <div class="row">
                            <!-- Column 1 -->
                            <div class="col-md-8 column1">
                                <div id="persnames" class="well">
                                    <xsl:apply-templates select="."/>
                                </div>
<!--                                <div data-template="app:external-relationships" data-template-relationship-type="skos:broadMatch" data-template-collection="sbd"/>-->
                                <div data-template="person:note"/>
                                <xsl:apply-templates select="t:note"/>
<!--                                <div data-template="person:authored-by"/>-->
<!--                                <div data-template="person:related-places"/>-->
<!--                                <div data-template="person:timeline" data-template-dates="personal"/>-->
                                <div data-template="person:data"/>
                                <!--
                                <xsl:for-each select="element()">
                                    <xsl:if test=".[[not(self::t:persName)][not(self::t:bibl)]
                                        [not(self::*[@type='abstract' or starts-with(@xml:id, 'abstract-en')])]
                                        [not(self::t:state)][not(self::t:sex)][not(self::t:note[@type='description'])]]">
                                        <xsl:apply-templates/>
                                    </xsl:if>
                                </xsl:for-each>
                                -->
                                <xsl:call-template name="sources"/>
                            </div>
                            <!-- Column 2 -->
                            <div class="col-md-4 column2">
<!--                                <div data-template="app:rec-status"/>-->
                                <div class="info-btns">  
                                    <!-- Button trigger corrections email modal -->
                                    <button class="btn btn-default" data-toggle="modal" data-target="#feedback">Corrections/Additions?</button> 
                                    <a href="#" class="btn btn-default" data-toggle="modal" data-target="#selection" data-ref="../documentation/faq.html" id="showSection">
                                        Is this record complete?
                                    </a>
                                </div>
<!--                                <div data-template="person:relations"/>-->
<!--                                <div data-template="person:worldcat"/>-->
<!--                                <div data-template="person:link-icons-list"/>-->
                            </div>
                        </div>
                        <xsl:call-template name="citationInfo"/>
                    <!-- Modal email form-->
                        <xsl:call-template name="contact-form">
                            <xsl:with-param name="collection">persons</xsl:with-param>
                        </xsl:call-template>
                    <!-- Modal faq popup -->
                    <div class="modal fade" id="selection" tabindex="-1" role="dialog" aria-labelledby="selectionLabel" aria-hidden="true">
                        <div class="modal-dialog">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <button type="button" class="close" data-dismiss="modal">
                                        <span aria-hidden="true"> x </span>
                                        <span class="sr-only">Close</span>
                                    </button>
                                    <h2 class="modal-title" id="selectionLabel">Is this record complete?</h2>
                                </div>
                                <div class="modal-body">
                                    <div>
                                        <div id="recComplete" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                                    </div>
                                </div>
                                <div class="modal-footer">
                                    <a class="btn" href="../documentation/faq.html" aria-hidden="true">See all FAQs</a>
                                    <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal fade" id="moreInfo" tabindex="-1" role="dialog" aria-labelledby="moreInfoLabel" aria-hidden="true">
                        <div class="modal-dialog modal-lg">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <button type="button" class="close" data-dismiss="modal">
                                        <span aria-hidden="true">x</span>
                                        <span class="sr-only">Close</span>
                                    </button>
                                    <h2 class="modal-title" id="moreInfoLabel"/>
                                </div>
                                <div class="modal-body" id="modal-body">
                                    <div id="moreInfo-box"/>
                                    <br style="clear:both;"/>
                                </div>
                                <div class="modal-footer">
                                    <button class="btn btn-default" data-dismiss="modal">Close</button>
                                </div>
                            </div>
                        </div>
                    </div>
                    </xsl:for-each>
                </div>
            </div>
        </div>
    </xsl:template>
    <xsl:template name="persons-title">
        <div class="row title">
            <h1 class="col-md-8">
                <!-- Format title, calls template in place-title-std.xsl -->
                <xsl:call-template name="title"/>
                
            </h1>   
            <!-- End Title -->
        </div>
        <!-- emit record URI and associated help links -->
        <div class="idno seriesStmt" style="margin:0; margin-top:-1em; margin-bottom: 1em; padding:1em; color: #999999;">
            <xsl:variable name="current-id">
                <xsl:variable name="idString" select="tokenize($resource-id,'/')[last()]"/>
                <xsl:variable name="idSubstring">
                    <xsl:choose>
                        <xsl:when test="contains($idString,'-')">
                            <xsl:value-of select="substring-after($idString,'-')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$idString"/>
                        </xsl:otherwise>
                    </xsl:choose>                    
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$idSubstring  castable as xs:integer">
                        <xsl:value-of select="$idSubstring cast as xs:integer"/>
                    </xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="next-id" select="$current-id + 1"/>
            <xsl:variable name="prev-id" select="$current-id - 1"/>
            <xsl:variable name="next-uri" select="replace($resource-id,$current-id,string($next-id))"/>
            <xsl:variable name="prev-uri" select="replace($resource-id,$current-id,string($prev-id))"/>                
            <small>
                <span class="uri">
                    <xsl:if test="starts-with($nav-base,'/exist/apps')">
                        <a href="{replace($prev-uri,$base-uri,$nav-base)}">
                            <span class="glyphicon glyphicon-backward" aria-hidden="true"/>
                        </a>
                    </xsl:if>
                    <xsl:text> </xsl:text>
                    <button type="button" class="btn btn-default btn-xs" id="idnoBtn" data-clipboard-action="copy" data-clipboard-target="#syriaca-id">
                        <span class="srp-label">URI</span>
                    </button>
                    <xsl:text> </xsl:text>
                    <span id="syriaca-id">
                        <xsl:value-of select="$resource-id"/>
                    </span>
                    <script>
                        var clipboard = new Clipboard('#idnoBtn');
                        clipboard.on('success', function(e) {
                        console.log(e);
                        });
                        
                        clipboard.on('error', function(e) {
                        console.log(e);
                        });
                    </script>
                    <xsl:text> </xsl:text>
                    <xsl:if test="starts-with($nav-base,'/exist/apps')">
                        <a href="{replace($next-uri,$base-uri,$nav-base)}">
                            <span class="glyphicon glyphicon-forward" aria-hidden="true"/>
                        </a>
                    </xsl:if>
                </span>
                <xsl:if test="t:seriesStmt/t:biblScope/t:title">
                    <span class="series pull-right" style="margin-left:2em; padding-left:2em; display:inline">
                        <xsl:text>This page is an entry in </xsl:text>
                        <xsl:for-each select="distinct-values(t:seriesStmt/t:biblScope/t:title)">
                            <xsl:choose>
                                <xsl:when test=". = 'The Syriac Biographical Dictionary'"/>
                                <xsl:when test=". = 'A Guide to Syriac Authors'">
                                    <xsl:text> </xsl:text>
                                    <a href="{$nav-base}/authors/index.html">
                                        <span class="syriaca-icon syriaca-authors" style="font-size:1.35em; vertical-align: middle;">
                                            <span class="path1"/>
                                            <span class="path2"/>
                                            <span class="path3"/>
                                            <span class="path4"/>
                                        </span>
                                        <span> A Guide to Syriac Authors</span>
                                    </a>
                                </xsl:when>
                                <xsl:when test=". = 'Qadishe: A Guide to the Syriac Saints'">
                                    <xsl:text> </xsl:text>
                                    <a href="{$nav-base}/q/index.html">
                                        <span class="syriaca-icon syriaca-q" style="font-size:1.35em; vertical-align: middle;">
                                            <span class="path1"/>
                                            <span class="path2"/>
                                            <span class="path3"/>
                                            <span class="path4"/>
                                        </span>
                                        <span> Qadishe: A Guide to the Syriac Saints</span>
                                    </a>
                                </xsl:when>
                                <xsl:when test=". = 'Bibliotheca Hagiographica Syriaca Electronica'">
                                    <xsl:text> </xsl:text>
                                    <a href="{$nav-base}/bhse/index.html">
                                        <span class="syriaca-icon syriaca-bhse" style="font-size:1.35em; vertical-align: middle;">
                                            <span class="path1"/>
                                            <span class="path2"/>
                                            <span class="path3"/>
                                            <span class="path4"/>
                                        </span>
                                        <span> Bibliotheca Hagiographica Syriaca Electronica</span>
                                    </a>
                                </xsl:when>
                                <xsl:when test=". = 'New Handbook of Syriac Literature'">
                                    <xsl:text> </xsl:text>
                                    <a href="{$nav-base}/nhsl/index.html">
                                        <span class="syriaca-icon syriaca-nhsl" style="font-size:1.35em; vertical-align: middle;">
                                            <span class="path1"/>
                                            <span class="path2"/>
                                            <span class="path3"/>
                                            <span class="path4"/>
                                        </span>
                                        <span> New Handbook of Syriac Literature</span>
                                    </a>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="position() != last()"> and </xsl:if>
                        </xsl:for-each>    
                    </span>
                </xsl:if>
            </small>
        </div>
    </xsl:template>
    <xsl:template name="bibl">
        <div xmlns:xi="http://www.w3.org/2001/XInclude">
            <div class="main-content-block">
                <div class="interior-content white">
                    <xsl:apply-templates select="/t:teiHeader/t:fileDesc/t:titleStmt"/>
                    <div class="row">
                        <div class="col-md-8 column1">
                            <xsl:apply-templates select="//t:body"/>
                        </div>
                        <!-- Column 2 -->
                        <div class="col-md-4 column2">
<!--                            <div data-template="app:rec-status"/>-->
                            <div class="info-btns">  
                                <!-- Button trigger corrections email modal -->
                                <button class="btn btn-default" data-toggle="modal" data-target="#feedback">Corrections/Additions?</button> 
                                <a href="#" class="btn btn-default" data-toggle="modal" data-target="#selection" data-ref="../documentation/faq.html" id="showSection">
                                    Is this record complete?
                                </a>
                            </div>
<!--                            <div data-template="app:subject-headings"/>-->
<!--                            <div data-template="app:cited"/>-->
                        </div>
                    </div>
                </div>
                <br/>
                <xsl:call-template name="aboutEntry"/>
            </div>
            <!-- Modal email form-->
            <xsl:call-template name="contact-form">
                <xsl:with-param name="collection">bibl</xsl:with-param>
            </xsl:call-template>
            <!-- Modal faq popup -->
            <div class="modal fade" id="selection" tabindex="-1" role="dialog" aria-labelledby="selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                            <h2 class="modal-title" id="selectionLabel">Is this record complete?</h2>
                        </div>
                        <div class="modal-body">
                            <div>
                                <div id="recComplete" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="../documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal fade" id="moreInfo" tabindex="-1" role="dialog" aria-labelledby="moreInfoLabel" aria-hidden="true">
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true">x</span>
                                <span class="sr-only">Close</span>
                            </button>
                            <h2 class="modal-title" id="moreInfoLabel"/>
                        </div>
                        <div class="modal-body" id="modal-body">
                            <div id="moreInfo-box"/>
                            <br style="clear:both;"/>
                        </div>
                        <div class="modal-footer">
                            <button class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>
    <xsl:template name="record">
        <div xmlns:xi="http://www.w3.org/2001/XInclude">
            <div class="main-content-block">
                <div class="interior-content white">
                    <xsl:apply-templates select="/t:teiHeader/t:fileDesc/t:titleStmt"/>
                    <div class="row">
                        <div class="col-md-8 column1">
                            <xsl:apply-templates select="//t:body"/>
                        </div>
                        <!-- Column 2 -->
                        <div class="col-md-4 column2">
                            <!--                            <div data-template="app:rec-status"/>-->
                            <div class="info-btns">  
                                <!-- Button trigger corrections email modal -->
                                <button class="btn btn-default" data-toggle="modal" data-target="#feedback">Corrections/Additions?</button> 
                                <a href="#" class="btn btn-default" data-toggle="modal" data-target="#selection" data-ref="../documentation/faq.html" id="showSection">
                                    Is this record complete?
                                </a>
                            </div>
                            <!--                            <div data-template="app:subject-headings"/>-->
                            <!--                            <div data-template="app:cited"/>-->
                        </div>
                    </div>
                </div>
                <br/>
                <xsl:call-template name="citationInfo"/>
            </div>
            <!-- Modal email form-->
            <!--
            <xsl:call-template name="contact-form">
                <xsl:with-param name="collection">bibl</xsl:with-param>
            </xsl:call-template>
            -->
            <!-- Modal faq popup -->
            <div class="modal fade" id="selection" tabindex="-1" role="dialog" aria-labelledby="selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                            <h2 class="modal-title" id="selectionLabel">Is this record complete?</h2>
                        </div>
                        <div class="modal-body">
                            <div>
                                <div id="recComplete" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="../documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal fade" id="moreInfo" tabindex="-1" role="dialog" aria-labelledby="moreInfoLabel" aria-hidden="true">
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true">x</span>
                                <span class="sr-only">Close</span>
                            </button>
                            <h2 class="modal-title" id="moreInfoLabel"/>
                        </div>
                        <div class="modal-body" id="modal-body">
                            <div id="moreInfo-box"/>
                            <br style="clear:both;"/>
                        </div>
                        <div class="modal-footer">
                            <button class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template name="contact-form">
        <xsl:param name="collection"/>
        <!-- Work in progress -->
    </xsl:template>
    <xsl:template name="placeLocation">
        <xsl:param name="type"/>
        <div class="clearfix">
            <div id="type">
                <p><strong>Place Type: </strong>
                    <a href="../documentation/place-types.html#{normalize-space($type)}" class="no-print-link"><xsl:value-of select="$type"/></a>
                </p>
            </div>
            <xsl:if test="//t:place/t:location">
                <div id="location">
                    <xsl:for-each select="//t:place/t:location">
                        <xsl:sort select="if(@subtype = 'preferred') then 0 else 1"/>
                        <xsl:apply-templates/>
                    </xsl:for-each>
                </div>
            </xsl:if>
        </div>
    </xsl:template>
    
    
    <!-- This will become to bulky to deal with. 
    <xsl:template match="*" mode="convertXQuery">
        <xsl:choose>
            <xsl:when test="@data-template">
                
            </xsl:when>
            <xsl:otherwise>
                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    -->
</xsl:stylesheet>