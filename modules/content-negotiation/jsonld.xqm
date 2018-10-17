xquery version "3.0";

module namespace jsonld="http://syriaca.org/srophe/jsonld";
(:~
 : Module returns JSON-LD
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2018-10-10
:)

import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "tei2html.xqm";
import module namespace tei2rdf="http://syriaca.org/srophe/tei2rdf" at "tei2rdf.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql="http://www.w3.org/2005/sparql-results#";
declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare function jsonld:sparql-JSON($results){
    for $node in $results
    return 
        typeswitch($node)
            case text() return $node
            case comment() return ()
            case element(sparql:variable) return element vars {string($node/@*:name)}
            case element(sparql:result) return element bindings {jsonld:sparql-JSON($node/node())}
            case element(sparql:binding) return element {string($node/@*:name)} {
                for $n in $node/node()
                return 
                    (element type {local-name($n)},
                     element value {normalize-space($n/text())},
                     if($n/@xml:lang) then 
                        element {xs:QName('xml:lang')} {string($n/@xml:lang)}
                     else()
                    )
            }
            case element() return jsonld:passthru($node)
            default return jsonld:sparql-JSON($node/node())
};

declare function jsonld:passthru($node as node()*) as item()* { 
    element {local-name($node)} {($node/@*, jsonld:sparql-JSON($node/node()))}
};

declare function jsonld:rdf-JSON($node as node()*){
<root>
    <id>{string($node/*:Concept/@*:about)}</id>
</root>
};

declare function jsonld:generic($node as node()*) {
    (
    <id>{replace($node/descendant::tei:idno[@type='URI'][1],'/tei','')}</id>,
    if($node/descendant::*[contains(@syriaca-tags,'#syriaca-headword')]) then 
        for $headword in $node/descendant::*[contains(@syriaca-tags,'#syriaca-headword')]
        return
         <name>
            {
            if($headword/@xml:lang != '') then
                element { string($headword/@xml:lang) } { normalize-space(string-join($headword/descendant-or-self::text(),'')) }
            else  normalize-space(string-join($headword/descendant-or-self::text(),''))
            }
            </name>
    else if($node/descendant::tei:body/tei:listPlace/tei:place) then 
        for $headword in $node/descendant::tei:body/tei:listPlace/tei:place/tei:placeName[1]
        return 
            <name>
            {
            if($headword/@xml:lang != '') then
                element { string($headword/@xml:lang) } { normalize-space(string-join($headword/descendant-or-self::text(),'')) }
            else normalize-space(string-join($headword/descendant-or-self::text(),''))
            }
            </name>
    else if($node[self::tei:div/@uri]) then 
         <name>{normalize-space(string-join((tei2html:tei2html($node/child::*[not(self::tei:bibl)])),' '))}</name>        
    else <name>{string-join($node/descendant::tei:title[1]/text(),'')}</name>,
    for $desc in $node/descendant::tei:body/descendant::tei:desc[not(ancestor-or-self::tei:relation)] | $node/descendant::tei:body/descendant::tei:note
    let $source := $desc/tei:quote/@source
    return <description>
            {
                if($desc/@xml:lang != '') then
                    element { string($desc/@xml:lang) } { normalize-space(string-join($desc//text(),'')) }
                else normalize-space(string-join($desc//text(),''))
            }</description>,
    if($node/descendant::tei:body/descendant::tei:idno[@type='URI']) then
        for $r in $node/descendant::tei:body/descendant::tei:idno[@type='URI']
        return 
            <sameAs>{normalize-space($r/text())}</sameAs>
    else () 
    )
};

declare function jsonld:record($node as node()*){
    <root>{
        if($node/descendant::tei:body/tei:listPerson) then
            (<context>http://schema.org/</context>,
            <type>Person</type>,
            jsonld:generic($node)) 
        else if($node/descendant::tei:body/tei:listPlace) then
            (jsonld:generic($node),
            for $geo in $node/descendant::tei:geo
            return <geo>
                    <latitude>{tokenize($geo,' ')[1]}</latitude>
                    <longitude>{tokenize($geo,' ')[2]}</longitude>
                </geo>)
        else if($node/descendant::tei:body/tei:bibl[@type="lawd:ConceptualWork"]) then
            jsonld:generic($node) 
        else if($node/descendant::tei:body/tei:biblStruct) then
            jsonld:generic($node)         
        else if($node/tei:listEvent) then
            jsonld:generic($node) 
        else if($node/tei:listRelation) then
            jsonld:generic($node) 
        else jsonld:generic($node)
    }</root>
};

declare function jsonld:collection($nodes as node()*){
    <root>{
        for $node in $nodes
        return 
        <record>{jsonld:record($node)}</record> 
    }</root>
};

declare function jsonld:jsonld($node as node()*){
    replace((serialize(jsonld:rdf-JSON(tei2rdf:rdf-output($node)), 
        <output:serialization-parameters>
            <output:method>json</output:method>
        </output:serialization-parameters>)
        ),'"id"','"@id"')
   
    (:(serialize(jsonld:sparql-JSON($node), 
        <output:serialization-parameters>
            <output:method>json</output:method>
        </output:serialization-parameters>)(:,
        response:set-header("Content-Type", "application/json"):)
        )
        :)
};