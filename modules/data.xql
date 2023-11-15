xquery version "3.1";
(:~  
 : Basic data interactions, returns raw data for use in other modules  
 : Used by browse, search, and view records.  
 :
 : @see config.xqm for global variables
 : @see lib/paging.xqm for sort options
 : @see lib/relationships.xqm for building and visualizing relatiobships 
 :)
 

import module namespace config="http://srophe.org/srophe/config" at "config.xqm";
import module namespace cntneg="http://srophe.org/srophe/cntneg" at "content-negotiation/content-negotiation.xqm";
import module namespace relations="http://srophe.org/srophe/relationships" at "lib/relationships.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

let $collection :=  request:get-parameter("collection", ())
let $id :=  request:get-parameter("id", ())
let $ids :=  request:get-parameter("ids", ())
let $currentID :=  request:get-parameter("currentID", ())
let $relationshipType :=  request:get-parameter("relationshipType", ())
let $relationship :=  request:get-parameter("relationship", ())
let $label :=  request:get-parameter("label", ())
let $format :=  request:get-parameter("format", ())
let $collection-path := 
            if(config:collection-vars($collection)/@data-root != '') then concat('/',config:collection-vars($collection)/@data-root)
            else if($collection != '') then concat('/',$collection)
            else ()
let $data := if($ids != '') then
                collection($config:data-root)//tei:idno[@type='URI'][. = tokenize($ids,' ')]
             else if($collection != '') then
                  collection($config:data-root || $collection-path)
             else collection($config:data-root)
let $request-format := if($format != '') then $format else 'xml'
return 
    if($ids != '') then 
       (response:set-header("Content-Type", "text/html; charset=utf-8"),
       relations:get-related($data, request:get-parameter("relID", ())))
    else if($relationship != '') then
        if($relationship = 'internal') then 
            (response:set-header("Content-Type", "text/html; charset=utf-8"),
            relations:get-related($data, request:get-parameter("relID", ())))
        else if($relationship = 'external' and $currentID != '') then 
            (response:set-header("Content-Type", "text/html; charset=utf-8"),
            relations:display-external-relatiobships($currentID, $relationshipType, $label))
        else <message>Missing</message>
    else ()
