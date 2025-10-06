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

(:
 : Get a series of records by id (in data.xql), display as expandable list
 : Include maps? {if($related//tei:geo) then
                    maps:build-map($related,count($related//tei:geo))
                else ()}
:)
declare function relations:get-related($data as node()*, $relID as xs:string?){    
    let $count := count($data)
    return 
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
    else ())
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
        if(contains($type,':')) then 
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
            default return concat(' ', functx:capitalize-first(functx:camel-case-to-words(replace($relationship-name,'-',' '),' ')),' ') 
};

(:
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
        return 
            <div class="relation internal-relationships"  xmlns="http://www.w3.org/1999/xhtml">
                <h4 class="relationship-type">{$title}&#160;{relations:stringify-relationship-type($relationship)} ({$count})</h4>
                <div class="indent">
                    <div class="dynamicContent" data-url="{concat($config:nav-base,'/modules/data.xql?ids=',$ids,'&amp;relID=',$rel-id,'&amp;relationship=internal')}"></div>
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