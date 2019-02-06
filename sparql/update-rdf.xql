xquery version "3.0";
(:
 : Build Srophe TEI to RDF/XML 
 : 
:)
module namespace tei2rdf="http://syriaca.org/srophe/tei2rdf";
import module namespace bibl2html="http://syriaca.org/srophe/bibl2html" at "../modules/content-negotiation/bibl2html.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "../modules/content-negotiation/tei2html.xqm";
import module namespace rel="http://syriaca.org/srophe/related" at "../modules/lib/get-related.xqm";
import module namespace config="http://syriaca.org/srophe/config" at "../modules/config.xqm";

import module namespace functx="http://www.functx.com";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace foaf = "http://xmlns.com/foaf/0.1";
declare namespace lawd = "http://lawd.info/ontology";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace dcterms = "http://purl.org/dc/terms/";
declare namespace rdfs = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace owl = "http://www.w3.org/2002/07/owl#";
declare namespace snap = "http://data.snapdrgn.net/ontology/snap#";
declare namespace syriaca = "http://syriaca.org/schema#";
declare namespace schema = "http://schema.org/";
declare namespace person = "http://syriaca.org/person/";
declare namespace cwrc = "http://sparql.cwrc.ca/ontologies/cwrc#";
declare namespace geo  = "http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace time =  "http://www.w3.org/2006/time#";
declare namespace periodo = "http://n2t.net/ark:/99152/p0v#";

declare option exist:serialize "method=xml media-type=application/xml omit-xml-declaration=no indent=yes";

(: Keep track of all the namespace being used. :)
declare variable $tei2rdf:namespaces := 
    <namespaceList>
        <item name="cwrc" qname="http://sparql.cwrc.ca/ontologies/cwrc#"/>
        <item name="dcterms" qname="http://purl.org/dc/terms/"/>
        <item name="foaf" qname="http://xmlns.com/foaf/0.1/"/>
        <item name="geo" qname="http://www.w3.org/2003/01/geo/wgs84_pos#"/>
        <item name="lawd" qname="http://lawd.info/ontology/"/>
        <item name="owl" qname="http://www.w3.org/2002/07/owl#"/>
        <item name="periodo" qname="http://n2t.net/ark:/99152/p0v#"/>
        <item name="person" qname="https://www.w3.org/ns/person"/>
        <item name="rdf" qname="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
        <item name="rdfs" qname="http://www.w3.org/2000/01/rdf-schema#"/>
        <item name="schema" qname="http://schema.org/"/>
        <item name="skos" qname="http://www.w3.org/2004/02/skos/core#"/>
        <item name="snap" qname="http://data.snapdrgn.net/ontology/snap#"/>
        <item name="syriaca" qname="http://syriaca.org/schema#"/>
        <item name="time" qname="http://www.w3.org/2006/time#"/>
        <item name="xsd" qname="http://www.w3.org/2001/XMLSchema#"/>
    </namespaceList>
;

(:~
 : Create a triple element with the rdf qname and content
 : @type indicates if element is literal default is rdf:resources
:)
declare function tei2rdf:create-element($element-name as xs:string, $lang as xs:string?, $content as xs:string*, $type as xs:string?){
    if($type='literal') then        
        element { xs:QName($element-name) } {
          (if ($lang) then attribute {xs:QName("xml:lang")} { $lang } else (), normalize-space($content))
        } 
    else if(starts-with($content,'http')) then  
        element { xs:QName($element-name) } {
            (if ($lang) then attribute {xs:QName("xml:lang")} { $lang } else (),
            attribute {xs:QName("rdf:resource")} { normalize-space($content) }
            )
        }
    else
        element { xs:QName($element-name) } {
          (if ($lang) then attribute {xs:QName("xml:lang")} { $lang } else (), normalize-space($content))
        } 
};

(: Resolve namespaces. :)
declare function tei2rdf:expand-namespace($property as xs:string){
    if(starts-with($property,'http')) then $property
    else if($tei2rdf:namespaces/*[@name = substring-before($property,':')]) then 
        concat($tei2rdf:namespaces/*[@name = substring-before($property,':')]/@qname,'/',substring-after($property,':'))
    else ()
};

(:~
 : Modified functx function to translate syriaca.org relationship names attributes to camel case.
 : @param $property as a string. 
:)
declare function tei2rdf:translate-relation-property($property as xs:string?) as xs:string{
    string-join((tokenize($property,'-')[1],
       for $word in tokenize($property,'-')[position() > 1]
       return functx:capitalize-first($word))
      ,'')
};

(: Create lawd:hasAttestation for elements with a source attribute and a matching bibl element. :)
declare function tei2rdf:attestation($rec, $source){
    for $source in tokenize($source,' ')
    return 
         if($rec//tei:bibl[@xml:id = replace($source,'#','')]/tei:ptr) then
                tei2rdf:create-element('lawd:hasAttestation', (), string($rec//tei:bibl[@xml:id = replace($source,'#','')]/tei:ptr/@target), ())
         else ()   
};

(: Create Dates :)
declare function tei2rdf:make-date-triples($date){
    (
       for $d in $date[@calendar='Gregorian'][not(parent::tei:orig)][@when != '']/@when | $date[@calendar='Gregorian'][not(parent::tei:orig)][@notBefore != '']/@notBefore | $date[@calendar='Gregorian'][not(parent::tei:orig)][@from != '']/@from | $date[@calendar='Gregorian'][not(parent::tei:orig)][@notAfter != '']/@notAfter | $date[@calendar='Gregorian'][not(parent::tei:orig)][@to != '']/@to
       let $d := if(starts-with($d,'-')) then substring($d,1,5) else substring($d,1,4) 
       let $d := concat($d,'-01-01T00:00:00.000')
       return 
        element { xs:QName('dcterms:temporal') } {
            if($d castable as xs:dateTime) then 
            (attribute {xs:QName("rdf:datatype")} { "http://www.w3.org/2001/XMLSchema#dateTime" }, xs:dateTime($d))                     
            else ()
        },
        element { xs:QName('time:hasDateTimeDescription') } {
            element { xs:QName('rdf:Description') } {
            (if($date//text()) then  
                tei2rdf:create-element('skos:prefLabel', (), normalize-space(string-join($date/descendant-or-self::text(),' ')), 'literal')
            else (),
            if($date/@when) then
                element { xs:QName('time:year') } {
                    if($date/@when castable as xs:date) then 
                        (attribute {xs:QName("rdf:datatype")} { "http://www.w3.org/2001/XMLSchema#date" }, xs:date($date/@when))
                    else if($date/@when castable as xs:dateTime) then 
                        (attribute {xs:QName("rdf:datatype")} { "http://www.w3.org/2001/XMLSchema#dateTime" }, xs:dateTime($date/@when))                        
                    else if($date/@when castable as xs:gYear) then 
                        (attribute {xs:QName("rdf:datatype")} { "http://www.w3.org/2001/XMLSchema#gYear" }, xs:gYear($date/@when))
                    else if($date/@when castable as xs:gYearMonth) then 
                        (attribute {xs:QName("rdf:datatype")} { "http://www.w3.org/2001/XMLSchema#gYearMonth" }, xs:gYearMonth($date/@when))
                    else string($date/@when)
                }
            else (),    
            if($date/@notBefore or $date/@from) then
                let $date := if($date/@notBefore) then $date/@notBefore else $date/@from
                return
                    element { xs:QName('periodo:earliestYear') } {
                        if($date castable as xs:date) then 
                            (attribute {xs:QName("rdf:datatype")} { "http://www.w3.org/2001/XMLSchema#date" }, xs:date($date))
                        else if($date castable as xs:dateTime) then 
                            (attribute {xs:QName("rdf:datatype")} { "http://www.w3.org/2001/XMLSchema#dateTime" }, xs:dateTime($date))                        
                        else if($date castable as xs:gYear) then 
                            (attribute {xs:QName("rdf:datatype")} { "http://www.w3.org/2001/XMLSchema#gYear" }, xs:gYear($date))
                        else if($date castable as xs:gYearMonth) then 
                            (attribute {xs:QName("rdf:datatype")} { "http://www.w3.org/2001/XMLSchema#gYearMonth" }, xs:gYearMonth($date))
                        else string($date)
                   }                
            else (),    
            if($date/@notAfter or $date/@to) then
                let $date := if($date/@notAfter) then $date/@notAfter else $date/@to
                return
                element { xs:QName('periodo:latestYear') } {
                       if($date castable as xs:date) then 
                            (attribute {xs:QName("rdf:datatype")} { "http://www.w3.org/2001/XMLSchema#date" }, xs:date($date))
                        else if($date castable as xs:dateTime) then 
                            (attribute {xs:QName("rdf:datatype")} { "http://www.w3.org/2001/XMLSchema#dateTime" }, xs:dateTime($date))                        
                        else if($date castable as xs:gYear) then 
                            (attribute {xs:QName("rdf:datatype")} { "http://www.w3.org/2001/XMLSchema#gYear" }, xs:gYear($date))
                        else if($date castable as xs:gYearMonth) then 
                            (attribute {xs:QName("rdf:datatype")} { "http://www.w3.org/2001/XMLSchema#gYearMonth" }, xs:gYearMonth($date))
                        else string($date)
                    }                
            else ()
            )}
         } 
    )         
};

(: Decode record type based on TEI elements:)
declare function tei2rdf:rec-type($rec){
    if($rec/descendant::tei:body/tei:listPerson) then
         'http://lawd.info/ontology/Person'
    else if($rec/descendant::tei:body/tei:listPlace) then
        'http://lawd.info/ontology/Place'
    else if($rec/descendant::tei:body/tei:bibl[@type="lawd:ConceptualWork"]) then
        'http://lawd.info/ontology/conceptualWork'
    else if($rec/descendant::tei:body/tei:biblStruct) then
        'http://purl.org/dc/terms/bibliographicResource'    
    else if($rec/tei:listPerson) then
       'http://syriaca.org/schema#/personFactoid'    
    else if($rec/tei:listEvent) then
        'http://syriaca.org/schema#/eventFactoid'
    else if($rec/tei:listRelation) then
        'http://syriaca.org/schema#/relationFactoid'
    else 'http://schema.org/Thing'
};

(: Decode record label and title based on Syriaca.org headwords if available 'rdfs:label' or dcterms:title:)
declare function tei2rdf:rec-label-and-titles($rec, $element as xs:string?){
    if($rec/descendant::*[contains(@syriaca-tags,'#syriaca-headword')]) then 
        for $headword in $rec/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][node()]
        return tei2rdf:create-element($element, string($headword/@xml:lang), string-join($headword/descendant-or-self::text(),''), 'literal')
    else if($rec/descendant::tei:body/tei:listPlace/tei:place) then 
        for $headword in $rec/descendant::tei:body/tei:listPlace/tei:place/tei:placeName[node()]
        return tei2rdf:create-element($element, string($headword/@xml:lang), string-join($headword/descendant-or-self::text(),''), 'literal')
    else if($rec[self::tei:div/@uri]) then 
        if(tei2rdf:rec-type($rec) = 'http://syriaca.org/schema#/relationFactoid') then
            tei2rdf:create-element($element, (), normalize-space(rel:relationship-sentence($rec/descendant::tei:listRelation/tei:relation)), 'literal')
        else tei2rdf:create-element($element, (),
        normalize-space(string-join((tei2html:tei2html($rec/child::*[not(self::tei:bibl)])),' ')), 'literal')
    else tei2rdf:create-element($element, string($rec/descendant::tei:title[1]/@xml:lang), string-join($rec/descendant::tei:title[1]/text(),''), 'literal')
};

(: Output place and person names and name varients :)
declare function tei2rdf:names($rec){ 
    for $name in $rec/descendant::tei:body/tei:listPlace/tei:place/tei:placeName | $rec/descendant::tei:body/tei:listPerson/tei:person/tei:persName
    return 
        if($name[contains(@syriaca-tags,'#syriaca-headword')]) then 
                element { xs:QName('lawd:hasName') } {
                    element { xs:QName('rdf:Description') } {(
                        tei2rdf:create-element('lawd:primaryForm', string($name/@xml:lang), string-join($name/descendant-or-self::text(),' '), 'literal'),
                        tei2rdf:attestation($rec, $name/@source)   
                    )} 
                } 
        else 
                element { xs:QName('lawd:hasName') } {
                        element { xs:QName('rdf:Description') } {(
                            tei2rdf:create-element('lawd:variantForm', string($name/@xml:lang), string-join($name/descendant-or-self::text(),' '), 'literal'),
                            tei2rdf:attestation($rec, $name/@source)   
                        )} 
                    }
};

declare function tei2rdf:location($rec){
    for $geo in $rec/descendant::tei:location/tei:geo[. != '']
    return
        (tei2rdf:create-element('geo:lat', (), tokenize($geo,' ')[1], 'literal'),
         tei2rdf:create-element('geo:long', (), tokenize($geo,' ')[2], 'literal'))
};
 
(:~ 
 : TEI descriptions
 : @param $rec TEI record. 
 : See if there is an abstract element?
 :)
declare function tei2rdf:desc($rec)  {
    for $desc in $rec/descendant::tei:body/descendant::tei:desc[not(ancestor-or-self::tei:relation)] | $rec/descendant::tei:body/descendant::tei:note
    let $source := $desc/tei:quote/@source
    return 
        if($source != '') then 
            element { xs:QName('dcterms:description') } {
                element { xs:QName('rdf:Description') } {(
                    tei2rdf:create-element('dcterms:description', string($desc/@xml:lang), string-join($desc/descendant-or-self::text(),' '), 'literal'),
                    tei2rdf:attestation($rec, $source)
                )} 
             }
        else tei2rdf:create-element('dcterms:description', (), string-join($desc/descendant-or-self::text(),' '), 'literal')
};

(:~
 : Uses XQuery templates to properly format bibl, extracts just text nodes. 
 : @param $rec
:)
declare function tei2rdf:bibl-citation($rec){
let $citation := bibl2html:citation($rec/ancestor::tei:TEI)
return 
    <dcterms:bibliographicCitation xmlns:dcterms="http://purl.org/dc/terms/">{normalize-space(string-join($citation))}</dcterms:bibliographicCitation>
};

(: Handle TEI relations:)
declare function tei2rdf:relations-with-attestation($rec, $id){
if(contains($id,'/spear/')) then 
    for $rel in $rec/descendant::tei:listRelation/tei:relation
    return 
        if($rel/@mutual) then 
            for $s in tokenize($rel/@mutual,' ')
            return
                element { xs:QName('rdf:Description') } {(
                            attribute {xs:QName("rdf:about")} { $s },
                            for $o in tokenize($rel/@mutual,' ')[. != $s]
                            let $element-name := if($rel/@ref and $rel/@ref != '') then string($rel/@ref) else if($rel/@name and $rel/@name != '') then string($rel/@name) else 'dcterms:relation'
                            let $element-name := if(starts-with($element-name,'dct:')) then replace($element-name,'dct:','dcterms:') else $element-name
                            let $relationshipURI := concat($o,'#',$element-name,'-',$s)
                            return 
                                (tei2rdf:create-element('dcterms:relation', (), $o, ()),
                                tei2rdf:create-element('snap:hasBond', (), $id, ()))
                        )}
        else 
            for $s in tokenize($rel/@active,' ')
            return 
                   element { xs:QName('rdf:Description') } {(
                            attribute {xs:QName("rdf:about")} { $s },
                            for $o in tokenize($rel/@passive,' ')
                            let $element-name := if($rel/@ref and $rel/@ref != '') then string($rel/@ref) else if($rel/@name and $rel/@name != '') then string($rel/@name) else 'dcterms:relation'
                            let $element-name := if(starts-with($element-name,'dct:')) then replace($element-name,'dct:','dcterms:') else $element-name
                            let $relationshipURI := concat($o,'#',$element-name,'-',$s)
                            return 
                                (tei2rdf:create-element('dcterms:relation', (), $o, ()),
                                tei2rdf:create-element('snap:hasBond', (), $id, ()))
                            )}
else ()                        
};

(: Handle TEI relations:)
declare function tei2rdf:relations($rec, $id){
    (
    for $rel in $rec/descendant::tei:listRelation/tei:relation
    let $ids := distinct-values((
                    for $r in tokenize($rel/@active,' ') return $r,
                    for $r in tokenize($rel/@passive,' ') return $r,
                    for $r in tokenize($rel/@mutual,' ') return $r
                    ))
    for $i in $ids 
    return 
        if(contains($id,'/spear/')) then tei2rdf:create-element('dcterms:subject', (), $i, ())
        else tei2rdf:create-element('dcterms:relation', (), $i, ()),
    for $rel in $rec/descendant::tei:listRelation/tei:relation
    return 
        if($rel/@mutual) then 
            for $s in tokenize($rel/@mutual,' ')
            for $o in tokenize($rel/@mutual,' ')[. != $s]
            let $element-name := if($rel/@ref and $rel/@ref != '') then string($rel/@ref) else if($rel/@name and $rel/@name != '') then string($rel/@name) else 'dcterms:relation'
            let $element-name := if(starts-with($element-name,'dct:')) then replace($element-name,'dct:','dcterms:') else $element-name
            let $relationshipURI := concat($o,'#',$element-name,'-',$s)
            return if(contains($id,'/spear/')) then 
                    (tei2rdf:create-element('rdf:type', (), tei2rdf:expand-namespace($element-name), ()),
                    tei2rdf:create-element('snap:bondWith', (), $o, ()))
                   else tei2rdf:create-element($element-name, (), $o, ()) 
        else 
            for $s in tokenize($rel/@active,' ')
            for $o in tokenize($rel/@passive,' ')
            let $element-name := if($rel/@ref and $rel/@ref != '') then string($rel/@ref) else if($rel/@name and $rel/@name != '') then string($rel/@name) else 'dcterms:relation'
            let $element-name := if(starts-with($element-name,'dct:')) then replace($element-name,'dct:','dcterms:') else $element-name
            let $relationshipURI := concat($o,'#',$element-name,'-',$s)
            return 
                if(contains($id,'/spear/')) then 
                    (tei2rdf:create-element('rdf:type', (), tei2rdf:expand-namespace($element-name), ()),
                     tei2rdf:create-element('snap:bondWith', (), $o, ()))
                else tei2rdf:create-element($element-name, (), $o, ())
   )
};

(: Internal references :)
declare function tei2rdf:internal-refs($rec){
    let $links := distinct-values($rec//@ref[starts-with(.,'http://')][not(ancestor::tei:teiHeader)])
    for $i in $links[. != '']
    return tei2rdf:create-element('dcterms:relation', (), $i, ()) 
};

(: Special handling for SPEAR :)
declare function tei2rdf:spear-related-triples($rec, $id){
    if(contains($id,'/spear/')) then
        (: Person Factoids :)
        if($rec/tei:listPerson) then  
            element { xs:QName('rdf:Description') } {(
                attribute {xs:QName("rdf:about")} { $rec/tei:listPerson/child::*/tei:persName/@ref },
                if($rec/tei:listPerson/tei:personGrp) then 
                    tei2rdf:create-element('rdf:type', (), 'http://xmlns.com/foaf/0.1/group', ())
                else (),
                if($rec/tei:listPerson/child::*/tei:birth/tei:date) then 
                    tei2rdf:create-element('schema:birthDate', (), string-join($rec/tei:listPerson/child::*/tei:birth/tei:date/@when | $rec/tei:listPerson/child::*/tei:birth/tei:date/@notAfter | $rec/tei:listPerson/child::*/tei:birth/tei:date/@notBefore,' '), 'literal')
                else(),
                if($rec/tei:listPerson/child::*/tei:birth/tei:placeName[@ref]) then 
                    for $r in tokenize($rec/tei:listPerson/child::*/tei:birth/tei:placeName/@ref,' ')
                    return tei2rdf:create-element('schema:birthPlace', (), $r, ())
                else(),
                if($rec/tei:listPerson/child::*/tei:nationality/tei:placeName[@ref]) then 
                    for $r in tokenize($rec/tei:listPerson/child::*/tei:nationality/tei:placeName/@ref,' ')
                    return tei2rdf:create-element('person:citizenship', (), $r, ())
                else(),
                if($rec/tei:listPerson/child::*/tei:death/tei:date) then 
                    tei2rdf:create-element('person:citizenship', (), string-join($rec/tei:listPerson/child::*/tei:death/tei:date/@when | $rec/tei:listPerson/child::*/tei:death/tei:date/@notAfter | $rec/tei:listPerson/child::*/tei:death/tei:date/@notBefore,' '), 'literal')
                else(),
                if($rec/tei:listPerson/child::*/tei:death/tei:placeName[@ref]) then 
                    for $r in tokenize($rec/tei:listPerson/child::*/tei:death/tei:placeName/@ref,' ')
                    return tei2rdf:create-element('schema:deathPlace', (), $r, ())
                else(),
                if($rec/tei:listPerson/child::*/tei:education[@ref]) then 
                    for $r in tokenize($rec/tei:listPerson/child::*/tei:education/@ref,' ')
                    return tei2rdf:create-element('syriaca:studiedSubject', (), $r, ())
                else(),
                if($rec/tei:listPerson/child::*/tei:trait[@type='ethnicLabel'][@ref != '']) then 
                    for $r in tokenize($rec/tei:listPerson/child::*/tei:trait[@type='ethnicLabel']/@ref,' ')
                    return tei2rdf:create-element('cwrc:hasEthnicity', (), $r, ())
                else(),
                if($rec/tei:listPerson/child::*/tei:trait[@type='gender'][@ref]) then 
                    for $r in tokenize($rec/tei:listPerson/child::*/tei:trait[@type='gender']/@ref,' ')
                    return tei2rdf:create-element('schema:gender', (), $r, ())
                else(),
                if($rec/descendant::tei:person/tei:langKnowledge/tei:langKnown[@ref]) then 
                    for $r in tokenize($rec/descendant::tei:person/tei:langKnowledge/tei:langKnown/@ref,' ')
                    return tei2rdf:create-element('cwrc:hasLinguisticAbility', (), $r, ())
                else(),
                if($rec/tei:listPerson/child::*/tei:state[@type='mental'][@ref]) then
                    for $r in tokenize($rec/tei:listPerson/child::*/tei:state[@type='mental']/@ref,' ')
                    return tei2rdf:create-element('syriaca:hasMentalState', (), $r, ())
                else(),
                if($rec/tei:listPerson/child::*/tei:occupation[@ref]) then 
                    for $r in tokenize($rec/tei:listPerson/child::*/tei:occupation/@ref,' ')
                    return tei2rdf:create-element('snap:occupation', (), $r, ())
                else(),
                if($rec/tei:listPerson/child::*/tei:trait[@type='physical'][@ref]) then 
                    for $r in tokenize($rec/tei:listPerson/child::*/tei:trait[@type='physical']/@ref,' ')
                    return tei2rdf:create-element('syriaca:hasPhysicalTrait', (), $r, ())
                else(),
                if($rec/tei:listPerson/child::*/tei:residence/tei:placeName[@ref]) then 
                    for $r in tokenize($rec/tei:listPerson/child::*/tei:residence/tei:placeName/@ref,' ')
                    return tei2rdf:create-element('person:residency', (), $r, ())
                else(),
                if($rec/tei:listPerson/child::*/tei:state[@type='sanctity'][@ref]) then
                    for $r in tokenize($rec/tei:listPerson/child::*/tei:state[@type='sanctity']/@ref,' ')
                    return tei2rdf:create-element('syriaca:sanctity', (), $r, ())
                else(),
                if($rec/tei:listPerson/child::*/tei:sex) then 
                    tei2rdf:create-element('syriaca:sex', (), string($rec/tei:listPerson/child::*/tei:sex/@value), 'literal')
                else(),
                if($rec/tei:listPerson/child::*/tei:socecStatus[@ref]) then 
                    for $r in tokenize($rec/tei:listPerson/child::*/tei:socecStatus/@ref,' ')
                    return tei2rdf:create-element('syriaca:hasSocialRank', (), $r, ())
                else(),
                if($rec/tei:listPerson/child::*/tei:trait[@type='physical'][@ref]) then 
                    for $r in tokenize($rec/tei:listPerson/child::*/tei:trait[@type='physical']/@ref,' ')
                    return tei2rdf:create-element('syriaca:hasPhysicalTrait', (), $r, ())                    
                else(),
                if($rec/tei:listPerson/child::*/tei:persName[descendant-or-self::text()]) then 
                    for $name in $rec/tei:listPerson/child::*/tei:persName[descendant-or-self::text()]
                    return tei2rdf:create-element('foaf:name', (), string-join($name//text(),' '), 'literal')
                else (),
                tei2rdf:create-element('lawd:hasAttestation', (), $id, ())
             )}
        else if($rec/descendant::tei:listRelation) then 
            tei2rdf:relations-with-attestation($rec,$id)
        else ()
    else ()
};

declare function tei2rdf:spear($rec, $id){
    let $header := $rec/ancestor::tei:TEI
    return 
    (element { xs:QName('skos:Concept') } {(
        attribute {xs:QName("rdf:about")} { $id },         
        tei2rdf:create-element('rdf:type', (), tei2rdf:rec-type($rec), ()),
        tei2rdf:rec-label-and-titles($rec, 'rdfs:label'),
        if($rec/tei:listEvent) then ( 
                (: Subjects:)
                let $subjects := tokenize($rec/descendant::tei:event/tei:ptr/@target,' ')
                for $subject in $subjects
                return tei2rdf:create-element('dcterms:subject', (), $subject, ()),
                (: Places :)
                let $places := $rec/descendant::tei:event/tei:desc/descendant::tei:placeName/@ref
                for $place in $places
                return tei2rdf:create-element('schema:location', (), $place, ())
                )
        else (),
        tei2rdf:names($rec),
        tei2rdf:desc($rec),
        for $temporal in $rec/descendant::tei:state[@type="existence"]
        return tei2rdf:make-date-triples($temporal),        
        for $date in $rec/descendant::tei:event/descendant::tei:date
        return tei2rdf:make-date-triples($date),
        let $links := distinct-values($rec//@ref[starts-with(.,'http://')][not(ancestor::tei:teiHeader)])
        for $i in $links[. != '']
        return tei2rdf:create-element('dcterms:subject', (), $i, ()), 
        tei2rdf:relations($rec, $id),
        for $id in $rec/descendant::tei:body/descendant::tei:idno[@type='URI'][text() != $id and text() != '']/text() 
        return tei2rdf:create-element('skos:closeMatch', (), $id, ()),
        for $s in $header/descendant::tei:seriesStmt
        return 
            if($s/tei:idno[@type="URI"]) then tei2rdf:create-element('dcterms:isPartOf', (), $s/tei:idno[@type="URI"][1], ())            
            else tei2rdf:create-element('dcterms:isPartOf', (), $s/tei:title[1], 'literal'),                    
        tei2rdf:bibl-citation($rec),
        for $bibl in $rec//tei:bibl[not(ancestor::tei:teiHeader)]/tei:ptr/@target[. != '']
        return  
            if(starts-with($bibl, "urn:cts:")) then tei2rdf:create-element('lawd:hasAttestation', (), $bibl, ())
            else tei2rdf:create-element('lawd:hasCitation', (), $bibl, ()),
        for $bibl in $rec//tei:teiHeader/descendant::tei:sourceDesc/descendant::*/@ref[contains(.,'/work/')]
        return tei2rdf:create-element('lawd:hasAttestation', (), $bibl, ()),
        tei2rdf:create-element('dcterms:isPartOf', (), replace($rec/ancestor::tei:TEI/descendant::tei:publicationStmt/tei:idno[@type="URI"][1],'/tei',''), ()),
        let $work-uris := distinct-values($header/descendant::tei:sourceDesc/descendant::*/@ref[contains(.,'/work/')] | $header/descendant::tei:sourceDesc/descendant::*/@target[contains(.,'/work/')]) 
        for $work-uri in $work-uris
        return  tei2rdf:create-element('dcterms:source', (), $work-uri, ()),        
        tei2rdf:create-element('dcterms:isPartOf', (), 'http://syriaca.org/spear', ()), 
        (: Other formats:)
        tei2rdf:create-element('dcterms:hasFormat', (), concat($id,'/html'), ()),
        tei2rdf:create-element('dcterms:hasFormat', (), concat($id,'/tei'), ()),
        tei2rdf:create-element('dcterms:hasFormat', (), concat($id,'/ttl'), ()),
        tei2rdf:create-element('dcterms:hasFormat', (), concat($id,'/rdf'), ()),
        tei2rdf:create-element('foaf:primaryTopicOf', (), concat($id,'/html'), ()),
        tei2rdf:create-element('foaf:primaryTopicOf', (), concat($id,'/tei'), ()),
        tei2rdf:create-element('foaf:primaryTopicOf', (), concat($id,'/ttl'), ()),
        tei2rdf:create-element('foaf:primaryTopicOf', (), concat($id,'/rdf'), ())
        )},
        tei2rdf:spear-related-triples($rec, $id) 
        )    
};

(:~
 : Pull together all triples for a single record
:)
declare function tei2rdf:make-triple-set($rec){
let $rec := if($rec/tei:div[@uri[starts-with(.,$config:base-uri)]]) then $rec/tei:div else $rec
let $id := if($rec/descendant::tei:idno[starts-with(.,$config:base-uri)]) then replace($rec/descendant::tei:idno[starts-with(.,$config:base-uri)][1],'/tei','')
           else if($rec/@uri[starts-with(.,$config:base-uri)]) then $rec/@uri[starts-with(.,$config:base-uri)]
           else $rec/descendant::tei:idno[1]
let $resource-class := if($rec/descendant::tei:body/tei:biblStruct) then 'rdfs:Resource'    
                       else 'skos:Concept'            
let $header := $rec/ancestor::tei:TEI
return  
    if(contains($id,'/spear/')) then tei2rdf:spear($rec, $id)
    else 
    (element { xs:QName($resource-class) } {(
                attribute {xs:QName("rdf:about")} { $id }, 
                tei2rdf:create-element('rdf:type', (), tei2rdf:rec-type($rec), ()),
                tei2rdf:rec-label-and-titles($rec, 'rdfs:label'),
                if($rec/descendant::tei:body/tei:bibl[@type="lawd:ConceptualWork"] or $rec/descendant::tei:body/tei:biblStruct) then
                   (for $author in $rec/descendant::tei:body/tei:bibl[@type="lawd:ConceptualWork"]/tei:author | $rec/descendant::tei:body/tei:biblStruct/descendant::tei:author
                    return  
                        if($author/@ref) then
                            tei2rdf:create-element('dcterms:contributor', (), $author/@ref, ())
                        else tei2rdf:create-element('dcterms:contributor', (), string-join($author/descendant-or-self::text(),''), 'literal'),
                    for $editor in $rec/descendant::tei:body/tei:bibl[@type="lawd:ConceptualWork"]/tei:editor | $rec/descendant::tei:body/tei:biblStruct/descendant::tei:editor
                    return 
                        if($editor/@ref) then
                            tei2rdf:create-element('dcterms:contributor', (), $editor/@ref, ())
                        else tei2rdf:create-element('dcterms:contributor', (), string-join($editor/descendant-or-self::text(),''), 'literal')
                    )
                else (),
                tei2rdf:names($rec),
                if(contains($id,'/spear/')) then ()
                else tei2rdf:location($rec),
                tei2rdf:desc($rec),
                for $temporal in $rec/descendant::tei:state[@type="existence"]
                return tei2rdf:make-date-triples($temporal),        
                for $date in $rec/descendant::tei:event/descendant::tei:date
                return tei2rdf:make-date-triples($date),
                for $otherid in $rec/descendant::tei:body/descendant::tei:idno[@type='URI'][text() != $id and text() != '']/text() 
                return 
                    tei2rdf:create-element('skos:closeMatch', (), $otherid, ()),
                for $rdfID in $rec/descendant::tei:body/descendant::tei:idno[not(@type='URI')][text() != $id and text() != '']/text() 
                let $expand := tei2rdf:expand-namespace($rdfID)
                return 
                    if($expand != '') then
                        tei2rdf:create-element('owl:sameAs', (), $expand, ())
                    else (),
                tei2rdf:internal-refs($rec),
                tei2rdf:relations($rec, $id),
                for $s in $header/descendant::tei:seriesStmt
                return 
                    if($s/tei:idno[@type="URI"]) then
                        tei2rdf:create-element('dcterms:isPartOf', (), $s/tei:idno[@type="URI"][1], ())            
                    else tei2rdf:create-element('dcterms:isPartOf', (), $s/tei:title[1], 'literal'),                    
                if(contains($id,'/spear/')) then tei2rdf:bibl-citation($rec) else (),
                for $bibl in $rec//tei:bibl[not(ancestor::tei:teiHeader)]/tei:ptr/@target[. != '']
                return  
                    if(starts-with($bibl, "urn:cts:")) then 
                        tei2rdf:create-element('lawd:hasAttestation', (), $bibl, ())
                    else tei2rdf:create-element('lawd:hasCitation', (), $bibl, ()),
                (: Other formats:)
                tei2rdf:create-element('dcterms:hasFormat', (), concat($id,'/html'), ()),
                tei2rdf:create-element('dcterms:hasFormat', (), concat($id,'/tei'), ()),
                tei2rdf:create-element('dcterms:hasFormat', (), concat($id,'/ttl'), ()),
                tei2rdf:create-element('dcterms:hasFormat', (), concat($id,'/rdf'), ()),
                tei2rdf:create-element('foaf:primaryTopicOf', (), concat($id,'/html'), ()),
                tei2rdf:create-element('foaf:primaryTopicOf', (), concat($id,'/tei'), ()),
                tei2rdf:create-element('foaf:primaryTopicOf', (), concat($id,'/ttl'), ()),
                tei2rdf:create-element('foaf:primaryTopicOf', (), concat($id,'/rdf'), ())
        )},
        if(contains($id,'/spear/')) then tei2rdf:spear-related-triples($rec, $id) 
        else 
            (tei2rdf:relations-with-attestation($rec,$id),
            <rdfs:Resource rdf:about="{concat($id,'/html')}" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
                {(
                tei2rdf:rec-label-and-titles($rec, 'dcterms:title'),
                tei2rdf:create-element('dcterms:subject', (), $id, ()),
                for $bibl in $rec//tei:bibl[not(ancestor::tei:teiHeader)]/tei:ptr/@target[. != '']
                return tei2rdf:create-element('dcterms:source', (), $bibl, ()),
                tei2rdf:create-element('dcterms:format', (), "text/html", "literal"),
                tei2rdf:bibl-citation($rec)
                )}
            </rdfs:Resource>,
            <rdfs:Resource rdf:about="{concat($id,'/tei')}" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
                {(
                tei2rdf:rec-label-and-titles($rec, 'dcterms:title'),
                tei2rdf:create-element('dcterms:subject', (), $id, ()),
                for $bibl in $rec//tei:bibl[not(ancestor::tei:teiHeader)]/tei:ptr/@target[. != '']
                return tei2rdf:create-element('dcterms:source', (), $bibl, ()),
                tei2rdf:create-element('dcterms:format', (), "text/xml", "literal"),
                tei2rdf:bibl-citation($rec)
                )}
            </rdfs:Resource>,
            <rdfs:Resource rdf:about="{concat($id,'/ttl')}" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
                {(
                tei2rdf:rec-label-and-titles($rec, 'dcterms:title'),
                tei2rdf:create-element('dcterms:subject', (), $id, ()),
                for $bibl in $rec//tei:bibl[not(ancestor::tei:teiHeader)]/tei:ptr/@target[. != '']
                return tei2rdf:create-element('dcterms:source', (), $bibl, ()),
                tei2rdf:create-element('dcterms:format', (), "text/turtle", "literal"),
                tei2rdf:bibl-citation($rec)
                )}
            </rdfs:Resource>,
            <rdfs:Resource rdf:about="{concat($id,'/rdf')}" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
                {(
                tei2rdf:rec-label-and-titles($rec, 'dcterms:title'),
                tei2rdf:create-element('dcterms:subject', (), $id, ()),
                for $bibl in $rec//tei:bibl[not(ancestor::tei:teiHeader)]/tei:ptr/@target[. != '']
                return tei2rdf:create-element('dcterms:source', (), $bibl, ()),
                tei2rdf:create-element('dcterms:format', (), "text/xml", "literal"),
                tei2rdf:bibl-citation($rec)
                )}
            </rdfs:Resource>)
        )
};        
    
(:~ 
 : Build RDF output for records. 
 <namespace namspace="cwrc" qname="http://sparql.cwrc.ca/ontologies/cwrc#"/>
:)
declare function tei2rdf:rdf-output($recs){
element rdf:RDF {namespace {""} {"http://www.w3.org/1999/02/22-rdf-syntax-ns#"}, 
    namespace cwrc {"http://sparql.cwrc.ca/ontologies/cwrc#"},
    namespace dcterms {"http://purl.org/dc/terms/"},
    namespace foaf {"http://xmlns.com/foaf/0.1/"},
    namespace geo {"http://www.w3.org/2003/01/geo/wgs84_pos#"},
    namespace lawd {"http://lawd.info/ontology/"},   
    namespace owl  {"http://www.w3.org/2002/07/owl#"},
    namespace periodo  {"http://n2t.net/ark:/99152/p0v#"},
    namespace person {"https://www.w3.org/ns/person"},
    namespace rdfs {"http://www.w3.org/2000/01/rdf-schema#"},
    namespace schema {"http://schema.org/"},
    namespace skos {"http://www.w3.org/2004/02/skos/core#"},
    namespace snap {"http://data.snapdrgn.net/ontology/snap#"},
    namespace syriaca {"http://syriaca.org/schema#"},
    namespace time {"http://www.w3.org/2006/time#"},
    namespace xsd {"http://www.w3.org/2001/XMLSchema#"}
,
            for $r in $recs
            return tei2rdf:make-triple-set($r) 
    }
};
