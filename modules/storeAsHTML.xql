xquery version "3.1";
(:~
 : XQuery to call, format and save TEI2HTML pages into the database
:)

import module namespace http="http://expath.org/ns/http-client";
import module namespace config="http://srophe.org/srophe/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace srophe="https://srophe.app";

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

declare function local:buildHTML($results as item()*, $htmlTemplate as xs:string?){
    <div xmlns="http://www.w3.org/1999/xhtml" xmlns:xi="http://www.w3.org/2001/XInclude" data-template="templates:surround" data-template-with="templates/{$htmlTemplate}.html" data-template-at="content">
        <div class="main-content-block">
            <div class="interior-content">
                <div data-template="app:other-data-formats" data-template-formats="print,tei,rdf,text"/>
                <div class="row">
                    <div class="col-md-7 col-lg-8">
                      <div data-template="app:fix-links">
                        {
                            transform:transform($results, doc($config:app-root || '/resources/xsl/tei2html.xsl'), 
                                <parameters>
                                    <param name="data-root" value="{$config:data-root}"/>
                                    <param name="app-root" value="{$config:app-root}"/>
                                    <param name="nav-base" value="{$config:nav-base}"/>
                                    <param name="base-uri" value="{$config:base-uri}"/>
                                </parameters>
                                )
                        }
                        </div>
                    </div>
                    <div class="col-md-5 col-lg-4 right-menu">
                        <br/>
                        <br/>
                        {
                        if($htmlTemplate = 'geo') then 
                            <div data-template="app:display-map"/>
                        else
                            <div data-template="app:display-related-places-map"/>
                        }
                        
                        <br/>
                        <div data-template="app:internal-relationships" data-template-label="Relationships"/>
                        <br/>
                    </div>
                </div>
                <div>
                </div>
            </div>
        </div>
        <!-- Modal email form-->
        <div data-template="app:contact-form" data-template-collection="{
        if($htmlTemplate = 'geo') then 'places' 
        else $htmlTemplate}"/> 
    </div> 
};

(: 
 : Page through all data
 : Also need a function for individual record
 : save to /html/collection/record.html
:)
declare function local:serializeData(){
    let $start := if(request:get-parameter('start', '') != '') then request:get-parameter('start', '') else 1
    let $limit := if(request:get-parameter('limit', '') != '') then request:get-parameter('limit', '') else 200
    let $startParam := if(request:get-parameter('start', '') != '') then concat('&amp;start=',request:get-parameter('start', '')) else '&amp;start=0'
    let $limitParam := if(request:get-parameter('limit', '') != '') then concat('&amp;limit=',request:get-parameter('limit', '')) else '&amp;limit=200'
    let $action := if(request:get-parameter('action', '') != '') then request:get-parameter('action', '') else 'check'
    let $items := if(request:get-parameter('id', '') != '') then collection($config:data-root)//tei:TEI[.//tei:idno[. = request:get-parameter('id', '')][@type='URI']] else collection($config:data-root)
    let $total := count($items)
    let $next := if(xs:integer($start) lt xs:integer($total)) then (xs:integer($start) + xs:integer($limit)) else ()
    let $group := 
            for $f in subsequence($items,$start,$limit)
            let $collection := document-uri($f)
            let $file := tokenize($collection,'/')[last()]
            let $fileName := replace($file,'.xml','.html')
            (:
            <collection name="places" app-root="/geo/" data-root="places" record-URI-pattern="https://architecturasinica.org/place/"/>
            <collection name="keywords" title="Architectural Features" app-root="/keyword/" data-root="keywords" record-URI-pattern="https://architecturasinica.org/keyword/"/>
            <collection name="bibl" title="Bibliography" app-root="/bibl/" data-root="bibl" record-URI-pattern="https://architecturasinica.org/bibl/"/>
            <collection name="sites" app-root="/geo/" data-root="places/sites" record-URI-pattern="https://architecturasinica.org/place/"/>
            <collection name="buildings" app-root="/geo/" data-root="places/buildings" record-URI-pattern="https://architecturasinica.org/place/"/>
            :)
            let $htmlCollection := 
                if(contains($collection,'/places/')) then 
                    'places'
                else if(contains($collection,'/sites/')) then 
                    'works'
                else if(contains($collection,'/bibl/')) then 
                    'sites'
                else if(contains($collection,'/buildings/')) then 
                    'buildings'    
                else if(contains($collection,'/keywords/')) then 
                    'keywords'  
                else if(contains($collection,'/bibl/')) then 
                    'bibl'     
                else 'unsorted'
            let $htmlPath := concat($config:app-root,'/html/',$htmlCollection)
            let $htmlTemplate := 'page'
            let $html := local:buildHTML($f, $htmlTemplate)
            let $buildPath := 
                    if(xmldb:collection-available($htmlPath)) then ()
                    else (local:mkcol("/db/apps", replace($htmlPath,'/db/apps','')))
            return 
               try {xmldb:store($htmlPath, xmldb:encode-uri($fileName), $html)} 
             catch *{
                    <response status="fail">
                        <message>Failed to add resource {$fileName}: {concat($err:code, ": ", $err:description)}</message>
                    </response>
                }
    return 
        if($next) then
            ($group,
            <div xmlns="http://www.w3.org/1999/xhtml">
                <p>Processed {if(request:get-parameter('start', '') != '') then request:get-parameter('start', '') else '0'} - {substring-before($next,'&amp;')} of {string($total)}</p>
                <p><a href="?start={$next}&amp;limit={$limit}" class="btn btn-info zotero">Next</a></p>
            </div>)
        else 
            ($group,
            <div><h3>Updated!</h3>
                <p><label>Number of updated records: </label> {string($total)}</p>
             </div>)
};

<div>{ local:serializeData() }</div>