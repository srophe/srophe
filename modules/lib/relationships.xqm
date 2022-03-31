xquery version "3.0";
(: Get and build TEI relationships :)
module namespace relations="http://srophe.org/srophe/relationships";
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
import module namespace global="http://srophe.org/srophe/global" at "global.xqm";
import module namespace data="http://srophe.org/srophe/data" at "data.xqm";
import module namespace maps="http://srophe.org/srophe/maps" at "maps.xqm";
import module namespace tei2html="http://srophe.org/srophe/tei2html" at "../content-negotiation/tei2html.xqm";

import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace srophe="https://srophe.app";

(:
 : Get a series of records by id (in data.xql), display as expandable list
 : Include maps? {if($related//tei:geo) then
                    maps:build-map($related,count($related//tei:geo))
                else ()}
:)
declare function relations:get-related($data as node()*, $relID as xs:string?){    
    let $count := count($data)
    return 
        if($data/descendant-or-self::*:external) then
            for $r in subsequence($data,1,2)
            return 
            <div class="short-rec-view">
                <a href="{$r/@uri}" dir="ltr">
                    <span class="tei-title" lang="en">{$r//*:title[1]/text()}</span>
                </a>
                <span class="results-list-desc uri">
                    <span class="srp-label">URI: </span>
                    <a href="{$r/@uri}">{string($r/@uri)}</a>
                </span>
            </div>
        else 
            (   
                for $r in subsequence($data,1,2)
                let $rid := replace($r//tei:idno[@type='URI'][1],'/tei','')
                return tei2html:summary-view(root($r), '', $rid),
                    if($count gt 2) then
                        <span>
                            <span class="collapse" id="showRel-{$relID}">{
                                for $r in subsequence($data,3,$count)
                                let $rid := replace($r//tei:idno[@type='URI'][1],'/tei','')
                                return tei2html:summary-view(root($r), '', $rid)                        
                            }</span>
                            <a class="more" data-toggle="collapse" data-target="#showRel-{$relID}" data-text-swap="Hide"> See all {$count} &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>
                        </span>                        
                     else ()
            )
};


declare function relations:display-records($data as node()*, $queryString as xs:string?){   
    if($data != '') then
        <div>{(
            if(request:get-parameter("label", ()) != '') then             
                    <h4>{request:get-parameter("label", ())}</h4>
            else (),
            let $count := count($data)
            return 
            (for $r in subsequence($data,1,2)
            let $rid := replace($r//tei:idno[@type='URI'][1],'/tei','')
            return tei2html:summary-view(root($r), '', $rid),
            if(($count gt 2) and ($count lt 10)) then
                <span>
                    <span class="collapse" id="showRel-{generate-id($data[1])}">{
                        for $r in subsequence($data,3,$count)
                        let $rid := replace($r//tei:idno[@type='URI'][1],'/tei','')
                        return tei2html:summary-view(root($r), '', $rid)                        
                    }</span>
                    <a class="more" data-toggle="collapse" data-target="#showRel-{generate-id($data[1])}" data-text-swap="Hide"> See all {$count} &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>
                </span>
            else if($count gt 9) then
                <a class="more" href="{concat('search.html?',$queryString)}"> See all {$count} &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>                        
            else ()
            )
        )}
        </div>
    else ()
};

declare function relations:stringify-relationship-type($type as xs:string*){
    if(global:odd2text('relation',$type) != '') then global:odd2text('relation',$type)    
    else relations:decode-relationship($type)
};

(:~
 : Translate relationship types based on SPEAR spreadsheet.
 : Assumes active/passive SPEAR
 :)
declare function relations:decode-relationship($type as xs:string?){
    let $relationship-name := 
        if(contains($type,'#')) then 
            substring-after($type,'#')   
        else if(contains($type,':')) then 
            substring-after($type,':')         
        else $type
    return 
        switch ($relationship-name)
            (: @ana = 'clerical':)
            case "Baptism" return " was baptized by "
            case "BishopOver" return " was under the authority of bishop "
            case "BishopOverBishop" return " was a bishop under the authority of bishop "
            case "BishopOverClergy" return " was a clergyperson under the authority of the bishop "
            case "BishopOverMonk" return " was a monk under the authority of the bishop "
            case "Ordination" return " was ordained by "
            case "ClergyFor" return " as a clergyperson " (: Full @passive had @active as a clergyperson.:)
            case "CarrierOfLetterBetween" return " exchanged a letter carried by "
            case "EpistolaryReferenceTo" return " was referenced in a letter between "
            case "LetterFrom" return " received a letter from "
            case "SenderOfLetterTo" return " received a letter from "
            (: @ana = 'family':)
            case "GreatGrandparentOf" return " had a great grandparent "
            case "AncestorOf" return " was the descendant of "
            case "ChildOf" return " was the parent of "
            case "SiblingOf" return " were siblings"
            case "ChildOfSiblingOf" return " was the sibling of a parent of "
            case "descendantOf" return " was the ancestor of "
            case "GrandchildOf" return " was the grandparent of "
            case "GrandparentOf" return " was the grandchild of "
            case "ParentOf" return " was the child of "
            case "SiblingOfParentOf" return " was a child of a sibling of "
            (: @ana = 'general' :)
            case "EnmityFor" return " was the object of the enmity of "
            case "MemberOfGroup" return " contained "
            case "Citation" return " was cited by "
            case "FollowerOf" return " had as a follower "
            case "StudentOf" return " had as a teacher "
            case "Judged" return " was judged by "
            case "LegalChargesAgainst" return " was the subject of a legal action brought by "
            case "Petitioned" return " received a petition or a request for legal action from "
            case "CommandOver" return " was under the command of "
            case "MonasticHeadOver" return " was under the monastic authority of "
            case "Commemoration" return " was commemorated by "  
            case "FreedSlaveOf" return " was released from slavery to "
            case "HouseSlaveOf" return " was held as a house slave "   
            case "SlaveOf" return " held as a slave "      
            (: @ana 'event' :)
            case "SameAs" return " refer to the same event. "
            case "CloseConnection" return " deal with closely related events."
            (: general :)
            case "broader" return " has a broader match with "
            case "closeMatch" return " has a close match with "
            default return concat('TEST1 ',$relationship-name)
            (:concat(' ', functx:capitalize-first(functx:camel-case-to-words(replace($relationship-name,'-',' '),' ')),' '):) 
};

(: Get cited works :)
declare function relations:cited($idno as xs:string?, $start as xs:string?, $perpage as xs:string?){
    <div class="relation internal-relationships"  xmlns="http://www.w3.org/1999/xhtml">
        <h4 class="relationship-type"></h4>
        <div class="indent">
            <div class="dynamicContent" data-url="{concat($config:nav-base,'/modules/data.xql?bibl=',$idno,'&amp;perpage=',$perpage,'&amp;sort=alpha&amp;collection=bibl&amp;queryType=search&amp;label=Cited in')}"></div>
        </div>
    </div>   
};
(:
declare function relations:subject-headings($idno as xs:string?){
    <div class="relation internal-relationships"  xmlns="http://www.w3.org/1999/xhtml">
        <h4 class="relationship-type">TESTING</h4>
        <div class="indent">
            <div class="dynamicContent" data-url="{concat($config:nav-base,'/modules/data.xql?bibl=',$idno,'&amp;perpage=',$perpage,'&amp;sort=alpha&amp;collection=bibl&amp;queryType=search&amp;label=Cited in')}"></div>
        </div>
    </div>   
};
:)

(:
 : @depreciated - spelling error
 : Get internal relationships, group by type
 : dynamically pass related ids to data.xql for async loading.  
 : 
:)
declare function relations:display-internal-relatiobships($data as node()*, $currentID as xs:string?, $type as xs:string?){
    let $record := $data
    let $title := if(contains($record/descendant::tei:title[1]/text(),' — ')) then 
                        substring-before($record/descendant::tei:title[1],' — ') 
                   else $record/descendant::tei:title[1]/text()
    let $uris := 
                string-join(
                    if($type != '') then
                        for $r in $record/descendant-or-self::tei:relation[@ref=$type]
                        return string-join(($r/@active/string(),$r/@passive/string(),$r/@mutual/string()),' ')
                    else
                        for $r in $record/descendant-or-self::tei:relation
                        return string-join(($r/@active/string(),$r/@passive/string(),$r/@mutual/string()),' '),' ')
    let $relationships := 
                    if($type != '') then
                        $record/descendant-or-self::tei:relation[@ref=$type]
                    else $record/descendant-or-self::tei:relation 
    for $related in $relationships
    let $rel-id := index-of($record, $related[1])
    let $rel-type := if($related/@ref) then $related/@ref else $related/@name
    group by $relationship := $rel-type
    return 
        let $ids := string-join(($related/@active/string(),$related/@passive/string(),$related/@mutual/string()),' ')
        let $ids := 
            string-join(
                distinct-values(
                    tokenize($ids,' ')[not(. = $currentID)]),' ')
        let $count := count(tokenize($ids,' ')[not(. = $currentID)])
        let $relationship-type := $relationship 
        let $relationshipTypeID := replace($relationship-type,' ','')
        return 
            <div class="relation internal-relationships"  xmlns="http://www.w3.org/1999/xhtml">
                <h4 class="relationship-type">{$title}&#160;{relations:stringify-relationship-type($relationship)} ({$count})</h4>
                <div class="indent">
                    <div class="dynamicContent" data-url="{concat($config:nav-base,'/modules/data.xql?ids=',$ids,'&amp;relID=',$relationshipTypeID,'&amp;relationship=internal')}"></div>
                    {
                    if($count gt 10) then 
                        <a class="more" href="{concat($config:nav-base,'/search.html?=?ids=',$ids,'&amp;relID=',$relationshipTypeID,'&amp;relationship=internal')}">See all</a>
                    else ()
                    }
                </div>
            </div>
};

(:
 : Get internal relationships, group by type
 : dynamically pass related ids to data.xql for async loading.  
 : 
:)
declare function relations:display-internal-relationships($data as node()*, $currentID as xs:string?, $type as xs:string?){
    let $record := $data
    let $title := if($record[1]/descendant::tei:text/tei:body[descendant::*[@srophe:tags = '#syriaca-headword2']]) then
                        $record[1]/descendant::tei:text/tei:body[descendant::*[@srophe:tags = '#syriaca-headword']][@xml:lang = 'en']/text()
                   else if(contains($record/descendant::tei:title[1]/text(),' — ')) then 
                        substring-before($record/descendant::tei:title[1],' — ')
                   else if(contains($record/descendant::tei:title[1]/text(),' - ')) then 
                        substring-before($record/descendant::tei:title[1],' - ')     
                   else string-join($record/descendant::tei:title[1]//text(),'')
    let $uris := 
                string-join(
                    if($type != '') then
                        for $r in $record/descendant-or-self::tei:relation[@ref=$type]
                        return string-join(($r/@active/string(),$r/@passive/string(),$r/@mutual/string()),' ')
                    else
                        for $r in $record/descendant-or-self::tei:relation
                        return string-join(($r/@active/string(),$r/@passive/string(),$r/@mutual/string()),' '),' ')
    let $relationships := 
                    if($type != '') then
                        $record/descendant-or-self::tei:relation[@ref=$type]
                    else $record/descendant-or-self::tei:relation 
    for $related in $relationships
    let $rel-id := index-of($record, $related[1])
    let $rel-type := if($related/@name) then $related/@name else if($related/@ref) then $related/@ref else $related/@name
    group by $relationship := $rel-type
    return 
        let $ids := string-join(($related/@active/string(),$related/@passive/string(),$related/@mutual/string()),' ')
        let $ids := 
            string-join(
                distinct-values(
                    tokenize($ids,' ')[not(. = $currentID)]),' ')
        let $count := count(tokenize($ids,' ')[not(. = $currentID)])
        let $relationship-type := $relationship 
        let $relationshipTypeID := replace($relationship-type,' ','')
        return 
            <div class="relation internal-relationships"  xmlns="http://www.w3.org/1999/xhtml">
                <h4 class="relationship-type">{$title[1]}&#160;{relations:stringify-relationship-type($relationship)} ({$count})</h4>
                <div class="indent">
                    <div class="dynamicContent" data-url="{concat($config:nav-base,'/modules/data.xql?ids=',$ids,'&amp;relID=',$relationshipTypeID,'&amp;relationship=internal')}"></div>
                    {
                    if($count gt 10) then 
                        <a class="more" href="{concat($config:nav-base,'/search.html?=?ids=',$ids,'&amp;relID=',$relationshipTypeID,'&amp;relationship=internal')}">See all</a>
                    else ()
                    }
                </div>
            </div>
};

(:
 : Build external relationships, i.e, aggrigate all records which reference the current record, 
 : as opposed to rel:build-relationships which displays record information for records referenced in the current record.
 : @param $currentID current record id 
 : @param $title current record title 
 : @param $relType relationship type
 : @param $collection current record collection
 : @param $sort sort on title or part number default to title
 : @param $count number of records to return, if empty defaults to 5 with a popup for more.
:)
declare function relations:display-external-relatiobships($currentID as xs:string?, $type as xs:string?, $label as xs:string?){
   let $relationship-string := 
        if($type != '') then
            concat("[descendant::tei:relation[@passive[matches(.,'",$currentID,"(\W.*)?$')] or @mutual[matches(.,'",$currentID,"(\W.*)?$')]][@ref = '",$type ,"' or @name = '",$type ,"']]")
        else concat("[descendant::tei:relation[@passive[matches(.,'",$currentID,"(\W.*)?$')] or @mutual[matches(.,'",$currentID,"(\W.*)?$')]]]")
   let $eval-string := concat("collection($config:data-root)/tei:TEI",$relationship-string)
   let $related := util:eval($eval-string)
   let $total := count($related)    
   return 
        if($total gt 0) then 
            <div class="relation external-relationships" xmlns="http://www.w3.org/1999/xhtml">
                <h3>{if($label != '') then $label else 'External Relationships' }</h3>
                {if($related//tei:geo) then
                    maps:build-map($related,count($related//tei:geo))
                else ()}
                <div class="indent">
                {
                if($total gt 5) then
                    (
                    for $r in subsequence($related,1,5)
                    let $id := replace($r/descendant::tei:idno[1],'/tei','')
                    return tei2html:summary-view($r, (), $id[1]),
                    <a class="more" href="{$config:nav-base}/search.html?relationship-type={$type}&amp;relation-id={$currentID}">See all</a>)
                else
                    for $r in $related
                    let $id := replace($r/descendant::tei:idno[1],'/tei','')
                    return tei2html:summary-view($r, (), $id[1])
                }
                </div>
            </div>  
        else()       
};

declare function relations:related-places-map($data as node()*, $currentID as xs:string?){
    let $record := $data
    let $title := if(contains($record/descendant::tei:title[1]/text(),' — ')) then 
                        substring-before($record/descendant::tei:title[1],' — ') 
                   else $record/descendant::tei:title[1]/text()
    let $uris := 
                string-join(
                        for $r in $record/descendant-or-self::tei:relation
                        return string-join(($r/@active/string(),$r/@passive/string(),$r/@mutual/string()),' '),' ') 
    let $ids := 
            string-join(
                distinct-values(
                    tokenize($uris,' ')[not(. = $currentID)][contains(.,'/place/')]),' ')
    let $count := count(tokenize($ids,' ')[not(. = $currentID)])
    return 
            if($count gt 0) then
                <div class="relation internal-relationships"  xmlns="http://www.w3.org/1999/xhtml">
                    <div class="indent">
                        <div class="dynamicContent" data-url="{concat($config:nav-base,'/modules/data.xql?ids=',$ids,'&amp;relID=',$currentID,'&amp;relationship=map')}"></div>
                    </div>
                </div> 
            else ()       
};
(: 
    <div id="map-data" style="margin-bottom:3em;">
        <!--<script type="text/javascript" src="{$config:nav-base}/resources/leaflet/leaflet.awesome-markers.min.js"/>-->
        <!--
        <script src="http://isawnyu.github.com/awld-js/lib/requirejs/require.min.js" type="text/javascript"/>
        <script src="http://isawnyu.github.com/awld-js/awld.js?autoinit" type="text/javascript"/>
        -->
        <div id="map"/>
        {
            if($total-count gt 0) then 
               <div class="hint map pull-right small">
                * This map displays {count($nodes)} records. Only places with coordinates are displayed. 
                     <button class="btn btn-default btn-sm" data-toggle="modal" data-target="#map-selection" id="mapFAQ">See why?</button>
               </div>
            else ()
            }
        <script type="text/javascript">
            <![CDATA[
            var terrain = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {attribution: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community'});
                                
            /* Not added by default, only through user control action */
            var streets = L.tileLayer('http://api.tiles.mapbox.com/v3/sgillies.map-pmfv2yqx/{z}/{x}/{y}.png', {attribution: "ISAW, 2012"});
                                
            var imperium = L.tileLayer('http://pelagios.dme.ait.ac.at/tilesets/imperium//{z}/{x}/{y}.png', {attribution: 'Tiles: &lt;a href="http://pelagios-project.blogspot.com/2012/09/a-digital-map-of-roman-empire.html"&gt;Pelagios&lt;/a&gt;, 2012; Data: NASA, OSM, Pleiades, DARMC', maxZoom: 11 });
                                
            var placesgeo = ]]>{geojson:geojson($nodes)}
            <![CDATA[                                
                                        
            var geojson = L.geoJson(placesgeo, {onEachFeature: function (feature, layer){
                            var typeText = feature.properties.type
                            var popupContent = 
                                "<a href='" + feature.properties.uri + "' class='map-pop-title'>" +
                                feature.properties.name + "</a>" + (feature.properties.type ? "Type: " + typeText : "") +
                                (feature.properties.desc ? "<span class='map-pop-desc'>"+ feature.properties.desc +"</span>" : "");
                                layer.bindPopup(popupContent);               
                                }
                            })
        var map = L.map('map',{scrollWheelZoom:false}).fitBounds(geojson.getBounds(),{maxZoom: 5}).setZoom(5);    
        terrain.addTo(map);
                                        
        L.control.layers({
                        "Terrain (default)": terrain,
                        "Streets": streets,
                        "Imperium": imperium }).addTo(map);
        geojson.addTo(map);     
        ]]>
        </script>
         <div>
            <div class="modal fade" id="map-selection" tabindex="-1" role="dialog" aria-labelledby="map-selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="/documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
         </div>
         <script type="text/javascript">
         <![CDATA[
            $('#mapFAQ').click(function(){
                $('#popup').load( '../documentation/faq.html #map-selection',function(result){
                    $('#map-selection').modal({show:true});
                });
             });]]>
         </script>
    </div> 
    
<div class="dynamicContent" data-url="{concat($config:nav-base,'/modules/data.xql?ids=',$ids,'&amp;relID=',$currentID,'&amp;relationship=map')}"></div>

:)

(:
 : Use OCLC API to return VIAF records 
 : limit to first 5 results
 : @param $rec
 : NOTE param should just be tei:idno as string
:)
declare function relations:worldcat($node as node(), $model as map(*)){
let $rec := $model("hits")
return 
    try {
        if($rec/descendant::tei:idno[starts-with(.,'http://worldcat.org/identities/lccn-n')] or $rec/descendant::tei:idno[starts-with(.,'http://viaf.org/viaf')][not(contains(.,'sourceID'))]) then
            let $viaf-ref := if($rec/descendant::tei:idno[@type='URI'][contains(.,'http://worldcat.org/identities/lccn-n')]) then 
                                        $rec/descendant::tei:idno[@type='URI'][contains(.,'http://worldcat.org/identities/lccn-n')][1]/text()
                                     else $rec/descendant::tei:idno[@type='URI'][not(contains(.,'sourceID/SRP')) and starts-with(.,'http://viaf.org/viaf')][1]
            let $uri := if(starts-with($viaf-ref,'http://viaf.org/viaf')) then 
                            (:
                                    let $rdf := http:send-request(<http:request href="{concat($viaf-ref,'/rdf.xml')}" method="get"/>)[2]//schema:sameAs/child::*/@rdf:about[starts-with(.,'http://id.loc.gov/')]
                                    let $lcc := tokenize($rdf,'/')[last()]
                                    return concat('http://worldcat.org/identities/lccn-',$lcc)
                             :)''  
                             else $viaf-ref
            return 
                if($uri != '') then 
                    try {(:
                        let $results :=  http:send-request($build-request)//by 
                        let $total-works := string($results/ancestor::Identity//nameInfo/workCount)
                        return 
                            if(not(empty($results)) and  $total-works != '0') then 
                                    <div id="worldcat-refs" class="well">
                                        <h3>{$total-works} Catalog Search Results from WorldCat</h3>
                                        <p class="hint">Based on VIAF ID. May contain inaccuracies. Not curated by Syriaca.org.</p>
                                        <div>
                                             <ul id="{$viaf-ref}" count="{$total-works}">
                                                {
                                                    for $citation in $results/citation[position() lt 5]
                                                    return
                                                        <li><a href="{concat('http://www.worldcat.org/oclc/',substring-after($citation/oclcnum/text(),'ocn'))}">{$citation/title/text()}</a></li>
                                                 }
                                             </ul>
                                             <span class="pull-right"><a href="{$uri}">See all {$total-works} titles from WorldCat</a></span>,<br/>
                                        </div>
                                    </div>    
                                             
                            else ():)'Test worldcat'
                    } catch * {
                        <error>Caught error {$err:code}: {$err:description}</error>
                    } 
                 else ()   
        else ()
    } catch * {
        <error>Caught error {$err:code}: {$err:description}</error>
    } 
};
