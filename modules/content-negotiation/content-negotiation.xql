xquery version "3.0";

(:~
 : Passes content to content negotiation module, if not using restxq
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2018-04-12
:)

import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";

(: Content serialization modules. :)
import module namespace cntneg="http://syriaca.org/srophe/cntneg" at "content-negotiation.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "tei2html.xqm";

(: Data processing module. :)
import module namespace data="http://syriaca.org/srophe/data" at "../lib/data.xqm";

(: Import KWIC module:)
import module namespace kwic="http://exist-db.org/xquery/kwic";

(: Namespaces :)
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http="http://expath.org/ns/http-client";

let $path := if(request:get-parameter('id', '')  != '') then 
                request:get-parameter('id', '')
             else if(request:get-parameter('doc', '') != '') then
                request:get-parameter('doc', '')
             else ()   
let $data :=
    if(request:get-parameter('id', '') != '' or request:get-parameter('doc', '') != '') then
        data:get-document()
    else if(request:get-parameter-names() != '') then 
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
        cntneg:content-negotiation($data, $format, $path)    
    else ()
    