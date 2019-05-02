xquery version "3.1";

(: Syriaca.org restxq file. :)
module namespace api="http://syriaca.org/srophe/api";

(: Syriaca.org modules :)
import module namespace data="http://syriaca.org/srophe/data" at "lib/data.xqm";
import module namespace cntneg="http://syriaca.org/srophe/cntneg" at "content-negotiation/content-negotiation.xqm"; 

(: Namespaces :)
declare namespace json="http://www.json.org";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


(: Establish API endpoints :)

(:
 : Get records with coordinates
 : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html
 : @param $collection filter on collection - not implmented yet
 : Serialized as geoJSON
:)
declare
    %rest:GET
    %rest:path("/srophe/api/geo/json")
    %rest:query-param("type", "{$type}", "")
    %rest:query-param("collection", "{$collection}", "")
function api:coordinates($type as xs:string*, $collection as xs:string*) {
  cntneg:content-negotiation-restxq(api:get-records-with-coordinates($type, $collection),'geojson',())
};

(:
 : Get records with coordinates
 : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html
 : @param $collection filter on collection - not implmented yet
 : Serialized as KML
:)
declare
    %rest:GET
    %rest:path("/srophe/api/geo/kml")
    %rest:query-param("type", "{$type}", "")
    %rest:query-param("collection", "{$collection}", "")
function api:kml-coordinates($type as xs:string*, $collection as xs:string*) {
    cntneg:content-negotiation-restxq(api:get-records-with-coordinates($type, $collection),'kml',())
};

(:~
 : Search API, returns JSON
 : @note: This function is important! Used by eKtobe
 : @param $element element to be searched. Accepts: persName, placeName, title, author, note, event, desc, location, idno
 : @param $collection accepts any value specified in the repo-config.xml
 : @param $lang accepts any valid ISO lang attribute used in the @xml:lang attrubute in the TEI
 : @param $author accepts string value. May only be used when $element = 'title'    
:)
declare
    %rest:GET
    %rest:path("/srophe/api/search/{$element}")
    %rest:query-param("q", "{$q}", "")
    %rest:query-param("collection", "{$collection}", "")
    %rest:query-param("lang", "{$lang}", "")
    %rest:query-param("author", "{$author}", "")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")
function api:search-element($element as xs:string?, $q as xs:string*, $collection as xs:string*, $lang as xs:string*, $author as xs:string*){
    let $options :=                  
        "<options>
            <default-operator>and</default-operator>
            <phrase-slop>1</phrase-slop>
            <leading-wildcard>yes</leading-wildcard>
            <filter-rewrite>yes</filter-rewrite>
        </options>"                          
    let $lang := if($lang != '') then concat("[@xml:lang = '",$lang,"']") 
                 else ()
    let $author := if($author != '') then 
                     concat("[ft:query(.//tei:author,'",$author,"',",$options,")]")
                 else ()                
    let $eval-string := concat(data:build-collection-path($collection),"[ft:query(.//tei:",$element,",'",$q,"*',",$options,")]",$lang,$author)
    let $hits := util:eval($eval-string)
    return 
        if(count($hits) gt 0) then 
            <json:value>
                <id>0</id>
                <action>{$q}</action>
                <info>hits: {count($hits)}</info>
                <start>1</start>
                <results>
                    {
                     for $hit in $hits
                     let $id := replace($hit/descendant::tei:publicationStmt/tei:idno[@type='URI'][1],'/tei','')
                     let $dates := 
                         if($element = 'persName') then 
                             string-join($hit/descendant::tei:body/descendant::tei:birth/descendant-or-self::text() 
                             | $hit/descendant::tei:body/descendant::tei:death/descendant-or-self::text() | 
                             $hit/descendant::tei:body/descendant::tei:floruit/descendant-or-self::text(),' ')
                         else ()
                     let $element-text := util:eval(concat("$hit//tei:",$element,"[ft:query(.,'",$q,"*',",$options,")]"))                   
                     return
                             <json:value json:array="true">
                                 <id>{$id}</id>
                                 {for $e in $element-text 
                                  return 
                                     element {xs:QName($element)} { normalize-space(string-join($e//text(),' ')) }}
                                 {if($dates != '') then <dates>{normalize-space($dates)}</dates> else ()}
                             </json:value>
                     }
                </results>
            </json:value>
        else   
            <json:value>
                <json:value json:array="true">
                    <id>0</id>
                    <action>{$q}</action>
                    <info>No results</info>
                    <start>1</start>
                </json:value>
            </json:value>
};

(:
 : Data dump for all records
 : @param $collection filter on collection - see repo-config.xml for collection names
 : @param $format -supported formats rdf/ttl/xml/html/json
 : @param $start
 : @param $limit
 : @param $content-type - serializtion based on format or Content-Type header. 
:)
declare
    %rest:GET
    %rest:path("/srophe/api/data")
    %rest:query-param("collection", "{$collection}", "")
    %rest:query-param("format", "{$format}", "")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("limit", "{$limit}", 50)
    %rest:header-param("Content-Type", "{$content-type}")
function api:data-dump(
    $type as xs:string*, 
    $collection as xs:string*, 
    $format as xs:string*, 
    $start as xs:integer*,
    $limit as xs:integer*,
    $content-type as item()*) {
    let $data := util:eval(data:build-collection-path($collection))
    let $request-format := if($format != '') then $format  else if($content-type) then $content-type else 'xml'
    return cntneg:content-negotiation-restxq(subsequence($data, $start, $limit), $request-format,())
};

(:
 : Data dump for any results set may be posted to this endpoint for serialization
 : @param $content-type - serializtion based on format or Content-Type header. 
:)
declare
    %rest:POST('{$data}')
    %rest:path('/srophe/api/data/serialize')
    %rest:header-param("Content-Type", "{$content-type}")
function api:data-serialize($data as item()*, $content-type as item()*) {
   cntneg:content-negotiation-restxq($data, $content-type,())
};

(: API helper functions :)
(:~
 : Get all records with coordinates
 : @param $type 
 : @param $collection
 :)
declare function api:get-records-with-coordinates($type as xs:string*, $collection as xs:string*){
    let $path := 
        if($type) then
            if(contains($type,',')) then 
                let $types := 
                    if(contains($type,',')) then  string-join(for $type-string in tokenize($type,',') return concat('"',$type-string,'"'),',')
                    else $type
                return concat(data:build-collection-path($collection),"[descendant::tei:place[@type = (",$types,")]//tei:geo]") 
            else concat(data:build-collection-path($collection),'[descendant::tei:place[@type=$type]]')
        else concat(data:build-collection-path($collection),'[descendant::tei:geo]')         
     return util:eval($path)   
};