xquery version "3.1";

(:~ 
 : Build indexes for all facets and search fields in configuration files. 
 :)
 
import module namespace sf = "http://srophe.org/srophe/facets" at "lib/facets.xql";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

sf:update-index()
(:sf:build-index():)

