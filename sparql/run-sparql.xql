xquery version "3.0";
(:
 : Run modules as needed
:)
import module namespace jsonld="http://syriaca.org/srophe/jsonld" at "../modules/content-negotiation/jsonld.xqm";
import module namespace sprql-queries="http://syriaca.org/sprql-queries" at "sparql.xqm";
import module namespace sparql-facets="http://syriaca.org/sparql-facets" at "sparql-facets.xqm";
import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";

(:declare namespace sparql="http://www.w3.org/2005/sparql-results#";:)
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $qname {request:get-parameter('qname', '')};
declare variable $id {request:get-parameter('id', '')};
declare variable $parameters {
    let $parameters :=  request:get-parameter-names()
    let $parameters := 
        <results>
           <parameters>{$parameters}</parameters>
           {for $parameter in $parameters
           return
           <parameter>
              <name>{$parameter}</name>
              <value>{request:get-parameter($parameter, '')}</value>
           </parameter>
           }
        </results>
    return $parameters
};

if(request:get-parameter('qname', '')) then
    let $query := if($qname = 'events-dates' or $qname = 'all-dates' or $qname = 'persons-dates' or $qname = 'relations-dates' or $qname = 'dates') then
                    sparql-facets:dates-facets($parameters)                    
                  else if($qname = 'facets') then
                    sparql-facets:build-sparql-facets($parameters)                    
                  else ()
    let $results := sparql:query($query)
    return  if(request:get-parameter('format', '') = ('json','JSON')) then              
            (response:set-header("Access-Control-Allow-Origin", "*"),
            response:set-header("Access-Control-Allow-Methods", "GET, POST"),
            response:set-header("Content-Type", "application/json"),
            jsonld:jsonld($results))
        else (response:set-header("Access-Control-Allow-Origin", "*"),
              response:set-header("Access-Control-Allow-Methods", "GET, POST"),
              $results)
else if(request:get-parameter('buildSPARQL', '') = 'true') then
    let $query := sparql-facets:build-sparql($parameters) 
    return let $results := sparql:query($query)
    return 
       if(request:get-parameter('format', '') = ('json','JSON')) then              
            (response:set-header("Access-Control-Allow-Origin", "*"),
            response:set-header("Access-Control-Allow-Methods", "GET, POST"),
            response:set-header("Content-Type", "application/json"),
            jsonld:jsonld($results))
        else (response:set-header("Access-Control-Allow-Origin", "*"),
              response:set-header("Access-Control-Allow-Methods", "GET, POST"),
              $results)
else if(request:get-parameter('sparql', '')) then
    let $results := sparql:query(request:get-parameter('sparql', ''))
    return 
        if(request:get-parameter('format', '') = ('json','JSON')) then              
            (response:set-header("Access-Control-Allow-Origin", "*"),
            response:set-header("Access-Control-Allow-Methods", "GET, POST"),
            response:set-header("Content-Type", "application/json"),
            jsonld:jsonld($results))
        else (response:set-header("Access-Control-Allow-Origin", "*"),
              response:set-header("Access-Control-Allow-Methods", "GET, POST"),
              $results)              
else if(request:get-parameter('query', '')) then 
    let $results := sparql:query(request:get-parameter('query', ''))
    return 
        if(request:get-parameter('format', '') = ('json','JSON')) then             
            (response:set-header("Access-Control-Allow-Origin", "*"),
            response:set-header("Access-Control-Allow-Methods", "GET, POST"),
            response:set-header("Content-Type", "application/json"),
            jsonld:jsonld($results))
        else
            (response:set-header("Access-Control-Allow-Origin", "*"),
            response:set-header("Access-Control-Allow-Methods", "GET, POST"),
            response:set-header("Content-Type", "text/xml"),
            $results)  
else if(not(empty(request:get-data()))) then
    let $results := sparql:query(request:get-data())
    return 
        if(request:get-parameter('format', '') = ('json','JSON')) then             
            (response:set-header("Access-Control-Allow-Origin", "*"),
            response:set-header("Access-Control-Allow-Methods", "GET, POST"),
            response:set-header("Content-Type", "application/json"),
            jsonld:jsonld($results))
        else
            (response:set-header("Access-Control-Allow-Origin", "*"),
            response:set-header("Access-Control-Allow-Methods", "GET, POST"),
            response:set-header("Content-Type", "text/xml"),
            $results)                   
else <message>No query data submitted</message>
