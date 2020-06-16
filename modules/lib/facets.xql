xquery version "3.1";

module namespace sf = "http://srophe.org/srophe/facets";
import module namespace functx="http://www.functx.com";
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";

declare namespace srophe="https://srophe.app";
declare namespace facet="http://expath.org/ns/facet";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $sf:QUERY_OPTIONS := map {
    "leading-wildcard": "yes",
    "filter-rewrite": "yes"
};

(: ~ 
 : Build indexes for fields and facets as specified in facet-def.xml and search-config.xml files
 : Note: Investigate boost? 
:)
declare function sf:build-index(){
<index xmlns="http://exist-db.org/collection-config/1.0" xmlns:tei="http://www.tei-c.org/ns/1.0">
    <lucene diacritics="no">
        <module uri="http://srophe.org/srophe/facets" prefix="sf" at="xmldb:exist:///{$config:app-root}/modules/lib/facets.xql"/>
        <text qname="tei:body">{
        let $facets :=     
            for $f in collection($config:app-root)//facet:facet-definition
            let $path := document-uri(root($f))
            group by $facet-grp := $f/@name
            return 
                if($f[1]/facet:group-by/@function != '') then 
                   <facet dimension="{functx:words-to-camel-case($facet-grp)}" expression="sf:facet(descendant-or-self::tei:body, {concat("'",$path[1],"'")}, {concat("'",$facet-grp,"'")})"/>
                else 
                    <facet dimension="{functx:words-to-camel-case($facet-grp)}" expression="{replace($f[1]/facet:group-by/facet:sub-path/text(),"&#34;","'")}"/>
        let $fields := 
            for $f in collection($config:app-root)//*:search-config/*:field
            let $path := document-uri(root($f))
            group by $field-grp := $f/@name
            where $field-grp != 'keyword' and  $field-grp != 'fullText'
            return 
                if($f[1]/@function != '') then 
                    <field name="{functx:words-to-camel-case($field-grp)}" expression="sf:field(descendant-or-self::tei:body, {concat("'",$path[1],"'")}, {concat("'",$field-grp,"'")})"/>
                else 
                    <field name="{functx:words-to-camel-case($field-grp)}" expression="{string($f[1]/@expression)}"/>
        return 
            ($facets,$fields)
        }
        <!--<ignore qname="tei:body"/>-->
        </text>
        <text qname="tei:fileDesc"/>
        <text qname="tei:biblStruct"/>
        <text qname="tei:div"/>
        <text qname="tei:author" boost="2.0"/>
        <text qname="tei:persName" boost="2.0"/>
        <text qname="tei:placeName" boost="2.0"/>
        <text qname="tei:title" boost="2.5"/>
        <text qname="tei:location"/>
        <text qname="tei:desc" boost="1.0"/>
        <text qname="tei:event"/>
        <text qname="tei:note"/>
        <text qname="tei:term"/>
    </lucene> 
    <range>
        <create qname="@syriaca-computed-start" type="xs:date"/>
        <create qname="@syriaca-computed-end" type="xs:date"/>
        <create qname="@type" type="xs:string"/>
        <create qname="@ana" type="xs:string"/>
        <create qname="@syriaca-tags" type="xs:string"/>
        <create qname="@when" type="xs:string"/>
        <create qname="@target" type="xs:string"/>
        <create qname="@who" type="xs:string"/>
        <create qname="@ref" type="xs:string"/>
        <create qname="@uri" type="xs:string"/>
        <create qname="@where" type="xs:string"/>
        <create qname="@active" type="xs:string"/>
        <create qname="@passive" type="xs:string"/>
        <create qname="@mutual" type="xs:string"/>
        <create qname="@name" type="xs:string"/>
        <create qname="@xml:lang" type="xs:string"/>
        <create qname="@status" type="xs:string"/>
        <create qname="tei:idno" type="xs:string"/>
        <create qname="tei:title" type="xs:string"/>
        <create qname="tei:geo" type="xs:string"/>
        <create qname="tei:relation" type="xs:string"/>
        <create qname="tei:persName" type="xs:string"/>
        <create qname="tei:placeName" type="xs:string"/>
        <create qname="tei:author" type="xs:string"/>
    </range>
</index>
};

(: Update collection.xconf file for data application, can be called by post install script, or index.xql :)
declare function sf:update-index(){
  try {
        let $indexFile := doc(concat('/db/system/config',replace($config:data-root,'/data',''),'/collection.xconf'))
        return 
            (update replace $indexFile//*:index with sf:build-index(), xmldb:reindex($config:data-root))
    } catch * {('error: ',concat($err:code, ": ", $err:description))}
};

(: Main facet function, for generic facets :)

(: Build facet path based on facet definition file. Used by collection.xconf to build facets at index time. 
 : @param $path - path to facet definition file, if empty assume root.
 : @param $name - name of facet in facet definition file. 
 :
 : TODO: test custom facets/fields
:)
declare function sf:facet($element as item()*, $path as xs:string, $name as xs:string){
    let $facet-definition :=  
        if(doc-available($path)) then
            doc($path)//facet:facet-definition[@name=$name]
        else () 
    let $xpath := $facet-definition/facet:group-by/facet:sub-path/text()    
    return 
        if(not(empty($facet-definition))) then  
            if($facet-definition/facet:group-by/@function != '') then 
              try { 
                    util:eval(concat('sf:facet-',string($facet-definition/facet:group-by/@function),'($element,$facet-definition, $name)'))
                } catch * {concat($err:code, ": ", $err:description)}
            else util:eval(concat('$element/',$xpath))
        else ()
};

declare function sf:field($element as item()*, $path as xs:string, $name as xs:string){
    let $field-definition :=  
        if(doc-available($path)) then
            doc($path)//*:field[@name=$name]
        else () 
    let $xpath := $field-definition/*:expression/text()    
    return 
        if(not(empty($field-definition))) then  
            if($field-definition/@function != '') then 
                try { 
                    util:eval(concat('sf:field-',string($field-definition/@function),'($element,$field-definition, $name)'))
                } catch * {concat($err:code, ": ", $err:description)}
            else util:eval(concat('$element/',$xpath)) 
        else ()  
};

(: Custom search fields :)
(: Could be just shortened to  tokenize(util:eval(concat('$element/',$xpath)),' ')  do not need to group for Lucene facets i think?:)
declare function sf:facet-group-by-array($element as item()*, $facet-definition as item(), $name as xs:string){
    let $xpath := $facet-definition/facet:group-by/facet:sub-path/text()    
    return tokenize(util:eval(concat('$element/',$xpath)),' ') 
};
(: Fit values into a specified range 
example: 
    <range type="xs:year">
        <bucket lt="0001" name="BC dates" order="22"/>
        <bucket gt="1600-01-01" lt="1700-01-01" name="1600-1700" order="5"/>
        <bucket gt="1700-01-01" lt="1800-01-01" name="1700-1800" order="4"/>
        <bucket gt="1800-01-01" lt="1900-01-01" name="1800-1900" order="3"/>
        <bucket gt="1900-01-01" lt="2000-01-01" name="1900-2000" order="2"/>
        <bucket gt="2000-01-01" name="2000 +" order="1"/>
    </range>
:)
declare function sf:facet-range($element as item()*, $facet-definition as item(), $name as xs:string){
    let $range := $facet-definition/facet:range 
    for $r in $range/facet:bucket
    let $path := if($r/@lt and $r/@lt != '' and $r/@gt and $r/@gt != '') then
                    concat('$element/',$facet-definition/descendant::facet:sub-path/text(),'[. >= "', sf:type($r/@gt, $range/@type),'" and . <= "',sf:type($r/@lt, $range/@type),'"]')
                 else if($r/@lt and $r/@lt != '' and (not($r/@gt) or $r/@gt ='')) then 
                    concat('$element/',$facet-definition/descendant::facet:sub-path/text(),'[. <= "',sf:type($r/@lt, $range/@type),'"]')
                 else if($r/@gt and $r/@gt != '' and (not($r/@lt) or $r/@lt ='')) then 
                    concat('$element/',$facet-definition/descendant::facet:sub-path/text(),'[. >= "', sf:type($r/@gt, $range/@type),'"]')
                 else if($r/@eq) then
                    concat('$element/',$facet-definition/descendant::facet:sub-path/text(),'[', $r/@eq ,']')
                 else ()
    let $f := util:eval($path)
    return if($f) then $r/@name else()
    
};

declare function sf:facet-range-display($element as item()*, $facet-definition as item(), $name as xs:string){
    'placeHolder'    
};

(: Title field :)
declare function sf:field-title($element as item()*, $facet-definition as item(), $name as xs:string){
    if($element/descendant-or-self::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang='en']) then 
        let $en := $element/descendant-or-self::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang='en'][1]
        let $syr := string-join($element/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]//text(),' ')
        return sf:build-sort-string(concat($en, if($syr != '') then  concat(' - ', $syr) else ()))
    else if($element/descendant-or-self::*[contains(@srophe:tags,'#headword')][@xml:lang='en']) then
        let $en := $element/descendant-or-self::*[contains(@srophe:tags,'#headword')][@xml:lang='en'][1]
        let $syr := string-join($element/descendant::*[contains(@srophe:tags,'#headword')][matches(@xml:lang,'^syr')][1]//text(),' ')
        return sf:build-sort-string(concat($en, if($syr != '') then  concat(' - ', $syr) else ()))
    else if($element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct) then 
        sf:build-sort-string($element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct/descendant::tei:title)
    else sf:build-sort-string($element/ancestor-or-self::tei:TEI/descendant::tei:titleStmt/tei:title)
};

(: Title field :)
declare function sf:facet-title($element as item()*, $facet-definition as item(), $name as xs:string){
    if($element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct) then 
        $element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct/descendant::tei:title
    else $element/ancestor-or-self::tei:TEI/descendant::tei:titleStmt/tei:title
};

(: Author field :)
declare function sf:field-author($element as item()*, $facet-definition as item(), $name as xs:string){
    if($element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct) then 
        $element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct/descendant::tei:author | $element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct/descendant::tei:editor
    else $element/ancestor-or-self::tei:TEI/descendant::tei:titleStmt/descendant::tei:author
};

(: Author field :)
declare function sf:facet-authors($element as item()*, $facet-definition as item(), $name as xs:string){
    if($element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct) then 
        $element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct/descendant::tei:author | $element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct/descendant::tei:editor
    else $element/ancestor-or-self::tei:TEI/descendant::tei:titleStmt/descendant::tei:author
};

declare function sf:facet-biblAuthors($element as item()*, $facet-definition as item(), $name as xs:string){
    if($element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct) then 
        $element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct/descendant::tei:author | $element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct/descendant::tei:editor
    else $element/ancestor-or-self::tei:TEI/descendant::tei:titleStmt/descendant::tei:author
};

(: Syriaca.org special facet :)
declare function sf:facet-type($element as item()*, $facet-definition as item(), $name as xs:string){
    if($element/descendant-or-self::tei:place/@type) then
        lower-case($element/descendant-or-self::tei:place/@type)    
    else if($element/descendant-or-self::tei:person/@ana) then
        tokenize(lower-case($element/descendant-or-self::tei:person/@ana),' ')
    else ()
};

declare function sf:field-type($element as item()*, $facet-definition as item(), $name as xs:string){
    if($element/descendant-or-self::tei:place/@type) then
        lower-case($element/descendant-or-self::tei:place/@type)    
    else if($element/descendant-or-self::tei:person/@ana) then
        tokenize(lower-case($element/descendant-or-self::tei:person/@ana),' ')
    else ()
};

declare function sf:field-idno($element as item()*, $facet-definition as item(), $name as xs:string){
    $element/descendant-or-self::tei:idno[@type='URI'][starts-with(.,$config:base-uri)]    
};

declare function sf:field-uri($element as item()*, $facet-definition as item(), $name as xs:string){
    $element/descendant-or-self::tei:idno[@type='URI'][starts-with(.,$config:base-uri)]    
};

declare function sf:facet-controlled-labels($element as item()*, $facet-definition as item(), $name as xs:string){
    let $xpath := $facet-definition/facet:group-by/facet:sub-path/text() 
    return util:eval(concat('$element/',$xpath))
};

(: Display, output functions 
request:get-parameter-names()[starts-with(., 'facet-')]
request:get-parameter('start', 1) 
:)
declare function sf:display($result as item()*, $facet-definition as item()*) {
    for $facet in $facet-definition//facet:facet-definition
    let $name := string($facet/@name)
    let $count := if(request:get-parameter(concat('all-',$name), '') = 'on' ) then () else string($facet/facet:max-values/@show)
    let $f := ft:facets($result, $name, $count)
    let $sort := $facet-definition/facet:order-by
    return 
        if (map:size($f) > 0) then
            <span class="facet-grp">
                <span class="facet-title">{string($facet/@label)}</span>
                <span class="facet-list">
                {array:for-each(sf:sort($f), function($entry) {
                    map:for-each($entry, function($label, $freq) {
                        let $param-name := concat('facet-',$name)
                        let $facet-param := concat($param-name,'=',$label)
                        let $active := if(request:get-parameter($param-name, '') = $label) then 'active' else ()
                        let $url-params := 
                            if($active) then replace(replace(replace(request:get-query-string(),encode-for-uri($label),''),concat($param-name,'='),''),'&amp;&amp;','&amp;') 
                            else concat($facet-param,'&amp;',request:get-query-string())
                        return
                            <a href="?{$url-params}" class="facet-label btn btn-default {$active}">
                            {if($active) then (<span class="glyphicon glyphicon-remove facet-remove"></span>)else ()}
                            {$label} <span class="count"> ({$freq})</span> </a>
                    })
                })}
                {if(map:size($f) = xs:integer($count)) then 
                    <a href="?{request:get-query-string()}&amp;all-{$name}=on" class="facet-label btn btn-info"> View All </a>
                 else ()}
                </span>
            </span>
        else ()  
};

(:~ 
 : Add sort option to facets 
 : Work in progress, need to pass sort options from facet-definitions to sort function.
:)
declare function sf:sort($facets as map(*)?) {
    array {
        if (exists($facets)) then
            for $key in map:keys($facets)
            let $value := map:get($facets, $key)
            order by $key ascending
            return
                map { $key: $value }
        else
            ()
    }
};

(:~
 : Build map for search query
 : Used by search functions
 :)
declare function sf:facet-query() {
    map:merge((
        $sf:QUERY_OPTIONS,
        map {
            "facets":
                map:merge((
                    for $param in request:get-parameter-names()[starts-with(., 'facet-')]
                    let $dimension := substring-after($param, 'facet-')
                    return
                        map {
                            $dimension: request:get-parameter($param, ())
                        }
                ))
        }
    ))
};


(:~
 : Adds type casting when type is specified facet:facet:group-by/@type
 : @param $value of xpath
 : @param $type value of type attribute
:)
declare function sf:type($value as item()*, $type as xs:string?) as item()*{
    if($type != '') then  
        if($type = 'xs:string') then xs:string($value)
        else if($type = 'xs:string') then xs:string($value)
        else if($type = 'xs:decimal') then xs:decimal($value)
        else if($type = 'xs:integer') then xs:integer($value)
        else if($type = 'xs:long') then xs:long($value)
        else if($type = 'xs:int') then xs:int($value)
        else if($type = 'xs:short') then xs:short($value)
        else if($type = 'xs:byte') then xs:byte($value)
        else if($type = 'xs:float') then xs:float($value)
        else if($type = 'xs:double') then xs:double($value)
        else if($type = 'xs:dateTime') then xs:dateTime($value)
        else if($type = 'xs:date') then xs:date($value)
        else if($type = 'xs:gYearMonth') then xs:gYearMonth($value)        
        else if($type = 'xs:gYear') then xs:gYear($value)
        else if($type = 'xs:gMonthDay') then xs:gMonthDay($value)
        else if($type = 'xs:gMonth') then xs:gMonth($value)        
        else if($type = 'xs:gDay') then xs:gDay($value)
        else if($type = 'xs:duration') then xs:duration($value)        
        else if($type = 'xs:anyURI') then xs:anyURI($value)
        else if($type = 'xs:Name') then xs:Name($value)
        else $value
    else $value
};

(: Syriaca.org strip non sort characters :)
declare function sf:build-sort-string($titlestring as xs:string?) as xs:string* {
    replace(normalize-space($titlestring),'^\s+|^[‘|ʻ|ʿ|ʾ]|^[tT]he\s+[^\p{L}]+|^[dD]e\s+|^[dD]e-|^[oO]n\s+[aA]\s+|^[oO]n\s+|^[aA]l-|^[aA]n\s|^[aA]\s+|^\d*\W|^[^\p{L}]','')
};
