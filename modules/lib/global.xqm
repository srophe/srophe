xquery version "3.1";
(: Global Srophe helper functions. :)
module namespace global="http://syriaca.org/srophe/global";

import module namespace http="http://expath.org/ns/http-client" at "java:org.exist.xquery.modules.httpclient.HTTPClientModule";

(: Import Srophe application modules. :)
import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";

(:~
 : Transform tei to html via xslt
 : @param $node data passed to transform
:)
declare function global:tei2html($nodes as node()*) {
  transform:transform($nodes, doc($config:app-root || '/resources/xsl/tei2html.xsl'), 
    <parameters>
        <param name="data-root" value="{$config:data-root}"/>
        <param name="app-root" value="{$config:app-root}"/>
        <param name="nav-base" value="{$config:nav-base}"/>
        <param name="base-uri" value="{$config:base-uri}"/>
    </parameters>
    )
};

(:~
 : Configure dropdown menu for keyboard layouts for input boxes
 : Options are defined in repo-config.xml
 : @param $input-id input id used by javascript to select correct keyboard layout.  
 :)
declare function global:keyboard-select-menu($input-id as xs:string){
    if($config:get-config//repo:keyboard-options/child::*) then 
        <span class="keyboard-menu">
            <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
            </button>
            <ul xmlns="http://www.w3.org/1999/xhtml" class="dropdown-menu">
                {
                for $layout in $config:get-config//repo:keyboard-options/repo:option
                return  
                    <li xmlns="http://www.w3.org/1999/xhtml"><a href="#" class="keyboard-select" id="{$layout/@id}" data-keyboard-id="{$input-id}">{$layout/text()}</a></li>
                }
            </ul>
        </span>
    else ()       
};

(:~
 : Get facet-definition file if it exists. 
:)
declare function global:facet-definition-file($collection as xs:string?){
    let $facet-config-file := 'facet-def.xml'
    let $facet-config := 
        if($collection != '') then 
            concat($config:app-root, '/', string(config:collection-vars($collection)/@app-root),'/',$facet-config-file) 
        else concat($config:app-root,'/',$facet-config-file)
    return 
        if(doc-available($facet-config)) then
            doc($facet-config)
        else ()
};

(:
 : Uses Srophe ODD file to establish labels for various ouputs. Returns blank if there is no matching definition in the ODD file.
 : Pass in ODD file from repo.xml 
 : example: global:odd2text($rec/descendant::tei:bibl[1],string($rec/descendant::tei:bibl[1]/@type))
:)
declare function global:odd2text($element as xs:string?, $label as xs:string?) as xs:string* {
    let $odd-path := $config:get-config//repo:odd/text()
    let $odd-file := 
                    if($odd-path != '') then
                        if(starts-with($odd-path,'http')) then 
                            http:send-request(<http:request href="{xs:anyURI($odd-path)}" method="get"/>)[2]
                        else doc($config:app-root || $odd-path)
                    else ()
    return 
        if($odd-path != '') then
            let $odd := $odd-file
            return 
                try {
                    if($odd/descendant::*[@ident = $element][1]/descendant::tei:valItem[@ident=$label][1]/tei:gloss[1]/text()) then 
                        $odd/descendant::*[@ident = $element][1]/descendant::tei:valItem[@ident=$label][1]/tei:gloss[1]/text()
                    else if($odd/descendant::tei:valItem[@ident=$label][1]/tei:gloss[1]/text()) then 
                        $odd/descendant::tei:valItem[@ident=$label][1]/tei:gloss[1]/text()
                    else ()    
                } catch * {
                    <error>Caught error {$err:code}: {$err:description}</error>
                }  
         else ()
};

(:~
 : Strips English title or sort string of non-sort characters as established by Syriaca.org
 : Used for alphabetizing in search/browse and elsewhere
 : @param $titlestring 
 : @param $lang   
 :)
declare function global:build-sort-string($titlestring as xs:string?, $lang as xs:string?) as xs:string* {
    if($lang = 'ar') then global:ar-sort-string($titlestring)
    else replace(normalize-space($titlestring),'^\s+|^[‘|ʻ|ʿ|ʾ]|^[tT]he\s+[^\p{L}]+|^[dD]e\s+|^[dD]e-|^[oO]n\s+[aA]\s+|^[oO]n\s+|^[aA]l-|^[aA]n\s|^[aA]\s+|^\d*\W|^[^\p{L}]','')
};

(:~
 : Strips Arabic titles of non-sort characters as established by Syriaca.org
 : @note: This code normalizes for alphabetization the most common cases, data uses rare Arabic glyphs such as those in the range U0674-U06FF, further normalization may be needed
 : Used for alphabetizing
 : @param $titlestring 
 :)
declare function global:ar-sort-string($titlestring as xs:string?) as xs:string* {
replace(
    replace(
      replace(
        replace(
          replace($titlestring,'^\s+',''), (:remove leading spaces. :)
            '[ً-ٖ]',''), (:remove vowels and diacritics :)
                '(^|\s)(ال|أل|ٱل)',''), (: remove all definite articles :)
                    'آ|إ|أ|ٱ','ا'), (: normalize letter alif :)
                        '^(ابن|إبن|بن)','') (:remove all forms of (ابن) with leading space :)
};

(:~
 : Matches English letters and their equivalent letters as established by Syriaca.org
 : @param $data:sort indicates letter for browse
 :)
declare function global:get-alpha-filter(){
let $sort := request:get-parameter('alpha-filter', '')
return 
        if(request:get-parameter('lang', '') = 'ar') then
            global:ar-sort()
        else if(request:get-parameter('lang', '') = 'en' or request:get-parameter('lang', '') = '') then
            if($sort = 'A' or $sort = '') then '^(A|a|ẵ|Ẵ|ằ|Ằ|ā|Ā)'
            else if($sort = 'D') then '^(D|d|đ|Đ)'
            else if($sort = 'S') then '^(S|s|š|Š|ṣ|Ṣ)'
            else if($sort = 'E') then '^(E|e|ễ|Ễ)'
            else if($sort = 'U') then '^(U|u|ū|Ū)'
            else if($sort = 'H') then '^(H|h|ḥ|Ḥ)'
            else if($sort = 'T') then '^(T|t|ṭ|Ṭ)'
            else if($sort = 'I') then '^(I|i|ī|Ī)'
            else if($sort = 'O') then '^(O|Ō|o|Œ|œ)'
            else concat('^(',$sort,')')
        else concat('^(',$sort,')')    
};

(:~
 : Matches Arabic letters and their equivalent letters as established by Syriaca.org
 :)
declare function global:ar-sort(){
let $sort := request:get-parameter('alpha-filter', '')
return 
    if($sort = 'ٱ') then '^(ٱ|ا|آ|أ|إ)'
        else if($sort = 'ٮ') then '^(ٮ|ب)'
        else if($sort = 'ة') then '^(ة|ت)'
        else if($sort = 'ڡ') then '^(ڡ|ف)'
        else if($sort = 'ٯ') then '^(ٯ|ق)'
        else if($sort = 'ں') then '^(ں|ن)'
        else if($sort = 'ھ') then '^(ھ|ه)'
        else if($sort = 'ۈ') then '^(ۈ|ۇ|ٷ|ؤ|و)'
        else if($sort = 'ى') then '^(ى|ئ|ي)'
        else concat('^(',$sort,')')
};

(:~ 
 : Expand dates to make iso dates YYYY-MM-DD 
 :)
declare function global:make-iso-date($date as xs:string?) as xs:date* {
xs:date(
    if($date = '0-100') then '0001-01-01'
    else if($date = '2000-') then '2100-01-01'
    else if(matches($date,'\d{4}')) then concat($date,'-01-01')
    else if(matches($date,'\d{3}')) then concat('0',$date,'-01-01')
    else if(matches($date,'\d{2}')) then concat('00',$date,'-01-01')
    else if(matches($date,'\d{1}')) then concat('000',$date,'-01-01')
    else '0100-01-01')
};

(:~ 
 : Parse persNames to take advantage of sort attribute in display. 
 : Returns a sorted string
 : @param $name persName element 
 :)
declare function global:parse-name($name as node()*) as xs:string* {
if($name/child::*) then 
    string-join(for $part in $name/child::*
    order by $part/@sort ascending, string-join($part/descendant-or-self::text(),' ') descending
    return $part/text(),' ')
else $name/text()
};

(: Architectura Sinica functions :)
(:~
 : Syriaca.org specific function to label URI's with human readable labels. 
 : @param $uri Syriaca.org uri to be used for lookup. 
 : URI can be a record or a keyword
 : NOTE: this function will probably slow down the facets.
:)
declare function global:get-label($uri as item()*){
if(starts-with($uri,$config:base-uri)) then  
      let $doc := collection($config:data-root)//tei:idno[@type='URI'][. = concat($uri,"/tei")]
      return 
          if(exists($doc)) then
            string-join($doc/ancestor::tei:TEI//tei:titleStmt[1]/tei:title[1]/text()[1],' ')
          else $uri 
else $uri
};