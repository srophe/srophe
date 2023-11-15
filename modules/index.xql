xquery version "3.1";

(:~ 
 : Build indexes for all facets and search fields in configuration files. 
 :)
 
import module namespace sf = "http://srophe.org/srophe/facets" at "lib/facets.xql";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


(response:set-header("Content-Type", "text/html; charset=utf-8"),
<span class="message">{
      try { 
            let $index := sf:update-index()
            return 'Your collection has been indexed!'
        } catch * {('error: ',concat($err:code, ": ", $err:description))}
}</span>)