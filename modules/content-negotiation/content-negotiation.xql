xquery version "3.0";

(:~
 : Passes content to content negotiation module, if not using restxq
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2018-04-12
:)

import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";

(: Content serialization modules. :)
import module namespace cntneg="http://srophe.org/srophe/cntneg" at "content-negotiation.xqm";
import module namespace tei2html="http://srophe.org/srophe/tei2html" at "tei2html.xqm";

(: Data processing module. :)
import module namespace data="http://srophe.org/srophe/data" at "../lib/data.xqm";

(: Import KWIC module:)
import module namespace kwic="http://exist-db.org/xquery/kwic";

(: Namespaces :)
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http="http://expath.org/ns/http-client";
declare namespace srophe="https://srophe.app";

(:~
 : Search API
 : @note: This function is important! Used by eKtobe
 : @param $element element to be searched. Accepts: persName, placeName, title, author, note, event, desc, location, idno
 : @param $collection accepts any value specified in the repo-config.xml
 : @param $lang accepts any valid ISO lang attribute used in the @xml:lang attrubute in the TEI
 : @param $author accepts string value. May only be used when $element = 'title'    
:)
declare function local:search-element($element as xs:string?, $q as xs:string*, $collection as xs:string*){                     
    let $element := if($element != '') then 
                     $element
                 else 'body' 
    let $hits := data:apiSearch($collection, $element, $q, ())
    return 
        if(count($hits) gt 0) then 
            <json:value>
                <action>{$q} in {$element}</action>
                <info>hits: {count($hits)}</info>
                <start>1</start>
                <results>
                    {
                     for $hit in $hits
                     let $id := replace($hit/ancestor-or-self::tei:TEI/descendant::tei:publicationStmt/tei:idno[@type='URI'][1],'/tei','')
                     return
                         <json:value json:array="true">
                            <id>{$id}</id>
                            <headword>{if($hit[contains(@srophe:tags,'#syriaca-headword')]) then 'true' else 'false'}</headword>
                            {element {xs:QName($element)} { normalize-space(string-join($hit//text(),' ')) }}
                            {
                            if($element = 'persName') then 
                                <date>{
                                normalize-space(string-join($hit/ancestor-or-self::tei:TEI/descendant::tei:body/descendant::tei:birth/descendant-or-self::text() 
                                | $hit/ancestor-or-self::tei:TEI/descendant::tei:body/descendant::tei:death/descendant-or-self::text() | 
                                $hit/ancestor-or-self::tei:TEI/descendant::tei:body/descendant::tei:floruit/descendant-or-self::text(),' '))
                                }</date>
                            else ()
                            }
                         </json:value>                           
                     }
                </results>
            </json:value>
        else   
            <json:value>
                <json:value json:array="true">
                    <action>{$q} in {$element}</action>
                    <info>No results</info>
                    <start>1</start>
                </json:value>
            </json:value>           
};

(:~
 : Search API, returns coordinates     
:)
declare function local:coordinates($type as xs:string?, $collection as xs:string*){          
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

let $path := if(request:get-parameter('id', '')  != '') then 
                request:get-parameter('id', '')
             else if(request:get-parameter('doc', '') != '') then
                request:get-parameter('doc', '')
             else ()   
let $data :=
    if(request:get-parameter('id', '') != '' or request:get-parameter('doc', '') != '') then
        data:get-document()
    else if(request:get-parameter-names() != '') then 
        if(request:get-parameter('api', '') != '') then
            if(request:get-parameter('element', '') !='' and request:get-parameter('q', '') != '') then 
                local:search-element(request:get-parameter('element', ''), request:get-parameter('q', ''), if(request:get-parameter('collection', '')) then request:get-parameter('collection', '') else ())
            else if(request:get-parameter('geo', '') != '') then
               local:coordinates(request:get-parameter('type', ''), request:get-parameter('collection', ''))
            else <div>Nothing, check params: {request:get-parameter-names()}</div>
        else
            let $hits := data:search('','','')
            return 
                if(count($hits) gt 0) then 
                    <root>
                        <action>{string-join(
                                    for $param in request:get-parameter-names()
                                    return concat('&amp;',$param, '=',request:get-parameter($param, '')),'')}</action>
                        <info>hits: {count($hits)}</info>
                        <start>1</start>
                        <results>{
                            let $start := if(request:get-parameter('start', 1)) then request:get-parameter('start', 1) else 1
                            let $perpage := if(request:get-parameter('perpage', 10)) then request:get-parameter('perpage', 10) else 10
                            for $hit in subsequence($hits,$start,$perpage)
                            let $id := replace($hit/descendant::tei:idno[starts-with(.,$config:base-uri)][1],'/tei','')
                            let $title := $hit/descendant::tei:titleStmt/tei:title
                            let $expanded := kwic:expand($hit)
                            return 
                                <json:value json:array="true">
                                    <id>{$id}</id>
                                    {$title}
                                    <hits>{normalize-space(string-join((tei2html:output-kwic($expanded, $id)),' '))}</hits>
                                </json:value>
                            }
                        </results>
                    </root>
                else 
                    <root>
                        <json:value json:array="true">
                            <action>{string-join(
                                    for $param in request:get-parameter-names()
                                    return concat('&amp;',$param, '=',request:get-parameter($param, '')),'')}</action>
                            <info>No results</info>
                            <start>0</start>
                        </json:value>
                    </root>
       else ()
let $format := if(request:get-parameter('format', '') != '') then request:get-parameter('format', '') else 'xml'    
return  
    if(not(empty($data))) then
        if(request:get-parameter('api', '') != '') then
            if(request:get-parameter('geo', '')) then
                if($format = 'kml') then 
                    cntneg:content-negotiation($data,'kml',())
                else cntneg:content-negotiation($data,'geojson',())
            else 
                let $format := if(request:get-parameter('format', '') = 'xml') then 'xml' else 'json'
                return cntneg:content-negotiation($data, 'json', ())
        else cntneg:content-negotiation($data, $format, $path)    
    else ()