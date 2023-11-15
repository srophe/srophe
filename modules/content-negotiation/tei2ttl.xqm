xquery version "3.0";
(:
 : Build Srophe TEI to ttl 
:)

module namespace tei2ttl="http://srophe.org/srophe/tei2ttl";
import module namespace bibl2html="http://srophe.org/srophe/bibl2html" at "bibl2html.xqm";
import module namespace tei2html="http://srophe.org/srophe/tei2html" at "tei2html.xqm";
import module namespace rel="http://srophe.org/srophe/related" at "../lib/get-related.xqm";
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";

import module namespace functx="http://www.functx.com";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=text media-type=text/turtle indent=yes";

(:~
 : Modified functx function to translate syriaca.org relationship names attributes to camel case.
 : @param $property as a string. 
:)
declare function tei2ttl:translate-relation-property($property as xs:string?) as xs:string{
    string-join((tokenize($property,'-')[1],
       for $word in tokenize($property,'-')[position() > 1]
       return functx:capitalize-first($word))
      ,'')
};

(:~
 : Create an RDF URI
 : @param $uri uri/id as xs:string 
 :)
declare function tei2ttl:make-uri($uri){
    concat('<',normalize-space($uri),'>')
};

(:~ 
 : Build literal string, normalize spaces and strip "", add lang if specified
 : @param $string string for literal
 : @param $lang language code as xs:string  
 :)
declare function tei2ttl:make-literal($string as xs:string*, $lang as xs:string*, $datatype as xs:string?) as xs:string?{
    concat('"',replace(normalize-space(string-join($string,' ')),'"',''),'"',
        if($lang != '') then concat('@',$lang) 
        else (), 
        if($datatype != '') then concat('^^',$datatype) else()) 
};

(:~ 
 : Build basic triple string, output as string. 
 : @param $s triple subject
 : @param $o triple object
 : @param $p triple predicate
 :)
declare function tei2ttl:make-triple($s as xs:string?, $o as xs:string?, $p as xs:string?) as xs:string* {
    concat('&#xa;', $s,' ', $o,' ', $p, ' ;')
};

(: Create lawd:hasAttestation for elements with a source attribute and a matching bibl element. :)
declare function tei2ttl:attestation($rec, $source){
    for $source in tokenize($source)
    return 
        let $source := 
            if($rec//tei:bibl[@xml:id = replace($source,'#','')]/tei:ptr) then
                string($rec//tei:bibl[@xml:id = replace($source,'#','')]/tei:ptr/@target)
            else string($source)
        return tei2ttl:make-triple('','lawd:hasAttestation', tei2ttl:make-uri($source))
};

(: Create dates :)
declare function tei2ttl:make-date-triples($date){
    concat('&#xa; time:hasDateTimeDescription [',string-join((
            if($date/descendant-or-self::text()) then 
               tei2ttl:make-triple('','skos:prefLabel', tei2ttl:make-literal(normalize-space(string-join($date/descendant-or-self::text(),' ')), (),()))
            else (),
            if($date/@when) then
                tei2ttl:make-triple('','time:year',
                   if($date/@when castable as xs:date) then 
                        tei2ttl:make-literal(string($date/@when), (),'xsd:date')
                    else if($date/@when castable as xs:dateTime) then 
                        tei2ttl:make-literal(string($date/@when), (),'xsd:dateTime')                        
                    else if($date/@when castable as xs:gYear) then 
                        tei2ttl:make-literal(string($date/@when), (),'xsd:gYear')
                    else if($date/@when castable as xs:gYearMonth) then
                        tei2ttl:make-literal(string($date/@when), (),'xsd:gYearMonth')
                    else tei2ttl:make-literal(string($date/@when), (),())
                    )
           else(),
           if($date/@notBefore or $date/@from) then
                tei2ttl:make-triple('','periodo:earliestYear',
                    let $date := if($date/@notAfter) then $date/@notAfter else $date/@to
                    return
                        if($date castable as xs:date) then 
                            tei2ttl:make-literal(string($date), (),'xsd:date')
                        else if($date castable as xs:dateTime) then 
                            tei2ttl:make-literal(string($date), (),'xsd:dateTime')                        
                        else if($date castable as xs:gYear) then 
                            tei2ttl:make-literal(string($date), (),'xsd:gYear')
                        else if($date castable as xs:gYearMonth) then
                            tei2ttl:make-literal(string($date), (),'xsd:gYearMonth')
                        else tei2ttl:make-literal(string($date), (),())
                    )    
            else (),
            if($date/@notAfter or $date/@to) then
                tei2ttl:make-triple('','periodo:latestYear',
                    let $date := if($date/@notAfter) then $date/@notAfter else $date/@to
                    return
                        if($date castable as xs:date) then 
                            tei2ttl:make-literal(string($date), (),'xsd:date')
                        else if($date castable as xs:dateTime) then 
                            tei2ttl:make-literal(string($date), (),'xsd:dateTime')                        
                        else if($date castable as xs:gYear) then 
                            tei2ttl:make-literal(string($date), (),'xsd:gYear')
                        else if($date castable as xs:gYearMonth) then
                            tei2ttl:make-literal(string($date), (),'xsd:gYearMonth')
                        else tei2ttl:make-literal(string($date), (),())
                    )    
            else ()            
        ),''),'];'
     )        
};

(:~ 
 : TEI descriptions
 : @param $rec TEI record. 
 :)
declare function tei2ttl:desc($rec) as xs:string* {
string-join((
for $desc in $rec/descendant::tei:desc[not(ancestor-or-self::tei:relation)]
let $source := $desc/tei:quote/@source
return
    if($desc[@type='abstract'][not(@source)][not(tei:quote/@source)] or $desc[contains(@xml:id,'abstract')][not(@source)][not(tei:quote/@source)][. != '']) then 
        tei2ttl:make-triple('', 'dcterms:description', tei2ttl:make-literal($desc,(),()))
    else 
        if($desc/child::* != '' or $desc != '') then 
            concat('&#xa; dcterms:description [',
                tei2ttl:make-triple('','rdfs:label', tei2ttl:make-literal($desc, string($desc/@xml:lang),())),
                    if($source != '') then
                       if($desc/ancestor::tei:TEI/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:licence/tei:p/tei:listBibl/tei:bibl/tei:ptr/@target = $source) then 
                            tei2ttl:make-triple('','dcterms:license', tei2ttl:make-uri(string($desc/ancestor::tei:TEI/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:licence/@target)))
                       else ()
                    else (),
            '];')
        else ()), '')
};

(:~
 : Handling tei:idno 
 : @param $rec TEI record.
 :)
declare function tei2ttl:idnos($rec, $id) as xs:string* {
let $ids := $rec//descendant::tei:body//tei:idno[@type='URI'][text() != $id]/text()
return 
if($ids != '') then
    string-join(
        (tei2ttl:make-triple('','skos:closeMatch',
           string-join((for $i in $ids
            return tei2ttl:make-uri($i)), ', ')),
        tei2ttl:make-triple('','dcterms:relation',
           string-join((for $i in $ids
            return tei2ttl:make-uri($i)), ', '))
            ),' ')
else ()   
};

(:~
 : Handling tei:bibl 
 : @param $rec TEI record.
 :)
declare function tei2ttl:bibl($rec) as xs:string* {
let $bibl-ids := $rec//descendant::tei:body//tei:bibl/tei:ptr/@target
(:[not(@type='lawd:ConceptualWork')]/tei:ptr:)
return 
if($bibl-ids != '') then 
        tei2ttl:make-triple('','dcterms:source',
           string-join((for $i in $bibl-ids
            return tei2ttl:make-uri($i)), ', '))
else ()   
};

(:~ 
 : Place/Person names 
 : @param $rec TEI record.
 :)
declare function tei2ttl:names($rec) as xs:string*{
string-join((
for $name in $rec/descendant::tei:body/descendant::tei:placeName | $rec/descendant::tei:body/descendant::tei:persName
return 
    if($name/parent::tei:place or $name/parent::tei:person) then  
            concat('&#xa; lawd:hasName [',
                if($name/@syriaca-tags='#syriaca-headword') then
                    string-join((tei2ttl:make-triple('','lawd:primaryForm',tei2ttl:make-literal($name/text(),$name/@xml:lang, ())),
                    tei2ttl:attestation($rec, $name/@source))) 
                else 
                    string-join((tei2ttl:make-triple('','lawd:variantForm',tei2ttl:make-literal($name/text(),$name/@xml:lang, ())),
                    tei2ttl:attestation($rec, $name/@source)))
            ,'];')
    else 
        if($name/ancestor::tei:location[@type='nested'][starts-with(@ref,$config:base-uri)]) then
           tei2ttl:make-triple('','dcterms:isPartOf',tei2ttl:make-uri($name/@ref)) 
        else if($name[starts-with(@ref,$config:base-uri)]) then  
            tei2ttl:make-triple('','skos:related',tei2ttl:make-uri($name/@ref))
        else ()),' ')        
};

(:~ 
 : Locations with coords 
 : @param $rec TEI record.
 :)
declare function tei2ttl:geo($rec) as xs:string*{
string-join((
for $geo in $rec/descendant::tei:location[tei:geo]
return 
    concat('&#xa;[',
        tei2ttl:make-triple('','geo:lat',tei2ttl:make-literal(tokenize($geo/tei:geo,' ')[1],(),())),
        tei2ttl:make-triple('','geo:long',tei2ttl:make-literal(tokenize($geo/tei:geo,' ')[2],(),())),
    '];')),'')
};

(:~
 : Uses XSLT templates to properly format bibl, extracts just text nodes. 
 : @param $rec
:)
declare function tei2ttl:bibl-citation($rec) as xs:string*{
let $citation := string-join(bibl2html:citation($rec/ancestor::tei:TEI))
return 
    tei2ttl:make-triple('','dcterms:bibliographicCitation', tei2ttl:make-literal($citation,(),()))
};

declare function tei2ttl:internal-refs($rec) as xs:string*{
let $links := distinct-values($rec/descendant::tei:body//@ref[starts-with(.,'http://')] | $rec/descendant::tei:body//@target[starts-with(.,'http://')])
return 
if($links != '') then
    tei2ttl:make-triple('','dcterms:relation',
           string-join((for $i in $links
            return tei2ttl:make-uri($i)), ', '))
else ()
};

declare function tei2ttl:rec-type($rec){
    if($rec/descendant::tei:body/tei:listPerson) then
        'lawd:Person'
    else if($rec/descendant::tei:body/tei:listPlace) then
        'lawd:Place'
    else if($rec/descendant::tei:body/tei:bibl[@type="lawd:ConceptualWork"]) then
        'lawd:conceptualWork'
    else if($rec/descendant::tei:body/tei:biblStruct) then
        'dcterms:bibliographicResource'        
    else if($rec/tei:listPerson) then
       'syriaca:personFactoid'    
    else if($rec/tei:listEvent) then
        'syriaca:eventFactoid'
    else if($rec/tei:listRelation) then
        'syriaca:relationFactoid'
    else()
};

(: 
 : Relations
 : @param $rec TEI record. 
 :)
declare function tei2ttl:relations-with-attestation($rec,$id){
if(contains($id,'/spear/')) then 
string-join((
    for $rel in $rec/descendant::tei:listRelation/tei:relation
    return 
        if($rel/@mutual) then 
            for $s in tokenize($rel/@mutual,' ')
            return
                string-join((
                    for $o in tokenize($rel/@mutual,' ')[. != $s]
                    let $element-name := if($rel/@ref and $rel/@ref != '') then string($rel/@ref) else if($rel/@name and $rel/@name != '') then string($rel/@name) else 'dcterms:relation'
                    let $element-name := if(starts-with($element-name,'dct:')) then replace($element-name,'dct:','dcterms:') else $element-name
                    let $relationshipURI := concat($o,'#',$element-name,'-',$s)
                    return 
                        tei2ttl:record(
                            concat(
                               tei2ttl:make-triple('', 'rdf:about', tei2ttl:make-uri($s)),
                               tei2ttl:make-triple('', 'dcterms:relation', tei2ttl:make-uri($o)),
                               tei2ttl:make-triple('', 'snap:has-bond', tei2ttl:make-uri($relationshipURI)))),
                    for $o in tokenize($rel/@mutual,' ')[. != $s]
                    let $element-name := if($rel/@ref and $rel/@ref != '') then string($rel/@ref) else if($rel/@name and $rel/@name != '') then string($rel/@name) else 'dcterms:relation'
                    let $element-name := if(starts-with($element-name,'dct:')) then replace($element-name,'dct:','dcterms:') else $element-name
                    let $relationshipURI := concat($o,'#',$element-name,'-',$s)
                    return 
                       tei2ttl:record(concat(tei2ttl:make-triple('', 'rdf:about', tei2ttl:make-uri($relationshipURI)),
                              tei2ttl:make-triple('', $element-name, tei2ttl:make-uri($o)),
                              tei2ttl:make-triple('', 'lawd:hasAttestation', tei2ttl:make-uri($id))))
                ),'')
        else 
            for $s in tokenize($rel/@active,' ')
            return 
                string-join((
                    for $o in tokenize($rel/@passive,' ')
                    let $element-name := if($rel/@ref and $rel/@ref != '') then string($rel/@ref) else if($rel/@name and $rel/@name != '') then string($rel/@name) else 'dcterms:relation'
                    let $element-name := if(starts-with($element-name,'dct:')) then replace($element-name,'dct:','dcterms:') else $element-name
                    let $relationshipURI := concat($o,'#',$element-name,'-',$s)
                    return 
                        tei2ttl:record(
                            concat(
                               tei2ttl:make-triple('', 'rdf:about', tei2ttl:make-uri($s)),
                               tei2ttl:make-triple('', 'dcterms:relation', tei2ttl:make-uri($o)),
                               tei2ttl:make-triple('', 'snap:has-bond', tei2ttl:make-uri($relationshipURI)))),
                     for $o in tokenize($rel/@passive,' ')
                     let $element-name := if($rel/@ref and $rel/@ref != '') then string($rel/@ref) else if($rel/@name and $rel/@name != '') then string($rel/@name) else 'dcterms:relation'
                     let $element-name := if(starts-with($element-name,'dct:')) then replace($element-name,'dct:','dcterms:') else $element-name
                     let $relationshipURI := concat($o,'#',$element-name,'-',$s)
                     return
                           tei2ttl:record(concat(tei2ttl:make-triple('', 'rdf:about', tei2ttl:make-uri($relationshipURI)),
                              tei2ttl:make-triple('', $element-name, tei2ttl:make-uri($o)),
                              tei2ttl:make-triple('', 'lawd:hasAttestation', tei2ttl:make-uri($id))))
                     ),'')
),'')
else()
};

declare function tei2ttl:relations($rec, $id){
string-join(
 ((
    for $rel in $rec/descendant::tei:listRelation/tei:relation
    let $ids := distinct-values((
                    for $r in tokenize($rel/@active,' ') return $r,
                    for $r in tokenize($rel/@passive,' ') return $r,
                    for $r in tokenize($rel/@mutual,' ') return $r
                    ))
    for $i in $ids 
    return 
        if(contains($id,'/spear/')) then 
            tei2ttl:make-triple('', 'dcterms:subject', tei2ttl:make-uri($i))
        else tei2ttl:make-triple('', 'dcterms:relation', tei2ttl:make-uri($i))
    ,
    for $rel in $rec/descendant::tei:listRelation/tei:relation
    return 
        if($rel/@mutual) then 
            for $s in tokenize($rel/@mutual,' ')
            for $o in tokenize($rel/@mutual,' ')[. != $s]
            let $element-name := if($rel/@ref and $rel/@ref != '') then string($rel/@ref) else if($rel/@name and $rel/@name != '') then string($rel/@name) else 'dcterms:relation'
            let $element-name := if(starts-with($element-name,'dct:')) then replace($element-name,'dct:','dcterms:') else $element-name
            let $relationshipURI := concat($o,'#',$element-name,'-',$s)
            return 
                if(contains($id,'/spear/')) then 
                    tei2ttl:make-triple('', 'snap:has-bond', tei2ttl:make-uri($relationshipURI))
                else tei2ttl:make-triple('', $element-name, tei2ttl:make-uri($o))    
        else 
            for $s in tokenize($rel/@active,' ')
            for $o in tokenize($rel/@passive,' ')
            let $element-name := if($rel/@ref and $rel/@ref != '') then string($rel/@ref) else if($rel/@name and $rel/@name != '') then string($rel/@name) else 'dcterms:relation'
            let $element-name := if(starts-with($element-name,'dct:')) then replace($element-name,'dct:','dcterms:') else $element-name
            let $relationshipURI := concat($o,'#',$element-name,'-',$s)
            return
                if(contains($id,'/spear/')) then  
                    tei2ttl:make-triple('', 'snap:has-bond', tei2ttl:make-uri($relationshipURI))
                else tei2ttl:make-triple('', $element-name, tei2ttl:make-uri($o))   
    ))
    ,' ')
};

(: Special handling for SPEAR :)
declare function tei2ttl:spear-related-triples($rec, $id){
    if(contains($id,'/spear/')) then
        (: Person Factoids :)
        if($rec/tei:listPerson) then  
            tei2ttl:record(string-join((
                tei2ttl:make-triple(tei2ttl:make-uri($rec/tei:listPerson/child::*/tei:persName/@ref), 'a', tei2ttl:rec-type($rec)),
                if($rec/tei:listPerson/child::*/tei:birth/tei:date) then 
                     tei2ttl:make-triple('', 'schema:birthDate', 
                        tei2ttl:make-literal(($rec/tei:listPerson/child::*/tei:birth/tei:date/@when | 
                        $rec/tei:listPerson/child::*/tei:birth/tei:date/@notAfter | 
                        $rec/tei:listPerson/child::*/tei:birth/tei:date/@notBefore),(),()))
                else(),
                if($rec/tei:listPerson/child::*/tei:birth/tei:placeName[@ref]) then
                    tei2ttl:make-triple('', 'schema:birthPlace', tei2ttl:make-uri($rec/tei:listPerson/child::*/tei:birth/tei:placeName/@ref))
                else(),
                if($rec/tei:listPerson/child::*/tei:nationality/tei:placeName/@ref) then 
                    tei2ttl:make-triple('', 'person:citizenship', tei2ttl:make-uri($rec/tei:listPerson/child::*/tei:nationality/tei:placeName/@ref))
                else(),
                if($rec/tei:listPerson/child::*/tei:death/tei:date) then 
                    tei2ttl:make-triple('', 'schema:deathDate', 
                        tei2ttl:make-literal(($rec/tei:listPerson/child::*/tei:death/tei:date/@when | 
                        $rec/tei:listPerson/child::*/tei:death/tei:date/@notAfter | 
                        $rec/tei:listPerson/child::*/tei:death/tei:date/@notBefore),(),()))
                else(),
                if($rec/tei:listPerson/child::*/tei:death/tei:placeName[@ref]) then 
                    tei2ttl:make-triple('', 'schema:deathPlace', tei2ttl:make-uri($rec/tei:listPerson/child::*/tei:death/tei:placeName/@ref))
                else(),
                if($rec/tei:listPerson/child::*/tei:education[@ref]) then 
                    tei2ttl:make-triple('', 'syriaca:studiedSubject', tei2ttl:make-uri($rec/tei:listPerson/child::*/tei:education/@ref))
                else(),
                if($rec/tei:listPerson/child::*/tei:trait[@type='ethnicLabel'][@ref]) then 
                    tei2ttl:make-triple('', 'cwrc:hasEthnicity', tei2ttl:make-uri($rec/tei:listPerson/child::*/tei:trait[@type='ethnicLabel']/@ref))
                else(),
                if($rec/tei:listPerson/child::*/tei:trait[@type='gender'][@ref]) then 
                    tei2ttl:make-triple('', 'schema:gender', tei2ttl:make-uri($rec/tei:listPerson/child::*/tei:trait[@type='ethnicLabel']/@ref))
                else(),
                if($rec/descendant::tei:person/tei:langKnowledge/tei:langKnown[@ref]) then
                    tei2ttl:make-triple('', 'cwrc:hasLinguisticAbility', tei2ttl:make-uri($rec/descendant::tei:person/tei:langKnowledge/tei:langKnown/@ref))
                else(),
                if($rec/tei:listPerson/child::*/tei:state[@type='mental'][@ref]) then 
                    tei2ttl:make-triple('', 'syriaca:hasMentalState', tei2ttl:make-uri($rec/tei:listPerson/child::*/tei:state/@ref))
                else(),
                if($rec/tei:listPerson/child::*/tei:occupation[@ref]) then
                    tei2ttl:make-triple('', 'snap:occupation', tei2ttl:make-uri($rec/tei:listPerson/child::*/tei:occupation/@ref))
                else(),
                if($rec/tei:listPerson/child::*/tei:trait[@type='physical'][@ref]) then 
                    tei2ttl:make-triple('', 'syriaca:hasPhysicalTrait', tei2ttl:make-uri($rec/tei:listPerson/child::*/tei:trait[@type='physical']/@ref))
                else(),
                if($rec/tei:listPerson/child::*/tei:residence/tei:placeName[@type='physical'][@ref]) then 
                    tei2ttl:make-triple('', 'person:residency', tei2ttl:make-uri($rec/tei:listPerson/child::*/tei:residence/tei:placeName[@type='physical']/@ref))
                else(),
                if($rec/tei:listPerson/child::*/tei:state[@type='sanctity'][@ref]) then
                    tei2ttl:make-triple('', 'syriaca:sanctity', tei2ttl:make-uri($rec/tei:listPerson/child::*/tei:state[@type='sanctity']/@ref))
                else(),
                if($rec/tei:listPerson/child::*/tei:sex) then
                    tei2ttl:make-triple('', 'syriaca:sex', tei2ttl:make-literal($rec/tei:listPerson/child::*/tei:sex/@value,(),()))
                else(),
                if($rec/tei:listPerson/child::*/tei:socecStatus[@ref]) then 
                    tei2ttl:make-triple('', 'syriaca:hasSocialRank', tei2ttl:make-uri($rec/tei:listPerson/child::*/tei:socecStatus/@ref))
                else(),
                if($rec/tei:listPerson/child::*/tei:trait[@type='physical'][@ref]) then 
                    tei2ttl:make-triple('', 'syriaca:hasPhysicalTrait', tei2ttl:make-uri($rec/tei:listPerson/child::*/tei:trait[@type='physical']/@ref))                    
                else(),
                if($rec/tei:listPerson/child::*/tei:persName[descendant-or-self::text()]) then 
                    for $name in $rec/tei:listPerson/child::*/tei:persName[descendant-or-self::text()]
                    return tei2ttl:make-triple('', 'foaf:name', tei2ttl:make-literal(string-join($name//text(),' '),(),()))
                else (),
                tei2ttl:make-triple('', 'lawd:hasAttestation', tei2ttl:make-uri($id))
             ),' '))
        else if($rec/descendant-or-self::tei:listRelation) then 
            tei2ttl:relations-with-attestation($rec,$id)
        else ()
    else ()
};

declare function tei2ttl:spear($rec, $id){
   if(contains($id,'/spear/')) then
        concat(if($rec/tei:listEvent) then string-join(( 
                (: Subjects:)
                let $subjects := tokenize($rec/descendant::tei:event/tei:ptr/@target,' ')
                for $subject in $subjects
                return tei2ttl:make-triple('', 'dcterms:subject', tei2ttl:make-uri($subject)),
                (: Places :)
                let $places := distinct-values($rec/descendant::tei:event/tei:desc/descendant::tei:placeName/@ref)
                for $place in $places
                return tei2ttl:make-triple('', 'schema:location', tei2ttl:make-uri($place)), 
                (: Dates :)
                let $dates := $rec/descendant::tei:event/descendant::tei:date/@when | $rec/descendant::tei:event/descendant::tei:date/@notBefore
                | $rec/descendant::tei:event/descendant::tei:date/@notAfter
                for $date in $dates
                return tei2ttl:make-triple('', 'dcterms:date', tei2ttl:make-literal(string($date),(),()))
                ),' ')
        else (),
        tei2ttl:bibl($rec),
        string-join((
        let $work-uris := distinct-values($rec/$rec/ancestor::tei:TEI/descendant::tei:teiHeader/descendant::tei:sourceDesc//@ref) 
        for $work-uri in $work-uris[contains(.,'/work/')]
        return tei2ttl:make-triple('', 'dcterms:source', tei2ttl:make-uri('http://syriaca.org/spear'))
        )),
        tei2ttl:make-triple('', 'dcterms:isPartOf', tei2ttl:make-uri(replace($rec/ancestor::tei:TEI/descendant::tei:teiHeader/descendant::tei:publicationStmt/tei:idno[@type="URI"][1],'/tei',''))),
        tei2ttl:make-triple('', 'dcterms:isPartOf', tei2ttl:make-uri('http://syriaca.org/spear'))
        )
    else () 
};

(: Prefixes :)
(: May not need these
@prefix geosparql: <http://www.opengis.net/ont/geosparql#> .
@prefix gn: <http://www.geonames.org/ontology#> .
:)
declare function tei2ttl:prefix() as xs:string{
"@prefix cwrc: <http://sparql.cwrc.ca/ontologies/cwrc#>.
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix geo: <http://www.w3.org/2003/01/geo/wgs84_pos#> .
@prefix lawd: <http://lawd.info/ontology/> .
@prefix owl: <http://www.w3.org/2002/07/owl#>.
@prefix periodo: <http://n2t.net/ark:/99152/p0v#>.
@prefix person: <https://www.w3.org/ns/person>,
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix schema: <http://schema.org/> .
@prefix skos: <http://www.w3.org/2004/02/skos/core#> .
@prefix syriaca: <http://syriaca.org/schema#> .
@prefix snap: <http://data.snapdrgn.net/ontology/snap#> .
@prefix time: <http://www.w3.org/2006/time#>.
@prefix wdata: <https://www.wikidata.org/wiki/Special:EntityData/>.
@prefix xsd: <http://www.w3.org/2001/XMLSchema#>. &#xa;"
};

(: Triples for a single record :)
declare function tei2ttl:make-triple-set($rec){
let $rec := if($rec/tei:div[@uri[starts-with(.,$config:base-uri)]]) then $rec/tei:div[@uri[starts-with(.,$config:base-uri)]] else $rec
let $id := if($rec/descendant::tei:idno[starts-with(.,$config:base-uri)]) then replace($rec/descendant::tei:idno[starts-with(.,$config:base-uri)][1],'/tei','')
           else if($rec/@uri[starts-with(.,$config:base-uri)]) then $rec/@uri[starts-with(.,$config:base-uri)]
           else $rec/descendant::tei:idno[1]
let $resource-class := if($rec/descendant::tei:body/tei:biblStruct) then 'rdfs:Resource'    
                       else 'skos:Concept'    
return 
    string-join((: start string-join-1:)(
        tei2ttl:record((:start record-1:) string-join((:start string-join-2:)(
        tei2ttl:make-triple(tei2ttl:make-uri($id), 'rdf:type', tei2ttl:rec-type($rec)),
        tei2ttl:make-triple((), 'a', tei2ttl:rec-type($rec)),
        tei2ttl:make-triple((),'rdfs:label',
                if($rec/descendant::*[@syriaca-tags='#syriaca-headword']) then
                    string-join(for $headword in $rec/descendant::*[@syriaca-tags='#syriaca-headword'][. != '']
                        return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else (),()),', ')
                else if($rec/descendant::tei:body/tei:listPlace/tei:place) then
                    string-join(for $headword in $rec/descendant::tei:body/tei:listPlace/tei:place/tei:placeName[. != '']
                        return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else (),()),', ')                        
                else if($rec[self::tei:div/@uri]) then
                        if(tei2ttl:rec-type($rec) = 'syriaca:relationFactoid') then
                            tei2ttl:make-literal(normalize-space(string-join(rel:relationship-sentence($rec/descendant::tei:listRelation/tei:relation),' ')),(),())
                        else tei2ttl:make-literal(normalize-space(string-join($rec/descendant::*[not(self::tei:citedRange)]/text(),' ')),(),())
                else tei2ttl:make-literal($rec/descendant::tei:title[1]/text(),if($rec/descendant::tei:title[1]/@xml:lang) then string($rec/descendant::tei:title[1]/@xml:lang) else (),())),
       if($rec/descendant::tei:body/tei:bibl[@type="lawd:ConceptualWork"] or $rec/descendant::tei:body/tei:biblStruct) then
               (for $author in $rec/descendant::tei:body/tei:bibl[@type="lawd:ConceptualWork"]/tei:author | $rec/descendant::tei:body/tei:biblStruct/descendant::tei:author
                return  
                        if($author/@ref) then
                            tei2ttl:make-triple((), 'dcterms:contributor', tei2ttl:make-uri($author/@ref))
                        else tei2ttl:make-triple((), 'dcterms:contributor', tei2ttl:make-literal(string-join($author/descendant-or-self::text(),' '),(),())),
                for $editor in $rec/descendant::tei:body/tei:bibl[@type="lawd:ConceptualWork"]/tei:editor | $rec/descendant::tei:body/tei:biblStruct/descendant::tei:editor
                return 
                        if($editor/@ref) then
                            tei2ttl:make-triple((), 'dcterms:contributor', tei2ttl:make-uri($editor/@ref))
                        else tei2ttl:make-triple((), 'dcterms:contributor', tei2ttl:make-literal(string-join($editor/descendant-or-self::text(),' '),(),()))
               )
       else (),
       tei2ttl:names($rec),
       if(contains($id,'/spear/')) then ()
       else tei2ttl:geo($rec),
       tei2ttl:idnos($rec, $id),
       tei2ttl:spear($rec, $id),
       tei2ttl:relations($rec, $id),
       let $links := distinct-values($rec//@ref[starts-with(.,'http://')][not(ancestor::tei:teiHeader)]) 
       for $i in $links[. != '']
       return tei2ttl:make-triple('', 'dcterms:relation', tei2ttl:make-uri($i)), 
       for $temporal in $rec/descendant::tei:state[@type="existence"]
       return tei2ttl:make-date-triples($temporal),        
       for $date in $rec/descendant::tei:event/descendant::tei:date
       return tei2ttl:make-date-triples($date),
       if(contains($id,'/spear/')) then
        tei2ttl:bibl-citation($rec)
       else (),
       for $bibl in $rec//tei:bibl[not(ancestor::tei:teiHeader)]/tei:ptr/@target[. != '']
       return  
            if(starts-with($bibl, "urn:cts:")) then 
                tei2ttl:make-triple('','lawd:hasAttestation', tei2ttl:make-uri($bibl))
            else tei2ttl:make-triple('','lawd:hasCitation', tei2ttl:make-uri($bibl)),
       tei2ttl:make-triple('','dcterms:hasFormat', 
            concat(tei2ttl:make-uri(concat($id,'/html')),
            ', ',tei2ttl:make-uri(concat($id,'/tei')),
            ', ',tei2ttl:make-uri(concat($id,'/ttl')),
            ', ',tei2ttl:make-uri(concat($id,'/rdf')))),
       tei2ttl:make-triple('','foaf:primaryTopicOf', tei2ttl:make-uri(concat($id,'/html'))),
       tei2ttl:make-triple('','foaf:primaryTopicOf', tei2ttl:make-uri(concat($id,'/tei'))),
       tei2ttl:make-triple('','foaf:primaryTopicOf', tei2ttl:make-uri(concat($id,'/ttl'))),
       tei2ttl:make-triple('','foaf:primaryTopicOf', tei2ttl:make-uri(concat($id,'/rdf'))),
       tei2ttl:internal-refs($rec)
    ),'') (:end string-join-2:) )(:end record-1:),
    if(contains($id,'/spear/')) then tei2ttl:spear-related-triples($rec, $id) 
    else tei2ttl:relations-with-attestation($rec,$id),
    if(contains($id,'/spear/')) then () 
    else 
        (
        (: rdfs:Resource, html :)
        tei2ttl:record(string-join((
            tei2ttl:make-triple(tei2ttl:make-uri(concat($id,'/html')), 'a', 'rdfs:Resource;'),
            tei2ttl:make-triple((),'dcterms:title',
                    if($rec/descendant::*[@syriaca-tags='#syriaca-headword']) then
                        string-join(for $headword in $rec/descendant::*[@syriaca-tags='#syriaca-headword'][. != '']
                            return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else (),()),', ')
                    else if($rec/descendant::tei:body/tei:listPlace/tei:place) then
                        string-join(for $headword in $rec/descendant::tei:body/tei:listPlace/tei:place/tei:placeName[. != '']
                            return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else (),()),', ')                        
                    else if($rec[self::tei:div/@uri]) then
                            if(tei2ttl:rec-type($rec) = 'syriaca:relationFactoid') then
                                tei2ttl:make-literal(normalize-space(string-join(rel:relationship-sentence($rec/descendant::tei:listRelation/tei:relation),' ')),(),())
                            else tei2ttl:make-literal(normalize-space(string-join($rec/descendant::*[not(self::tei:citedRange)]/text(),' ')),(),())
                    else tei2ttl:make-literal($rec/descendant::tei:title[1]/text(),if($rec/descendant::tei:title[1]/@xml:lang) then string($rec/descendant::tei:title[1]/@xml:lang) else (),())),
            tei2ttl:make-triple('','dcterms:subject', tei2ttl:make-uri($id)),
            if(contains($id,'/spear/')) then () else tei2ttl:bibl($rec),
            tei2ttl:make-triple('','dcterms:format', tei2ttl:make-literal('text/html',(),())),
            tei2ttl:bibl-citation($rec)
        ))),
        (: rdfs:Resource, tei :)
        tei2ttl:record(string-join((
            tei2ttl:make-triple(tei2ttl:make-uri(concat($id,'/tei')), 'a', 'rdfs:Resource;'),
            tei2ttl:make-triple((),'dcterms:title',
                    if($rec/descendant::*[@syriaca-tags='#syriaca-headword']) then
                        string-join(for $headword in $rec/descendant::*[@syriaca-tags='#syriaca-headword'][. != '']
                            return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else (),()),', ')
                    else if($rec/descendant::tei:body/tei:listPlace/tei:place) then
                        string-join(for $headword in $rec/descendant::tei:body/tei:listPlace/tei:place/tei:placeName[. != '']
                            return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else (),()),', ')                        
                    else if($rec[self::tei:div/@uri]) then
                            if(tei2ttl:rec-type($rec) = 'syriaca:relationFactoid') then
                                tei2ttl:make-literal(normalize-space(string-join(rel:relationship-sentence($rec/descendant::tei:listRelation/tei:relation),' ')),(),())
                            else tei2ttl:make-literal(normalize-space(string-join($rec/descendant::*[not(self::tei:citedRange)]/text(),' ')),(),())
                    else tei2ttl:make-literal($rec/descendant::tei:title[1]/text(),if($rec/descendant::tei:title[1]/@xml:lang) then string($rec/descendant::tei:title[1]/@xml:lang) else (),())),
            tei2ttl:make-triple('','dcterms:subject', tei2ttl:make-uri($id)),
            if(contains($id,'/spear/')) then () else tei2ttl:bibl($rec), 
            tei2ttl:make-triple('','dcterms:format', tei2ttl:make-literal('text/xml',(),())),
            tei2ttl:bibl-citation($rec)
        ))),
        (: rdfs:Resource, ttl :)
        tei2ttl:record(string-join((
            tei2ttl:make-triple(tei2ttl:make-uri(concat($id,'/ttl')), 'a', 'rdfs:Resource;'),
            tei2ttl:make-triple((),'dcterms:title',
                    if($rec/descendant::*[@syriaca-tags='#syriaca-headword']) then
                        string-join(for $headword in $rec/descendant::*[@syriaca-tags='#syriaca-headword'][. != '']
                            return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else (),()),', ')
                    else if($rec/descendant::tei:body/tei:listPlace/tei:place) then
                        string-join(for $headword in $rec/descendant::tei:body/tei:listPlace/tei:place/tei:placeName[. != '']
                            return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else (),()),', ')                        
                    else if($rec[self::tei:div/@uri]) then
                            if(tei2ttl:rec-type($rec) = 'syriaca:relationFactoid') then
                                tei2ttl:make-literal(normalize-space(string-join(rel:relationship-sentence($rec/descendant::tei:listRelation/tei:relation),' ')),(),())
                            else tei2ttl:make-literal(normalize-space(string-join($rec/descendant::*[not(self::tei:citedRange)]/text(),' ')),(),())
                    else tei2ttl:make-literal($rec/descendant::tei:title[1]/text(),if($rec/descendant::tei:title[1]/@xml:lang) then string($rec/descendant::tei:title[1]/@xml:lang) else (),())),        
                    tei2ttl:make-triple('','dcterms:subject', tei2ttl:make-uri($id)),
            tei2ttl:make-triple('','dcterms:subject', tei2ttl:make-uri($id)),
            if(contains($id,'/spear/')) then () else tei2ttl:bibl($rec),         
            tei2ttl:make-triple('','dcterms:format', tei2ttl:make-literal('text/turtle',(),())),
            tei2ttl:bibl-citation($rec)
        )))        
    
        )
    
    ),'')(: end string-join-1:) 
    
};

(: Make sure record ends with a '.' :)
declare function tei2ttl:record($triple as xs:string*) as xs:string*{
    replace($triple,';$','.&#xa;')
};

declare function tei2ttl:ttl-output($recs) {
    serialize((concat(tei2ttl:prefix(), tei2ttl:make-triple-set($recs))), 
        <output:serialization-parameters>
            <output:method>text</output:method>
            <output:media-type>text/plain</output:media-type>
        </output:serialization-parameters>)
};
