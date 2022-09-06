xquery version "3.1";
(:~
 : XQuery Zotero integration
 : Queries Zotero API : https://api.zotero.org
 : Checks for updates since last modified version using Zotero Last-Modified-Version header
 : Converts Zotero records to Syriaca.org TEI using zotero2tei.xqm
 : Adds new records to directory.
 :
 : To be done: 
 :      Submit to Perseids
:)

import module namespace http="http://expath.org/ns/http-client";
import module namespace zotero2tei="http://syriaca.org/zotero2tei" at "zotero2tei.xqm";
import module namespace console="http://exist-db.org/xquery/console";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare variable $zotero-api := 'https://api.zotero.org';

(: Access zotero-api configuration file :) 
declare variable $zotero-config := doc('zotero-config.xml');
(: Zotero group id :)
declare variable $groupid := $zotero-config//groupid/text();
(: Zotero last modified version, to check for updates. :)
declare variable $last-modified-version := $zotero-config//last-modified-version/text();
(: Directory bibl data is stored in :)
declare variable $data-dir := $zotero-config//data-dir/text();
(: Local URI pattern for bibl records :)
declare variable $base-uri := $zotero-config//base-uri/text();
(: Format defaults to tei :)
declare variable $format := if($zotero-config//format/text() != '') then $zotero-config//format/text() else 'tei';
(: API key :)
declare variable $apikey := $zotero-config//api-key/text();

(:~
 : Convert records to Syriaca.org compliant TEI records, using zotero2tei.xqm
 : Save records to the database. 
 : @param $record 
 : @param $index-number
 : @param $format
:)
declare function local:process-records($record as item()?, $format as xs:string?){
    let $idNumber :=
                    if($zotero-config//id-pattern/text() = 'zotero' and $format = 'json') then
                        tokenize($record?links?alternate?href,'/')[last()]
                    else if($zotero-config//id-pattern/text() = 'zotero' and $format ='tei') then
                        tokenize($record/@corresp,'/')[last()]
                    else util:random(10000)                   
    (:let $id := local:make-local-uri($index-number):)
    let $file-name := concat($idNumber,'.xml')
    let $new-record := zotero2tei:build-new-record($record, $idNumber, $format)
    return 
        if($idNumber != '') then 
            try {xmldb:store($data-dir, xmldb:encode-uri($file-name), $new-record)} catch *{
                <response status="fail">
                    <message>Failed to add resource {$file-name}: {concat($err:code, ": ", $err:description), console:log(concat($err:code, ": ", $err:description))}</message>
                </response>
            } 
        else ()  
};

(:~
 : Get highest existing local id in the eXist database. Increment new record ids
 : @param $path to existing bibliographic data
 : @param $base-uri base uri defined in repo.xml, establishing pattern for bibl ids. example: http://syriaca.org/bibl 
:)
declare function local:make-local-uri($index-number as xs:integer) {
    let $all-bibl-ids := 
            for $uri in collection($data-dir)/tei:TEI/tei:text/tei:body/tei:biblStruct/descendant::tei:idno[starts-with(.,$base-uri)]
            return number(replace(replace($uri,$base-uri,''),'/tei',''))
    let $max := max($all-bibl-ids)          
    return
        if($max) then concat($base-uri,'/', ($max + $index-number))
        else concat($base-uri,'/',$index-number)
};

(:~
 : Update stored last modified version (from Zotero API) in zotero-config.xml
:)
declare function local:update-version($version as xs:string?) {
    try {
            <response status="200">
                    <message>{for $v in $zotero-config//last-modified-version return update value $v with $version}</message>
                </response>
        } catch *{
            <response status="fail">
                <message>Failed to update last-modified-version: {concat($err:code, ": ", $err:description)}</message>
            </response>
        } 
};

(:~
 : Page through Zotero results
 : @param $groupid
 : @param $last-modified-version
 : @param $total
 : @param $start
 : @param $perpage
:)
declare function local:process-results($results as item()*){
    let $items := $results
    let $headers := $items[1]
    let $results := 
        if($format = 'json') then 
            parse-json(util:binary-to-string($items[2])) 
        else $items[2]
    return 
        if($headers/@status = '200') then
            if($format = 'json') then
                for $rec at $p in $results?*
                where not(exists($rec?data?parentItem))
                return local:process-records($rec, $format)
            else 
                for $rec at $p in $results//tei:biblStruct
                return $rec(:local:process-records($rec, $format):)
(:        else if($headers/@name="Backoff") then:)
(:            (<message status="{$headers/@status}">{string($headers/@message)}</message>,:)
(:                let $wait := util:wait(xs:integer($headers[@name="Backoff"][@value])):)
(:                return local:get-zotero():)
(:            ):)
(:        else if($headers/@name="Retry-After") then   :)
(:            (<message status="{$headers/@status}">{string($headers/@message)}</message>,:)
(:                let $wait := util:wait(xs:integer($headers[@name="Retry-After"][@value])):)
(:                return local:get-zotero():)
(:            ):)
        else  <message status="{$headers/@status}">{string($headers/@message)}</message>    
};

(:~
 : Get Zotero data
 : Check for updates since last modified version (stored in $zotero-config)
 : @param $groupid Zotero group id
 : @param $last-modified-version
:)
declare function local:get-zotero-data($url){ 
(:http:send-request(<http:request http-version="1.1" href="{xs:anyURI($url)}" method="get"></http:request>):)
    if(request:get-parameter('action', '') = 'initiate') then 
            http:send-request(<http:request http-version="1.1" href="{xs:anyURI($url)}" method="get">
                                {if($apikey != '') then
                                    <http:header name="Zotero-API-Key" value="{$apikey}"/>
                                 else ()
                                 }
                              </http:request>)
    else http:send-request(<http:request http-version="1.1" href="{xs:anyURI($url)}" method="get">
                             {if($apikey != '') then
                                    <http:header name="Zotero-API-Key" value="{$apikey}"/>
                                 else ()}
                             <http:header name="If-Modified-Since-Version" value="{$last-modified-version}"/>
                           </http:request>)                           
};

(:~
 : Get and process Zotero data. 
:)
declare function local:get-zotero(){
    let $start := if(request:get-parameter('start', '') != '') then concat('&amp;start=',request:get-parameter('start', '')) else '&amp;start=0'
    let $limit := if(request:get-parameter('limit', '') != '') then concat('&amp;limit=',request:get-parameter('limit', '')) else '&amp;limit=50'
    let $action := if(request:get-parameter('action', '') != '') then request:get-parameter('action', '') else 'check'
    let $since := if($action = 'update') then concat('&amp;since=',$last-modified-version) else ()
    let $url := if(request:get-parameter('next', '') != '') then request:get-parameter('next', '') else concat($zotero-api,'/groups/',$groupid,'/items?format=',$format,if($format='json') then '&amp;include=bib,data,coins,citation&amp;style=chicago-fullnote-bibliography' else(),$start, $limit, $since)
    let $items := local:get-zotero-data($url)
    let $items-info := $items[1]
    let $total := $items-info/http:header[@name='total-results']/@value
    let $version := $items-info/http:header[@name='last-modified-version']/@value
    let $links := string($items-info/http:header[@name='link']/@value)
    let $next-link := tokenize($links,',')[contains(., 'rel="next"')]    
    let $next-url := replace(substring-before($next-link, '; '),'&lt;|&gt;','')
    let $new-start := substring-after($next-url,'start=')
    return 
        if(request:get-parameter('action', '') = 'check') then
            <div xmlns="http://www.w3.org/1999/xhtml" id="response">
                {
                    if($items-info/@message="Not Modified") then 
                        <p><label>Updates : </label> No updates available.</p>
                    else 
                        (<p><label>Last Modified Version (Zotero): </label> {string($version)}</p>,
                        <p><label>Number of updated records: </label> {string($total)}</p>
                        )
                }
             </div>
        else if($items-info/@status = '200') then
            <div xmlns="http://www.w3.org/1999/xhtml" id="response">
            {
             let $results := 
                  (local:process-results($items),
                  if($next-url) then () else local:update-version($version))
              return 
              (if(request:get-parameter('debug', '') = 'true') then $results else (),
              if($next-url) then
                  <div xmlns="http://www.w3.org/1999/xhtml">
                      <p>Processed {if(request:get-parameter('start', '') != '') then request:get-parameter('start', '') else '0'} - {substring-before($new-start,'&amp;')} of {string($total)}</p>
                      <p><a href="get-zotero-data.xql?action={$action}&amp;start={$new-start}{$since}" class="btn btn-info zotero">Next</a></p>
                  </div>
              else 
                if($items-info/@message="Not Modified") then 
                    <p><label>Updates : </label> No updates available.</p>
                else 
                    <div><h3>Updated</h3>
                      <p><label>Last Modified Version (Zotero): </label> {string($version)}</p>
                      <p><label>Number of updated records: </label> {string($total)}</p>
                      </div>)
             }</div>
        else <message status="{$items-info/@status}">{string($items-info/@message)} {$url}</message> 
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

(:~
 : Check action parameter, if empty, return contents of config.xml
 : If $action is not empty, check for specified collection, create if it does not exist. 
 : Run Zotero request. 
:)
if(request:get-parameter('action', '') = 'update') then
    if(xmldb:collection-available($data-dir)) then
        local:get-zotero()
    else (local:mkcol("/db/apps", replace($data-dir,'/db/apps','')),local:get-zotero())
else if(request:get-parameter('action', '') = 'initiate') then 
    if(request:get-parameter('start', '') != '' and xmldb:collection-available($data-dir)) then 
        local:get-zotero()
    else if((request:get-parameter('start', '') = '0' or  request:get-parameter('start', '') = '1') and xmldb:collection-available($data-dir)) then 
        local:get-zotero()        
    else if(xmldb:collection-available($data-dir)) then
        (xmldb:remove($data-dir),local:mkcol("/db/apps", replace($data-dir,'/db/apps','')),local:get-zotero())
    else (local:mkcol("/db/apps", replace($data-dir,'/db/apps','')),local:get-zotero())
else 
    <div xmlns="http://www.w3.org/1999/xhtml">
        <p><label>Group ID : </label> {$groupid}</p>
        <p><label>Last Modified Version (Zotero): </label> {$last-modified-version}</p>
        <p><label>Data Directory : </label> {$data-dir}</p>    
    </div>