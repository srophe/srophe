xquery version "3.1";

(:~ 
 : Webhook endpoint for Srophe Web Application 
 : XQuery endpoint to respond to Github webhook requests.  
 : 
 : Requirements
 :  - githubxq library : http://exist-db.org/lib/githubxq 
 :  - EXPath Crypto library : http://expath.org/spec/crypto
 :  - eXist-db 3.0 or greater 
 :  - Must be run with elevated privileges: sm:chmod(xs:anyURI('/db/apps/srophe/modules/git-sync.xql'), "rwsr-xr-x")
 :
 : @author Winona Salesky
 : @version 2.0 
 :)
 
import module namespace githubxq="http://exist-db.org/lib/githubxq";

(:~
 : Path to eXist-db application.
 :)
declare variable $local:db-application-path := "/db/apps/${package-target}";
(:~
 : GitHub repository.
 :)
declare variable $local:git-repo := "${git-repo-url}";
(:~
 : GitHub branch to get data from.
 :)
declare variable $local:git-branch := "${git-branch}";
(:~
 : Private key for GitHub authentication.
 : See: https://developer.github.com/webhooks/securing/
 :)
declare variable $local:github-private-key := "${github-private-key}";
(:~
 : Git Token used for rate limiting.
 : See: https://developer.github.com/v3/#rate-limiting
 :)
 declare variable $local:github-rate-limit-token :=  "";

let $data := request:get-data()
return
    githubxq:execute-webhook($data,
        $local:db-application-path,
        $local:git-repo,
        $local:git-branch,
        $local:github-private-key,
        $local:github-rate-limit-token)