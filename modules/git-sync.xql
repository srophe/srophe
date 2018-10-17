xquery version "3.1";

(:~ 
 : Webhook endpoint for Srophe Web Application 
 : XQuery endpoint to respond to Github webhook requests.  
 : The EXPath Crypto library supplies the HMAC-SHA1 algorithm for matching Github secret.  
 :
 : Secret can be stored as environmental variable.
 : Will need to be run with administrative privileges, suggest creating a git user with privileges only to relevant app.
 :
 : @Notes 
 : This module is for the PRODUCTION server and picks up calls from refs/heads/master
 : This version uses eXistdb's native JSON parser elminating the need for the xqjson library
 : 
 : Requirements 
 :  - EXPath Crypto library : http://expath.org/spec/crypto
 :  - eXist-db 3.0 or greater
 :  - access-config.xml file with github secret, or environment variable with secret. 
 :  - Must be run with elevated privileges: sm:chmod(xs:anyURI('/db/apps/srophe/modules/git-sync.xql'), "rwsr-xr-x")
 :
 : @author Winona Salesky
 : @version 2.0 
 : 
 : @see http://expath.org/spec/crypto 
 : @see http://expath.org/spec/http-client
 : 
 :)
 
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace templates="http://exist-db.org/xquery/templates" ;

(:import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";:)
import module namespace crypto="http://expath.org/ns/crypto";
import module namespace http="http://expath.org/ns/http-client";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";

(: Access git-api configuration file :) 
declare variable $git-config := if(doc('../access-config.xml')) then doc('../access-config.xml') else <response status="fail"><message>Load config.xml file please.</message></response>;

(: Private key for authentication :)
declare variable $private-key := if($git-config//private-key-variable != '') then 
                                    environment-variable($git-config//private-key-variable/text())
                                 else $git-config//private-key/text();

declare variable $gitToken := if($git-config//gitToken-variable != '') then 
                                    environment-variable($git-config//gitToken-variable/text())
                              else $git-config//gitToken/text();
(: eXist db collection location :)
declare variable $exist-collection := $git-config//exist-collection/text();

(: Github repository :)
declare variable $repo-name := $git-config//repo-name/text();

(:~  
 : Recursively creates new collections if necessary  
 : @param $uri url to resource being added to db 
 :)
declare function local:create-collections($uri as xs:string){
let $collection-uri := substring($uri,1)
for $collections in tokenize($collection-uri, '/')
let $current-path := concat('/',substring-before($collection-uri, $collections),$collections)
let $parent-collection := substring($current-path, 1, string-length($current-path) - string-length(tokenize($current-path, '/')[last()]))
return 
    if (xmldb:collection-available($current-path)) then ()
    else xmldb:create-collection($parent-collection, $collections)
};

declare function local:get-file-data($file-name, $contents-url){
let $url := concat($contents-url,'/',$file-name)         
let $raw-url := concat(replace(replace($contents-url,'https://api.github.com/repos/','https://raw.githubusercontent.com/'),'/contents','/master'),$file-name)            
return 
        http:send-request(<http:request http-version="1.1" href="{xs:anyURI($raw-url)}" method="get">
                            {if($gitToken != '') then
                                <http:header name="Authorization" value="{concat('token ',$gitToken)}"/>
                            else() }
                            <http:header name="Connection" value="close"/>
                        </http:request>)[2]
};

(:~
 : Updates files in eXistdb with github data 
 : @param $commits serilized json data
 : @param $contents-url string pointing to resource on github
:)
declare function local:do-update($commits as xs:string*, $contents-url as xs:string?){
    for $file in $commits
    let $file-name := tokenize($file,'/')[last()]
    let $file-data := 
        if(contains($file-name,'.xar')) then ()
        else local:get-file-data($file,$contents-url)
    let $resource-path := substring-before(replace($file,$repo-name,''),$file-name)
    let $exist-collection-url := xs:anyURI(replace(concat($exist-collection,'/',$resource-path),'/$',''))        
    return 
        try {
             if(contains($file-name,'.xar')) then ()
             else if(xmldb:collection-available($exist-collection-url)) then 
                <response status="okay">
                    <message>{xmldb:store($exist-collection-url, xmldb:encode-uri($file-name), $file-data)}</message>
                </response>
             else
                <response status="okay">
                    {(local:create-collections($exist-collection-url),xmldb:store($exist-collection-url, xmldb:encode-uri($file-name), $file-data))}
               </response>  
        } catch * {
        (response:set-status-code( 500 ),
            <response status="fail">
                <message>Failed to update resource {xs:anyURI(concat($exist-collection-url,'/',$file-name))}: {concat($err:code, ": ", $err:description)}</message>
            </response>)
        }
};

(:~
 : Adds new files to eXistdb. 
 : Pulls data from github repository, parses file information and passes data to xmldb:store
 : @param $commits serilized json data
 : @param $contents-url string pointing to resource on github
 : NOTE permission changes could happen in a db trigger after files are created
:)
declare function local:do-add($commits as xs:string*, $contents-url as xs:string?){
    for $file in $commits
    let $file-name := tokenize($file,'/')[last()]
    let $file-data := 
        if(contains($file-name,'.xar')) then ()
        else local:get-file-data($file,$contents-url)
    let $resource-path := substring-before(replace($file,$repo-name,''),$file-name)
    let $exist-collection-url := xs:anyURI(replace(concat($exist-collection,'/',$resource-path),'/$',''))
    return
        try {
             if(contains($file-name,'.xar')) then ()
             else if(xmldb:collection-available($exist-collection-url)) then 
                <response status="okay">
                    <message>{xmldb:store($exist-collection-url, xmldb:encode-uri($file-name), xs:base64Binary($file-data))}</message>
                </response>
             else
                <response status="okay">
                 {(local:create-collections($exist-collection-url),xmldb:store($exist-collection-url, xmldb:encode-uri($file-name), xs:base64Binary($file-data)))}
               </response>  
               } catch * {
               (response:set-status-code( 500 ),
            <response status="fail">
                <message>Failed to add resource {xs:anyURI(concat($exist-collection-url,$file-name))}: {concat($err:code, ": ", $err:description)}</message>
            </response>)
        }
};

(:~
 : Removes files from the database uses xmldb:remove
 : Pulls data from github repository, parses file information and passes data to xmldb:store
 : @param $commits serilized json data
 : @param $contents-url string pointing to resource on github
:)
declare function local:do-delete($commits as xs:string*, $contents-url as xs:string?){
    for $file in $commits
    let $file-name := tokenize($file,'/')[last()]
    let $resource-path := substring-before(replace($file,$repo-name,''),$file-name)
    let $exist-collection-url := xs:anyURI(replace(concat($exist-collection,'/',$resource-path),'/$',''))
    return
        if(contains($file-name,'.xar')) then ()
        else 
            try {
                <response status="okay">
                    <message>{xmldb:remove($exist-collection-url, $file-name)}</message>
                </response>
            } catch * {
            (response:set-status-code( 500 ),
                <response status="fail">
                    <message>Failed to remove resource {xs:anyURI(concat($exist-collection-url,$file-name))}: {concat($err:code, ": ", $err:description)}</message>
                </response>)
            }
   
};

(:~
 : Parse request data and pass to appropriate local functions
 : @param $json-data github response serializing as xml xqjson:parse-json()  
 :)
declare function local:parse-request($json-data as item()*){
let $contents-url := substring-before($json-data?repository?contents_url,'{')
return 
    try {
      (
            local:do-update(distinct-values($json-data?commits?*?modified?*), $contents-url),  
            local:do-add(distinct-values($json-data?commits?*?added?*), $contents-url),
            local:do-delete(distinct-values($json-data?commits?*?removed?*), $contents-url))   
    } catch * {
    (response:set-status-code( 500 ),
        <response status="fail">
            <message>Failed to parse JSON {concat($err:code, ": ", $err:description)}</message>
        </response>)
    }
};

(:~
 : Validate github post request.
 : Check user agent and github event, only accept push events from master branch.
 : Check git hook secret against secret stored in environmental variable
 : @param $GIT_TOKEN environment variable storing github secret
 :)

declare function local:execute-webhook($post-data){
if(not(empty($post-data))) then 
    let $payload := util:base64-decode($post-data)
    let $json-data := parse-json($payload)
    let $branch := if($git-config//github-branch/text() != '') then $git-config//github-branch/text() else 'refs/heads/master'
    return
        if($json-data?ref[. = $branch]) then 
             try {
                if(matches(request:get-header('User-Agent'), '^GitHub-Hookshot/')) then
                    if(request:get-header('X-GitHub-Event') = 'push') then 
                        let $signiture := request:get-header('X-Hub-Signature')
                        let $expected-result := <expected-result>{request:get-header('X-Hub-Signature')}</expected-result>
                        let $actual-result :=
                            <actual-result>
                                {crypto:hmac($payload, string($private-key), "HMAC-SHA-1", "hex")}
                            </actual-result>
                        let $condition := contains(normalize-space($expected-result/text()),normalize-space($actual-result/text()))                	
                        return
                            if ($condition) then 
                                local:parse-request($json-data)
            			    else 
            			     (response:set-status-code( 401 ),<response status="fail"><message>Invalid secret. </message></response>)
                    else (response:set-status-code( 401 ),<response status="fail"><message>Invalid trigger.</message></response>)
                else (response:set-status-code( 401 ),<response status="fail"><message>This is not a GitHub request.</message></response>)    
            } catch * {
                (response:set-status-code( 401 ),
                <response status="fail">
                    <message>Unacceptable headers {concat($err:code, ": ", $err:description)}</message>
                </response>)
            }
        else (response:set-status-code( 401 ),<response status="fail"><message>Not from the master branch.</message></response>)
else    
            (response:set-status-code( 401 ),
            <response status="fail">
                <message>No post data recieved</message>
            </response>)   
};

let $post-data := request:get-data()
return local:execute-webhook($post-data)
    