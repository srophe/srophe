xquery version "3.0";

module namespace cntneg="http://syriaca.org/srophe/cntneg";
(:~
 : Module for content negotiation based on work done by Steve Baskauf
 : https://github.com/baskaufs/guid-o-matic
 : Supported serializations: 
    - TEI to HTML
    - TEI to PDF
    - TEI to EPUB
    - TEI to RDF/XML
    - TEI to RDF/ttl
    - TEI to geoJSON
    - TEI to KML
    - TEI to Atom 
    - SPARQL XML to JSON-LD
 : Add additional serializations to lib folder and call them here.
 :
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2018-04-12
:)

(:
 : Content serialization modules.
 : Additional modules can be added. 
:)
import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";
import module namespace feed="http://syriaca.org/srophe/atom" at "atom.xqm";
import module namespace geojson="http://syriaca.org/srophe/geojson" at "geojson.xqm";
import module namespace geokml="http://syriaca.org/srophe/geokml" at "geokml.xqm";
import module namespace jsonld="http://syriaca.org/srophe/jsonld" at "jsonld.xqm";
import module namespace tei2rdf="http://syriaca.org/srophe/tei2rdf" at "tei2rdf.xqm";
import module namespace tei2ttl="http://syriaca.org/srophe/tei2ttl" at "tei2ttl.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "tei2html.xqm";
import module namespace tei2txt="http://syriaca.org/srophe/tei2txt" at "tei2txt.xqm";

(: These are needed for rending as HTML via existdb templating module, can be removed if not using 
import module namespace config="http://syriaca.org/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
:)

(: Namespaces :)
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace http="http://expath.org/ns/http-client";
declare namespace fo="http://www.w3.org/1999/XSL/Format";

(:
 : Main content negotiation
 : @param $data - data to be serialized
 : @param $content-type - content-type header to determine serialization 
 : @param $path - url can be used to determine content-type if content-type header is not available
 :
 : @NOTE - This function has two ways to serialize HTML records, these can easily be swapped out for other HTML serializations, including an XSLT version: 
        1. tei2html.xqm (an incomplete serialization, used primarily for search and browse results)
        2. eXistdb's templating module for full html page display
:)
declare function cntneg:content-negotiation($data as item()*, $content-type as xs:string?, $path as xs:string?){
    let $page := if(contains($path,'/')) then tokenize($path,'/')[last()] else $path
    let $type := 
                 if($content-type) then 
                    cntneg:determine-extension($content-type)
                 else if(contains($path,'.')) then 
                    fn:tokenize($path, '\.')[fn:last()]                    
                 else 'html'
    let $file-name := if(contains($page,'.')) then substring-before($page,'.') else $page                 
    let $flag := cntneg:determine-type-flag($type)
    return 
        if($flag = 'atom') then 
           <message>Not an available data format.</message>
           (: (response:set-header("Content-Type", "application/atom+xml; charset=utf-8"), feed:build-atom-feed($data,(),(),(),())):)
        else if($flag = 'geojson') then 
            (response:set-header("Content-Type", "application/json; charset=utf-8"),
            response:set-header("Access-Control-Allow-Origin", "application/json; charset=utf-8"),
            geojson:geojson($data))
        else if($flag = 'jsonld') then 
            (response:set-header("Content-Type", "application/ld+json; charset=utf-8"),
            response:set-header("Access-Control-Allow-Origin", "application/json; charset=utf-8"),
            jsonld:jsonld($data))
        else if($flag = 'json') then 
            (response:set-header("Content-Type", "application/json; charset=utf-8"),
            response:set-header("Access-Control-Allow-Origin", "application/json; charset=utf-8"),
            serialize($data, 
                <output:serialization-parameters>
                    <output:method>json</output:method>
                </output:serialization-parameters>))        
        else if($flag = 'kml') then 
            (response:set-header("Content-Type", "application/xml; charset=utf-8"),
            response:set-header("media-type", "application/vnd.google-earth.kmz"),
            geokml:kml($data))
        else if($flag = ('rdf')) then 
            (response:set-header("Content-Type", "application/xml; charset=utf-8"),tei2rdf:rdf-output($data))
        else if($flag = ('turtle','ttl')) then 
            (response:set-header("Content-Type", "text/turtle; charset=utf-8"),
            response:set-header("method", "text"),
            response:set-header("media-type", "text/plain"),
            tei2ttl:ttl-output($data))
        else if($flag = ('tei','xml')) then 
            (response:set-header("Content-Type", "application/xml; charset=utf-8"),$data)                               
        else if($flag = ('txt','text')) then
            (response:set-header("Content-Type", "text/plain; charset=utf-8"),
             response:set-header("Access-Control-Allow-Origin", "text/plain; charset=utf-8"),
             tei2txt:tei2txt($data))
        (: Output as html using existdb templating module or tei2html.xqm :)
        else
            (response:set-header("Content-Type", "text/html; charset=utf-8"),
             tei2html:tei2html($data))   
}; 

(:Main entry point via restxq :)
declare function cntneg:content-negotiation-restxq($data as item()*, $content-type as xs:string?, $path as xs:string?){
    let $page := if(contains($path,'/')) then tokenize($path,'/')[last()] else $path
    let $type := if($content-type) then 
                    cntneg:determine-extension($content-type)
                 else if(contains($path,'.')) then 
                    fn:tokenize($path, '\.')[fn:last()]                    
                 else 'html'
    let $flag := cntneg:determine-type-flag($type)
    return 
        if($flag = ('tei','xml')) then 
            (<rest:response> 
                <http:response status="200"> 
                    <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
                </http:response> 
                <output:serialization-parameters>
                    <output:method value='xml'/>
                    <output:media-type value='text/xml'/>
                </output:serialization-parameters>
             </rest:response>,$data)
        else if($flag = 'atom') then <message>Not an available data format.</message>
        else if($flag = 'rdf') then 
            (<rest:response> 
                <http:response status="200"> 
                    <http:header name="Content-Type" value="application/xml; charset=utf-8"/>  
                    <http:header name="media-type" value="application/xml"/>
                </http:response> 
                <output:serialization-parameters>
                    <output:method value='xml'/>
                    <output:media-type value='application/xml'/>
                </output:serialization-parameters>
             </rest:response>, tei2rdf:rdf-output($data))
        else if($flag = ('turtle','ttl')) then <message>Not an available data format.</message>
             (<rest:response> 
                <http:response status="200"> 
                    <http:header name="Content-Type" value="text/turtle; charset=utf-8"/>
                    <http:header name="method" value="text"/>
                    <http:header name="media-type" value="text/plain"/>
                </http:response>
                <output:serialization-parameters>
                    <output:method value='text'/>
                    <output:media-type value='text/plain'/>
                </output:serialization-parameters>
            </rest:response>, tei2ttl:ttl-output($data))
        else if($flag = 'geojson') then 
            (<rest:response> 
                <http:response status="200"> 
                    <http:header name="Content-Type" value="application/json; charset=utf-8"/>
                    <http:header name="Access-Control-Allow-Origin" value="application/json; charset=utf-8"/> 
                </http:response> 
             </rest:response>, geojson:geojson($data))
        else if($flag = 'kml') then 
            (<rest:response> 
                <http:response status="200"> 
                    <http:header name="Content-Type" value="application/xml; charset=utf-8"/>  
                </http:response> 
                <output:serialization-parameters>
                    <output:method value='xml'/>
                    <output:media-type value='application/vnd.google-earth.kmz'/>
                    </output:serialization-parameters>                        
             </rest:response>, geokml:kml($data))
        else if($flag = 'json') then 
            (<rest:response> 
                <http:response status="200"> 
                    <http:header name="Content-Type" value="application/json; charset=utf-8"/>
                    <http:header name="Access-Control-Allow-Origin" value="application/json; charset=utf-8"/> 
                </http:response> 
             </rest:response>, jsonld:jsonld($data))
        else if($flag = 'txt') then 
            (<rest:response> 
                <http:response status="200"> 
                    <http:header name="Content-Type" value="text/plain; charset=utf-8"/>
                    <http:header name="Access-Control-Allow-Origin" value="text/plain; charset=utf-8"/> 
                </http:response> 
             </rest:response>, tei2txt:tei2txt($data))
        (: Output as html using tei2html.xqm :)
        else
            (<rest:response> 
                <http:response status="200"> 
                    <http:header name="Content-Type" value="text/html; charset=utf-8"/>  
                </http:response> 
                <output:serialization-parameters>
                    <output:method value='html5'/>
                    <output:media-type value='text/html'/>
                </output:serialization-parameters>                        
            </rest:response>, tei2html:tei2html($data))
};

(: Utility functions to set media type-dependent values :)

(: Functions used to set media type-specific values :)
declare function cntneg:determine-extension($header){
    if (contains(string-join($header),"application/rdf+xml") or $header = 'rdf') then "rdf"
    else if (contains(string-join($header),"text/turtle") or $header = ('ttl','turtle')) then "ttl"
    else if (contains(string-join($header),"application/ld+json") or contains(string-join($header),"application/json") or $header = ('json','ld+json')) then "json"
    else if (contains(string-join($header),"application/tei+xml") or contains(string-join($header),"text/xml") or $header = ('tei','xml')) then "tei"
    else if (contains(string-join($header),"application/atom+xml") or $header = 'atom') then "atom"
    else if (contains(string-join($header),"application/vnd.google-earth.kmz") or $header = 'kml') then "kml"
    else if (contains(string-join($header),"application/geo+json") or $header = 'geojson') then "geojson"
    else if (contains(string-join($header),"text/plain") or $header = 'txt') then "txt"
    else if (contains(string-join($header),"application/pdf") or $header = 'pdf') then "pdf"
    else if (contains(string-join($header),"application/epub+zip") or $header = 'epub') then "epub"
    else "html"
};

declare function cntneg:determine-media-type($extension){
  switch($extension)
    case "rdf" return "application/rdf+xml"
    case "tei" return "application/tei+xml"
    case "tei" return "text/xml"
    case "atom" return "application/atom+xml"
    case "ttl" return "text/turtle"
    case "json" return "application/json"
    case "jsonld" return "application/ld+json"
    case "kml" return "application/vnd.google-earth.kmz"
    case "geojson" return "application/geo+json"
    case "txt" return "text/plain"
    case "pdf" return "application/pdf"
    case "epub" return "application/epub+zip"
    default return "text/html"
};

(: NOTE: not sure this is needed:)
declare function cntneg:determine-type-flag($extension){
  switch($extension)
    case "rdf" return "rdf"
    case "atom" return "atom"
    case "tei" return "xml"
    case "xml" return "xml"
    case "ttl" return "turtle"
    case "json" return "json"
    case "jsonld" return "jsonld"
    case "kml" return "kml"
    case "geojson" return "geojson"
    case "html" return "html"
    case "htm" return "html"
    case "txt" return "txt"
    case "text" return "txt"
    case "pdf" return "pdf"
    case "epub" return "epub"
    default return $extension
};
