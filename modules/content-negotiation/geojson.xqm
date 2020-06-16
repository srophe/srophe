xquery version "3.0";

module namespace geojson="http://srophe.org/srophe/geojson";
(:~
 : Module returns coordinates as geoJSON
 : Formats include geoJSON 
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2014-06-25
:)

import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace srophe="https://srophe.app";

(:~
 : Serialize XML as JSON
:)
declare function geojson:geojson($nodes as node()*){
    serialize(geojson:json-wrapper($nodes), 
        <output:serialization-parameters>
            <output:method>json</output:method>
        </output:serialization-parameters>)
    (: xqjson:serialize-json(geojson:json-wrapper($nodes)) :)
};

(:~
 : Build root element for geojson output
:)
declare function geojson:json-wrapper($nodes as node()*) as element()*{
    <root>
        <type>FeatureCollection</type>
        <features>
            {
            let $nodes := $nodes[descendant-or-self::tei:geo]
            let $count := count($nodes)
            for $n in $nodes
            return geojson:geojson-object($n, $count)}
        </features>
    </root>
};

(:~
 : Build geoJSON object for each node with coords
 : Sample data passed to geojson-object
  <place xmlns="http://www.tei-c.org/ns/1.0">
    <idno></idno>
    <title></title>
    <desc></desc>
    <location></location>  
  </place>
:)
declare function geojson:geojson-object($node as node()*, $count as xs:integer?) as element()*{
let $id := if($node/descendant::tei:idno[@type='URI']) then $node/descendant::tei:idno[@type='URI'][1]
           else $node/descendant::tei:idno[1]
let $title := if($node/descendant::*[@srophe:tags="#headword"]) then $node/descendant::*[@srophe:tags="#headword"][1] 
              else if($node/descendant::*[@syriaca-tags="#syriaca-headword"]) then $node/descendant::*[@syriaca-tags="#syriaca-headword"][1] 
              else $node/descendant::tei:title[1]
let $desc := if($node/descendant::tei:desc[1]/tei:quote) then 
                concat('"',$node/descendant::tei:desc[1]/tei:quote,'"')
             else $node/descendant::tei:desc[1]
let $type := if($node/descendant::tei:relationType != '') then 
                string($node/descendant::tei:relationType)
              else if($node/descendant::tei:place/@type) then 
                string($node/descendant::tei:place/@type)
              else ()   
let $coords := if($node/descendant::tei:location[@subtype = 'preferred']) then $node/descendant::tei:location[@subtype = 'preferred']/tei:geo else $node/descendant::tei:geo[1]
return 
    <json:value>
        {(if(count($count) = 1) then attribute {xs:QName("json:array")} {'true'} else())}
        <type>Feature</type>
        <geometry>
            <type>Point</type>
            <coordinates json:literal="true">{tokenize($coords,' ')[2]}</coordinates>
            <coordinates json:literal="true">{tokenize($coords,' ')[1]}</coordinates>
        </geometry>
        <properties>
            <uri>{replace(replace($id,$config:base-uri,$config:nav-base),'/tei','')}</uri>
            <name>{string-join($title,' ')}</name>
            {if($desc != '') then
                <desc>{string-join($desc,' ')}</desc> 
            else(),
            if($type != '') then
                <type>{$type}</type> 
            else ()
            }
        </properties>
    </json:value>
};