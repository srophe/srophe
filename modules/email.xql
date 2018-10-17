xquery version "3.1";

(:~
 : Build email form returns. error or sucess message to ajax function.
 : Use reCaptcha to filter out spam. 
 :)
import module namespace config="http://syriaca.org/srophe/config" at "config.xqm";
import module namespace http="http://expath.org/ns/http-client";
declare namespace httpclient = "http://exist-db.org/xquery/httpclient";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mail="http://exist-db.org/xquery/mail";
declare namespace request="http://exist-db.org/xquery/request";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";

declare variable $VALIDATE_URI as xs:anyURI := xs:anyURI("https://www.google.com/recaptcha/api/siteverify");

(: Get reCaptcha private key for authentication :)
declare variable $secret-key := if($config:get-access-config//*:recaptcha-secret-key-variable != '') then 
                                    environment-variable($config:get-access-config//*:recaptcha-secret-key-variable/text())
                                 else $config:get-access-config//*:recaptcha-secret-key/text();
 
(: Validate reCaptcha :)
declare function local:recaptcha() {
    let $client-ip := request:get-header("X-Real-IP")
    let $response := http:send-request(<http:request http-version="1.1" href="{xs:anyURI(concat($VALIDATE_URI,
                                            '?secret=',string($secret-key),
                                            '&amp;response=',request:get-parameter("g-recaptcha-response",()),
                                            '&amp;remoteip=',$client-ip))}" method="post">
                                        </http:request>)[2]
    let $payload := util:base64-decode($response)
    let $json-data := parse-json($payload)
    return 
        if($json-data?success = true()) then true()
        else false()  
};

declare function local:email-list(){
let $list := 
    if(request:get-parameter('formID','') != '') then 
        request:get-parameter('formID','') 
    else if(request:get-parameter('collection','') != '') then 
        request:get-parameter('collection','') 
    else ()
return 
if($list != '') then 
    if($config:get-access-config/descendant::contact[@listID =  $list]) then 
        for $contact in $config:get-access-config/descendant::contact[@listID =  $list]/child::*
        return element { fn:local-name($contact) } {$contact/text()}
    else 
        for $contact in $config:get-access-config/descendant::contact[1]/child::*
        return element { fn:local-name($contact) } {$contact/text()}
else 
    for $contact in $config:get-access-config/descendant::contact[1]/child::*
    return 
         element { fn:local-name($contact) } {$contact/text()}
};

declare function local:build-message(){
let $rec-uri := if(request:get-parameter('id','')) then concat('for ',request:get-parameter('id','')) else ()
return
    <mail>
    <from>{$config:app-title} &#160;{concat('&lt;',$config:get-access-config//*:contact[not(@listID)]/child::*[1]//text(),'&gt;')}</from>
    {local:email-list()}
    <subject>{request:get-parameter('subject','')}&#160; {$rec-uri}</subject>
    <message>
      <xhtml>
           <html xmlns="http://www.w3.org/1999/xhtml">
               <head>
                 <title>{request:get-parameter('subject','')}</title>
               </head>
               <body>
                 <p>Name: {request:get-parameter('name','')}</p>
                 <p>e-mail: {request:get-parameter('email','')}</p>
                 <p>Subject: {request:get-parameter('subject','')}&#160; {$rec-uri}</p>
                 <p>{$rec-uri}</p>
                 <p>{request:get-parameter('comments','')}</p>
              </body>
           </html>
      </xhtml>
    </message>
  </mail>
};

let $cache := current-dateTime()
let $smtp := if($config:get-access-config//*:smtp/text() != '') then $config:get-access-config//*:smtp/text() else ()
return 
    if(exists(request:get-parameter('email','')) and request:get-parameter('email','') != '')  then 
        if(exists(request:get-parameter('comments','')) and request:get-parameter('comments','') != '') then 
            if($secret-key != '') then
                if(local:recaptcha() = true()) then 
                   let $mail := local:build-message()
                   return 
                       if(mail:send-email($mail,$smtp, ()) ) then
                           <h4>Thank you. Your message has been sent.</h4>
                       else
                           <h4>Could not send message.</h4>
                else 'Recaptcha fail'
            else 
                let $mail := local:build-message()
                return 
                    if(mail:send-email($mail,$smtp, ()) ) then
                       <h4>Thank you. Your message has been sent.</h4>
                    else
                       <h4>Could not send message.</h4>
        else  <h4>Incomplete form.</h4>
   else  <h4>Incomplete form.</h4>