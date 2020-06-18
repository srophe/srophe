xquery version "3.1";
(:~ 
 : Srophe facets v2.0 
 : Removes in memory nodes created by orginal 
 : 
 : Uses the following eXist-db specific functions:
 :      util:eval 
 :      request:get-parameter
 :      request:get-parameter-names()
 : 
 : @author Winona Salesky
 : @version 2.0 
 :
 : @see http://expath.org/spec/facet   
   @Note:  no longer matches spec. 
 : Spec builds in memory nodes and causes very poor performance.
 : See v1.0 for more spec compliant version 
 :)
 
module namespace facet = "http://expath.org/ns/facet";
import module namespace global="http://srophe.org/srophe/global" at "global.xqm";
import module namespace functx="http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: External facet parameters :)
declare variable $facet:fq {request:get-parameter('fq', '') cast as xs:string};

(:~
 : XPath filter to be passed to main query
 : creates XPath based on facet:facet-definition//facet:sub-path.
 : @param $facet-def facet:facet-definition element
:)
declare function facet:facet-filter($facet-definitions as node()*)  as item()*{
    if($facet:fq != '') then 
       string-join(
        for $facet in tokenize($facet:fq,';fq-')
        let $facet-name := substring-before($facet,':')
        let $facet-value := normalize-space(substring-after($facet,':'))
        return 
            for $facet in $facet-definitions/descendant-or-self::facet:facet-definition[@name = $facet-name]
            let $path := 
                         if(matches($facet/facet:sub-path/text(), '^/@')) then 
                            concat('descendant::*/',substring($facet/facet:group-by/facet:sub-path/text(),2))
                         else $facet/facet:group-by/facet:sub-path/text()                
            return 
                if($facet-value != '') then 
                    if($facet/facet:range) then
                        if($facet/facet:group-by[@function='facet:keywordType']) then
                           concat('[',$facet/facet:range/facet:bucket[@name = $facet-value]/@path,']')
                        else if($facet/facet:range/facet:bucket[@name = $facet-value]/@lt and $facet/facet:range/facet:bucket[@name = $facet-value]/@lt != '') then
                            concat('[',$path,'[string(.) >= "', facet:type($facet/facet:range/facet:bucket[@name = $facet-value]/@gt, $facet/facet:range/facet:bucket[@name = $facet-value]/@type),'" and string(.) <= "',facet:type($facet/facet:range/facet:bucket[@name = $facet-value]/@lt, $facet/facet:range/facet:bucket[@name = $facet-value]/@type),'"]]')                        
                        else if($facet/facet:range/facet:bucket[@name = $facet-value]/@eq and $facet/facet:range/facet:bucket[@name = $facet-value]/@eq != '') then
                            concat('[',$path,'[', $facet/facet:range/facet:bucket[@name = $facet-value]/@eq ,']]')
                        else concat('[',$path,'[string(.) >= "', facet:type($facet/facet:range/facet:bucket[@name = $facet-value]/@gt, $facet/facet:range/facet:bucket[@name = $facet-value]/@type),'" ]]')
                    else if($facet/facet:group-by[@function="facet:group-by-array"]) then 
                        concat('[',$path,'[matches(., "',$facet-value,'(\W|$)")]',']')                     
                    else concat('[',$path,'[normalize-space(.) = "',replace($facet-value,'"','""'),'"]',']')
                else()
        ,'')
    else  ()  
};

(:~
 : Adds type casting when type is specified facet:facet:group-by/@type
 : @param $value of xpath
 : @param $type value of type attribute
:)
declare function facet:type($value as item()*, $type as xs:string?) as item()*{
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

(: Print facet results to HTML page :)
declare function facet:output-html-facets($results as item()*, $facet-definitions as element(facet:facet-definition)*) as item()*{
<div class="facets">
    {   
    for $facet in $facet-definitions
    return 
        <div class="facetDefinition">
            {for $facets at $i in facet:facet($results, $facet)
             return $facets}
        </div>
    }
</div>
};

(:~
 : Pass facet definition to correct XQuery function;
 : Range, User defined function or default group-by function
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
 : TODO: Handle nested facet-definition
:) 
declare function facet:facet($results as item()*, $facet-definitions as element(facet:facet-definition)?) as item()*{
    if($facet-definitions/facet:group-by/@function) then
        util:eval(concat($facet-definitions/facet:group-by/@function,'($results,$facet-definitions)'))
    else if($facet-definitions/facet:range) then
        facet:group-by-range($results, $facet-definitions)   
    else facet:group-by($results, $facet-definitions)
};

(:~
 : Default facet function. 
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
:) 
declare function facet:group-by($results as item()*, $facet-definition as element(facet:facet-definition)?) as element(facet:key)*{
    let $path := concat('$results/',$facet-definition/facet:group-by/facet:sub-path/text())
    let $sort := $facet-definition/facet:order-by
    return 
        if($sort/@direction = 'ascending') then 
            let $facets := 
                for $f in util:eval($path)
                group by $facet-grp := $f
                let $label := if($f[self::attribute()]) then $f[1]/parent::*[1]/text() else $facet-grp
                order by 
                    if($sort/text() = 'value') then $label
                    else count($f)
                    ascending
                return facet:key($label, $facet-grp, count($f), $facet-definition)
            let $count := count($facets)
            return facet:list-keys($facets, $count, $facet-definition) 
        else 
            let $facets := 
                for $f in util:eval($path)
                group by $facet-grp := $f
                let $label := if($f[self::attribute()]) then $f[1]/parent::*[1]/text() else $facet-grp
                order by 
                    if($sort/text() = 'value') then $label
                    else count($f)
                    descending
                return facet:key($label, $facet-grp, count($f), $facet-definition)
            let $count := count($facets)   
            return facet:list-keys($facets, $count, $facet-definition)
};
   
(:~ 
 : Range values defined by: range and range/bucket elements
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
:) 
declare function facet:group-by-range($results as item()*, $facet-definition as element(facet:facet-definition)*) as element(facet:key)*{
    let $ranges := $facet-definition/facet:range
    let $sort := $facet-definition/facet:order-by
    let $facets := 
        for $range in $ranges/facet:bucket
        let $path := if($range/@lt and $range/@lt != '') then
                        concat('$results/',$facet-definition/descendant::facet:sub-path/text(),'[. >= "', facet:type($range/@gt, $ranges/@type),'" and . <= "',facet:type($range/@lt, $ranges/@type),'"]')
                     else if($range/@eq) then
                        concat('$results/',$facet-definition/descendant::facet:sub-path/text(),'[', $range/@eq ,']')
                     else concat('$results/',$facet-definition/descendant::facet:sub-path/text(),'[. >= "', facet:type($range/@gt, $ranges/@type),'"]')
        let $f := util:eval($path)
        order by 
                if($sort/text() = 'value') then $f[1]
                else if($sort/text() = 'count') then count($f)
                else if($sort/text() = 'order') then xs:integer($range/@order)
                else count($f)
            descending
        let $count := count($f)
        return facet:key(string($range/@name), string($range/@name), count($f), $facet-definition)
    let $count := count($facets)        
    return 
        if($count gt 0) then
            <div class="facetDefinition facet-grp">
                <h4>{string($facet-definition/@name)}</h4>
                {$facets}
            </div>
        else ()
};   

(:~
 : Syriaca.org specific group-by function for correctly labeling attributes with arrays.
 : Used for TEI relationships where multiple URIs may be coded in a single element or attribute
:)
declare function facet:group-by-array($results as item()*, $facet-definition as element(facet:facet-definition)?){
    let $path := concat('$results/',$facet-definition/facet:group-by/facet:sub-path/text()) 
    let $sort := $facet-definition/facet:order-by
    let $d := tokenize(string-join(util:eval($path),' '),' ')
    let $facets := 
        for $f in $d
        group by $facet-grp := tokenize($f,' ')
        order by 
            if($sort/text() = 'value') then $f[1]
            else count($f)
            descending
        return facet:key($facet-grp, $facet-grp, count($f), $facet-definition) 
    let $count := count($facets)           
    return facet:list-keys($facets, $count, $facet-definition)
};

declare function facet:list-keys($facets as item()*, $count, $facet-definition as element(facet:facet-definition)*){        
if($count gt 0) then 
    let $max := if(xs:integer($facet-definition/facet:max-values)) then xs:integer($facet-definition/facet:max-values) else 10
    let $show := if(xs:integer($facet-definition/facet:max-values/@show)) then xs:integer($facet-definition/facet:max-values/@show) else 5
    return 
        <div class="facetDefinition facet-grp">
            <h4>{string($facet-definition/@name)}</h4>
            <div class="facet-list show">{
            for $key at $l in subsequence($facets,1,$show)
            return $key
            }</div>
            {if($count gt ($show)) then 
                (<div class="facet-list collapse" id="{concat('show',replace(string($facet-definition/@name),' ',''))}">{
                    for $key at $l in subsequence($facets,$show + 1,$max)
                    where $count gt 0
                    return $key
                }</div>,
                <a class="facet-label togglelink btn btn-info" 
                data-toggle="collapse" data-target="#{concat('show',replace(string($facet-definition/@name),' ',''))}" href="#{concat('show',replace(string($facet-definition/@name),' ',''))}" 
                data-text-swap="Less"> More &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>)
            else()}
        </div>
else ()
};

declare function facet:key($label, $value, $count, $facet-definition){
   let $facet-query := concat(string($facet-definition/@name),':',$value)
   (:replace(replace(concat(';fq-',string($facet-definition/@name),':',string($value)),';fq-;fq-;',';fq-'),';fq- ',''):)
   let $active := if(contains($facet:fq,concat(';fq-',string($facet-definition/@name),':',string($value)))) then 'active' else ()
   let $new-fq :=
        if($active) then 
            concat('fq=',
                string-join(for $facet-param in tokenize($facet:fq,';fq-') 
                        return 
                            if($facet-param = '' or $facet-param = $facet-query) then () 
                            else concat(';fq-',$facet-param),''))
        else if($facet:fq) then concat('fq=',encode-for-uri($facet:fq),encode-for-uri(concat(';fq-',$facet-query)))
        else concat('fq=',encode-for-uri(concat(';fq-',$facet-query)))
   return 
        if($count gt 0) then 
           <a href="?{$new-fq}{facet:url-params()}" class="facet-label btn btn-default {$active}">{if($active) then <span class="glyphicon glyphicon-remove facet-remove"></span> else ()}{$label} <span class="count"> ({string($count)})</span> </a>
        else ()        
};

(:~
 : Create 'Remove' button for selected facets
 : Constructs new URL for user action 'remove facet'
:)
declare function facet:selected-facets-display(){
    for $facet in tokenize($facet:fq,';fq-')
    let $value := substring-after($facet,':')
    let $new-fq := string-join(
                    for $facet-param in tokenize($facet:fq,';fq-') 
                    return 
                        if($facet-param = $facet) then ()
                        else concat(';fq-',$facet-param),'')
    let $href := if($new-fq != '') then concat('?fq=',replace(replace($new-fq,';fq- ',''),';fq-;fq-',';fq-'),facet:url-params()) else ()
    return 
        if($facet != '') then 
            <span class="label label-facet" title="Remove {$value}">
                {$value} <a href="{$href}" class="facet icon"> x</a>
            </span>
        else()
};

(:~ 
 : Create 'Remove' button for selected facets, uses facet-definition as part of label
 : Constructs new URL for user action 'remove facet'
:)
declare function facet:selected-facets-display($facet-definition){
    for $facet in tokenize($facet:fq,';fq-')
    let $facet-name := substring-before($facet,':')
    let $value := substring-after($facet,':')
    let $new-fq := string-join(
                    for $facet-param in tokenize($facet:fq,';fq-') 
                    return 
                        if($facet-param = $facet) then ()
                        else concat(';fq-',$facet-param),'')
    let $href := if($new-fq != '') then concat('?fq=',replace(replace($new-fq,';fq- ',''),';fq-;fq-',';fq-'),facet:url-params()) else ()
    return
        for $f in $facet-definition/descendant-or-self::*[@name = $facet-name]
        let $fn := string($f/@name)
        return 
                    <span class="label facet-label remove" title="Remove {$value}">
                        {concat($fn,': ', $value)} <a href="{$href}" class="facet icon"> x</a>
                    </span>
};

(:~ 
 : Builds new facet params for html links.
 : Uses request:get-parameter-names() to get all current params 
 :)
declare function facet:url-params(){
    string-join(
    for $param in request:get-parameter-names()
    return 
        if($param = 'fq') then ()
        else if($param = 'start') then '&amp;start=1'
        else if(request:get-parameter($param, '') = ' ') then ()
        else concat('&amp;',$param, '=',request:get-parameter($param, '')),'')
};

(: END :)

