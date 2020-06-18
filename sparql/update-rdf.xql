xquery version "3.0";
(:~
 : XQuery RDF generation
 : Checks for updates since last modified version using:
     eXistdb's xmldb:find-last-modified-since($node-set as node()*, $since as xs:dateTime) as node()*
 : Converts TEI records to RDF using $global:public-view-base/modules/lib/rei2rdf.xqm 
 : Adds new RDF records to RDF store.
 :
:)

import module namespace http="http://expath.org/ns/http-client";
import module namespace config="http://srophe.org/srophe/config" at "../modules/config.xqm";
import module namespace tei2rdf="http://srophe.org/srophe/tei2rdf" at "../modules/content-negotiation/tei2rdf.xqm ";
import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: Can I store the last modified date in the script? :)
declare variable $rdf-config := if(doc('config.xml')) then doc('zotero-config.xml') else ();
declare variable $last-modified-version := $rdf-config//rdf/last-modified/text();

(: Update RDF :)
declare function local:update-rdf(){
let $action := request:get-parameter('action', '')
let $collection := request:get-parameter('collection', '')
return 
    if($action = 'initiate') then
        local:get-records($action,$collection,())
    else if(request:get-parameter('action', '') = 'update') then
        <response status="200" xmlns="http://www.w3.org/1999/xhtml">
            <message>Update!</message>
        </response>
    else 
        <response status="400" xmlns="http://www.w3.org/1999/xhtml">
            <message>You did not give me any directions.</message>
        </response>
};

declare function local:get-records($action as xs:string?, $collection as xs:string?, $date as xs:dateTime?){
    if($action = 'initiate') then
        let $records := 
                (: Special handling for SPEAR, to process every div[@uri] as a record. :)
                if($collection = 'spear') then
                    (
                    for $r in collection($config:data-root || '/' || $collection)//tei:div[@uri]
                    let $teiHeader := root($r)//tei:teiHeader
                    return 
                        <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">{($teiHeader,$r)}</tei:TEI>
                        ) 
                else collection($config:data-root || '/' || $collection)/tei:TEI
        let $total := count($records)
        let $perpage := 50
        let $pages := xs:integer($total div $perpage)
        let $start := 0
        return 
            if(request:get-parameter('pelagios', '') = 'dump') then 
                let $rdf := tei2rdf:rdf-output($records)
                return 
                (response:set-header("Content-Disposition", fn:concat("attachment; filename=", concat($collection,'-','pelagios','.rdf'))),$rdf)
                    (:file:serialize($rdf, '/Users/wsalesky/Desktop', ()) :)
            else 
                <response status="200" xmlns="http://www.w3.org/1999/xhtml">
                    <message style="margin:1em;padding:1em; border: 1px solid #eee; display:block;">
                        <strong>Total: </strong>{$total}<br/>
                        <strong>Per page: </strong>{$perpage}<br/>
                        <strong>Pages: </strong>{$pages}<br/>
                        <strong>Collection: </strong>{$collection}<br/>
                    </message>
                    <output>{(local:process-results($records, $total, $start, $perpage, $collection)(:,local:create-void-record($records, $total, $start, $perpage, $collection):))}</output>
                </response>
    else if($action = 'update') then 
        let $records := 
            if($collection != '') then 
                collection($config:data-root || '/' || $collection)/tei:TEI[xmldb:find-last-modified-since(., xs:dateTime($date))] 
            else collection($config:data-root)/tei:TEI[xmldb:find-last-modified-since(., xs:dateTime($date))]
        let $total := count($records)
        let $perpage := 50
        let $pages := xs:integer($total div $perpage)
        let $start := 0
        return 
            <response status="200" xmlns="http://www.w3.org/1999/xhtml">
                <message style="margin:1em;padding:1em; border: 1px solid #eee; display:block;">
                    <strong>Total: </strong>{$total}<br/>
                    <strong>Per page: </strong>{$perpage}<br/>
                    <strong>Pages: </strong>{$pages}<br/>
                    <strong>Collection: </strong>{$collection}<br/>
                </message>
                <output>{local:process-results($records, $total, $start, $perpage, $collection)}</output>
            </response>            
    else 
        <response status="200" xmlns="http://www.w3.org/1999/xhtml">
            <message>There is no other hand.</message>
        </response>
};

declare function local:create-void-record($records, $total, $start, $perpage, $collection) {
let $void-file :=
    if($collection = 'bibl') then
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:void="http://rdfs.org/ns/void#"
         xmlns:owl="http://www.w3.org/2002/07/owl#"
         xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
         xmlns:dcterms="http://purl.org/dc/terms/"
         xmlns:foaf="http://xmlns.com/foaf/0.1/">
            <void:Dataset rdf:about="http://syriaca.org/bibl">
                <dcterms:title>yriaca.org: Works Cited RDF Dataset</dcterms:title>
                <dcterms:publisher>Syriaca.org: The Syriac Reference Portal</dcterms:publisher>
                <foaf:homepage rdf:resource="http://syriaca.org/bibl"/>
                <dcterms:description>Syriaca.org: Works Cited RDF Dataset is a linked dataset derived from Syriaca.org: Works Cited data set.</dcterms:description>
                <dcterms:creator>David A. Michelson</dcterms:creator>
                <dcterms:date>2016</dcterms:date>
                <dcterms:license rdf:resource="http://creativecommons.org/licenses/by/3.0/"/>
                <dcterms:source>Syriaca.org: Works Cited</dcterms:source>
                <dcterms:created>{current-date()}</dcterms:created>
                <void:documents>{$total}</void:documents>
                <void:dataDump rdf:resource="https://github.com/srophe/srophe-data-rdf/tree/master/rdf/srophe/bibl"/>
            </void:Dataset>
        </rdf:RDF>
    else if($collection = 'persons') then
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:void="http://rdfs.org/ns/void#"
         xmlns:owl="http://www.w3.org/2002/07/owl#"
         xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
         xmlns:dcterms="http://purl.org/dc/terms/"
         xmlns:foaf="http://xmlns.com/foaf/0.1/">
            <void:Dataset rdf:about="http://syriaca.org/persons">
                <dcterms:title>The Syriac Biographical Dictionary RDF Dataset</dcterms:title>
                <dcterms:publisher>Syriaca.org: The Syriac Reference Portal</dcterms:publisher>
                <foaf:homepage rdf:resource="http://syriaca.org/persons"/>
                <dcterms:description>The Syriac Biographical Dictionary RDF Dataset is a linked dataset derived from The Syriac Biographical Dictionary, a multi-volume name and biographic authority record documenting persons relevant to the field of Syriac studies.</dcterms:description>
                <dcterms:creator>David A. Michelson</dcterms:creator>
                <dcterms:creator>Jeanne-Nicole Mellon Saint-Laurent</dcterms:creator>
                <dcterms:date>2016</dcterms:date>
                <dcterms:license rdf:resource="http://creativecommons.org/licenses/by/3.0/"/>
                <dcterms:source>The Syriac Biographical Dictionary</dcterms:source>
                <dcterms:created>{current-date()}</dcterms:created>
                <void:documents>{$total}</void:documents>
                <void:dataDump rdf:resource="https://github.com/srophe/srophe-data-rdf/tree/master/rdf/srophe/persons"/>
            </void:Dataset>
        </rdf:RDF>
    else if($collection = 'places') then
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:void="http://rdfs.org/ns/void#"
         xmlns:owl="http://www.w3.org/2002/07/owl#"
         xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
         xmlns:dcterms="http://purl.org/dc/terms/"
         xmlns:foaf="http://xmlns.com/foaf/0.1/">
            <void:Dataset rdf:about="http://syriaca.org/geo">
                <dcterms:title>The Syriac Gazetteer RDF Dataset</dcterms:title>
                <dcterms:publisher>Syriaca.org: The Syriac Reference Portal</dcterms:publisher>
                <foaf:homepage rdf:resource="http://syriaca.org/geo"/>
                <dcterms:description>The Syriac Gazetteer RDF Dataset is a linked dataset derived from The Syriac Gazetteer, a geographical reference work of Syriaca.org for places relevant to Syriac studies.</dcterms:description>
                <dcterms:creator>Thomas A. Carlson</dcterms:creator>
                <dcterms:creator>David A. Michelson</dcterms:creator>
                <dcterms:date>2014</dcterms:date>
                <dcterms:license rdf:resource="http://creativecommons.org/licenses/by/3.0/"/>
                <dcterms:source>The Syriac Gazetteer</dcterms:source>
                <dcterms:created>{current-date()}</dcterms:created>
                <void:documents>{$total}</void:documents>
                <void:dataDump rdf:resource="https://github.com/srophe/srophe-data-rdf/tree/master/rdf/srophe/places"/>
            </void:Dataset>
        </rdf:RDF>
    else if($collection = 'subjects') then
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:void="http://rdfs.org/ns/void#"
         xmlns:owl="http://www.w3.org/2002/07/owl#"
         xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
         xmlns:dcterms="http://purl.org/dc/terms/"
         xmlns:foaf="http://xmlns.com/foaf/0.1/">
            <void:Dataset rdf:about="http://syriaca.org/taxonomy">
                <dcterms:title>A Taxonomy of Syriac Studies</dcterms:title>
                <dcterms:publisher>Syriaca.org: The Syriac Reference Portal</dcterms:publisher>
                <foaf:homepage rdf:resource="http://syriaca.org/taxonomy"/>
                <dcterms:description>A Taxonomy of Syriac Studies RDF Dataset is a linked dataset derived from A Taxonomy of Syriac Studies.</dcterms:description>
                <dcterms:creator>David A. Michelson</dcterms:creator>
                <dcterms:date>2016</dcterms:date>
                <dcterms:license rdf:resource="http://creativecommons.org/licenses/by/3.0/"/>
                <dcterms:source>A Taxonomy of Syriac Studies</dcterms:source>
                <dcterms:created>{current-date()}</dcterms:created>
                <void:documents>{$total}</void:documents>
                <void:dataDump rdf:resource="https://github.com/srophe/srophe-data-rdf/tree/master/rdf/srophe/subjects"/>
            </void:Dataset>
        </rdf:RDF>
    else if($collection = 'spear') then
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:void="http://rdfs.org/ns/void#"
         xmlns:owl="http://www.w3.org/2002/07/owl#"
         xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
         xmlns:dcterms="http://purl.org/dc/terms/"
         xmlns:foaf="http://xmlns.com/foaf/0.1/">
            <void:Dataset rdf:about="http://syriaca.org/spear">
                <dcterms:title>SPEAR: Syriac Persons Events and Relations RDF Dataset</dcterms:title>
                <dcterms:publisher>Syriaca.org: The Syriac Reference Portal</dcterms:publisher>
                <foaf:homepage rdf:resource="http://syriaca.org/spear"/>
                <dcterms:description>SPEAR: Syriac Persons Events and Relations RDF Dataset is a linked dataset derived from SPEAR: Syriac Persons Events and Relations, is a prosopographical reference work designed to provide information about persons and their relationships within the context of historical events.</dcterms:description>
                <dcterms:creator>Daniel L. Schwartz</dcterms:creator>
                <dcterms:date>2016</dcterms:date>
                <dcterms:license rdf:resource="http://creativecommons.org/licenses/by/3.0/"/>
                <dcterms:source>SPEAR: Syriac Persons Events and Relations</dcterms:source>
                <dcterms:created>{current-date()}</dcterms:created>
                <void:documents>{$total}</void:documents>
                <void:dataDump rdf:resource="https://github.com/srophe/srophe-data-rdf/tree/master/rdf/srophe/spear"/>
            </void:Dataset>
        </rdf:RDF>        
    else if($collection = 'works') then
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:void="http://rdfs.org/ns/void#"
         xmlns:owl="http://www.w3.org/2002/07/owl#"
         xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
         xmlns:dcterms="http://purl.org/dc/terms/"
         xmlns:foaf="http://xmlns.com/foaf/0.1/">
            <void:Dataset rdf:about="http://syriaca.org/works">
                <dcterms:title>The New Handbook of Syriac Literature RDF Dataset</dcterms:title>
                <dcterms:publisher>Syriaca.org: The Syriac Reference Portal</dcterms:publisher>
                <foaf:homepage rdf:resource="http://syriaca.org/works"/>
                <dcterms:description>The New Handbook of Syriac Literature RDF Dataset is a linked dataset derived from The New Handbook of Syriac Literature.</dcterms:description>
                <dcterms:creator>Nathan P. Gibson</dcterms:creator>
                <dcterms:creator>David A. Michelson</dcterms:creator>
                <dcterms:creator>Jeanne-Nicole Mellon Saint-Laurent</dcterms:creator>
                <dcterms:date>2016</dcterms:date>
                <dcterms:license rdf:resource="http://creativecommons.org/licenses/by/3.0/"/>
                <dcterms:source>The New Handbook of Syriac Literature</dcterms:source>
                <dcterms:created>{current-date()}</dcterms:created>
                <void:documents>{$total}</void:documents>
                <void:dataDump rdf:resource="https://github.com/srophe/srophe-data-rdf/tree/master/rdf/srophe/works"/>
            </void:Dataset>
        </rdf:RDF>
    else ()  
let $repository := replace($config:app-root,'/db/apps/','')    
return xmldb:store('/db/rdftest/' || $repository, xmldb:encode-uri(concat($collection,'.void.rdf')), $void-file)
};

declare function local:process-results($records as item()*, $total, $start, $perpage, $collection-name){
    let $end := $start + $perpage
    return 
        (    
         (: Process collection records :)
         for $r in subsequence($records,$start,$perpage)
         let $id := 
                if($r/descendant-or-self::tei:div[@uri]) then 
                    string($r/descendant-or-self::tei:div[@uri][1]/@uri) 
                else replace($r/descendant::tei:idno[starts-with(.,$config:base-uri)][1],'/tei','')
         let $uri := document-uri(root($r))
         let $rdf := try {tei2rdf:rdf-output($r)}catch *{
                 <response status="fail" xmlns="http://www.w3.org/1999/xhtml">
                     <message>RDF fail {$uri} {concat($err:code, ": ", $err:description)}</message>
                 </response>
                 }
         let $file-name := substring-before(tokenize($uri,'/')[last()],'.xml')
         let $collection := substring-before(substring-before($uri, $file-name),'/tei/')
         let $repository := replace($config:app-root,'/db/apps/','')
         let $rdf-collection := if($collection-name = 'spear' or $r/descendant-or-self::tei:div[@uri] or contains($uri,'/spear/')) then 'spear' else replace(substring(substring-after($collection, $config:data-root),2),'tei','')
         let $rdf-filename := concat(replace(substring-after($id,'http://'),'/|\.','-'),'.rdf')
         let $rdf-path := concat($repository,'/',$rdf-collection) 
         return 
            if($rdf/@status='fail') then ()
            else 
             try {
                 <response status="200" xmlns="http://www.w3.org/1999/xhtml">
                     <message>{(
                             (: Check for local collection :)
                            if(xmldb:collection-available('/db/rdftest/' || $rdf-path)) then ()
                            else local:mkcol("/db/rdftest", $rdf-path),
                            xmldb:store('/db/rdftest/' || $rdf-path, xmldb:encode-uri($rdf-filename), $rdf)
                     )}</message>
                 </response>
                 } catch *{
                 <response status="fail" xmlns="http://www.w3.org/1999/xhtml">
                     <message>Failed to add resource {$rdf-filename}: {concat($err:code, ": ", $err:description)}</message>
                 </response>
                 },
         (: Go to next :)        
         if($total gt $end) then 
             local:process-results($records, $total, $end, $perpage, $collection-name)
         else ()
         )            
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

(: Create rdf collection if it does not exist. :)
declare function local:build-collection-rdf(){
    let $rdf-coll := xmldb:create-collection("/db", "rdftest")
    let $rdf-conf-coll := xmldb:create-collection("/db/system/config/db", "rdftest")
    let $rdf-conf :=
        <collection xmlns="http://exist-db.org/collection-config/1.0">
           <index xmlns:xs="http://www.w3.org/2001/XMLSchema">
              <rdf />
           </index>
        </collection>
    return xmldb:store($rdf-conf-coll, "collection.xconf", $rdf-conf)
};

(:~
 : Check action parameter, if empty, return contents of config.xml
 : If $action is not empty, check for specified collection, create if it does not exist. 
 : Run Zotero request. 
:)
if(request:get-parameter('action', '') != '') then
    if(request:get-parameter('pelagios', '') = 'dump') then
        local:update-rdf()
    if(request:get-parameter('download', '') = 'true') then
        local:update-rdf()        
    else if(xmldb:collection-available('/db/rdftest')) then
        <response xmlns="http://www.w3.org/1999/xhtml">{ local:update-rdf() }</response>
    else <response xmlns="http://www.w3.org/1999/xhtml">{ (local:build-collection-rdf(),local:update-rdf()) }</response>
else if(request:get-parameter('id', '') != '') then
     let $rec := collection($config:data-root)/tei:TEI[descendant::tei:idno[. = request:get-parameter('id', '')]]
     return 
        if(xmldb:collection-available('/db/rdftest')) then         
            <response xmlns="http://www.w3.org/1999/xhtml">{ local:process-results($rec, 1,1,1,()) }</response>
        else <response xmlns="http://www.w3.org/1999/xhtml">{(: (local:build-collection-rdf(),local:update-rdf()) :) 'Error'}</response>
else 
    <div xmlns="http://www.w3.org/1999/xhtml">
        <p><label>Last Updated: </label> {$last-modified-version}</p>
    </div>