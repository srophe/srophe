xquery version "3.0";

(:~
 : Passes content to content negotiation module, if not using restxq
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2018-04-12
:)

import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";

(: Content serialization modules. :)
import module namespace cntneg="http://srophe.org/srophe/cntneg" at "content-negotiation.xqm";
import module namespace tei2html="http://srophe.org/srophe/tei2html" at "tei2html.xqm";

(: Data processing module. :)
import module namespace data="http://srophe.org/srophe/data" at "../lib/data.xqm";

(: Import KWIC module:)
import module namespace kwic="http://exist-db.org/xquery/kwic";

(: Namespaces :)
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http="http://expath.org/ns/http-client";
declare namespace srophe="https://srophe.app";

(:~
 : Search API
 : @note: This function is important! Used by eKtobe
 : @param $element element to be searched. Accepts: persName, placeName, title, author, note, event, desc, location, idno
 : @param $collection accepts any value specified in the repo-config.xml
 : @param $lang accepts any valid ISO lang attribute used in the @xml:lang attrubute in the TEI
 : @param $author accepts string value. May only be used when $element = 'title'    
:)
declare function local:search-element($element as xs:string?, $q as xs:string*, $collection as xs:string*){                     
    let $e := if($element = 'citation' or $element = 'simpleCite') then 'biblStruct'
              else if($element = 'biblWorksCitation') then 'title'
              else if($element = 'biblWorksAuthor') then 'persName'
              else if($element = 'titleBibl') then  'title'
              else if($element = 'mutual' or $element = 'active' or $element = 'passive') then  ()
              else if($element = 'search') then ()
              else if($element != '') then $element
              else ()
    let $hits := 
                if(contains($collection,',')) then 
                    for $c in tokenize($collection,',')
                    return data:apiSearch($c, $e, $q, ())
                else data:apiSearch($collection, $e, $q, ())
   let $hits := if(request:get-parameter('limit', '') != '') then
                    for $hit in $hits
                    let $id := replace($hit/ancestor-or-self::tei:TEI/descendant::tei:publicationStmt/tei:idno[@type='URI'][1],'/tei','')
                    where contains($id,request:get-parameter('limit', ''))
                    return $hit 
                 else $hits
    return 
        if(count($hits) gt 0) then 
            <json:value>
                <action>{$q} in {$element}</action>
                <info>hits: {count($hits)}</info>
                <start>1</start>
                <results>
                    {
                     for $hit in $hits
                     let $id := replace($hit/ancestor-or-self::tei:TEI/descendant::tei:publicationStmt/tei:idno[@type='URI'][1],'/tei','')
                     let $headword := if($hit[contains(@srophe:tags,'#syriaca-headword')]) then
                                        normalize-space(string-join($hit//text(),' '))
                                      else if($hit/following-sibling::*[contains(@srophe:tags,'#syriaca-headword')]) then
                                        normalize-space(string-join($hit/following-sibling::*[contains(@srophe:tags,'#syriaca-headword')][1]//text(),' '))
                                      else if($hit/preceding-sibling::*[contains(@srophe:tags,'#syriaca-headword')]) then
                                        normalize-space(string-join($hit/preceding-sibling::*[contains(@srophe:tags,'#syriaca-headword')][1]//text(),' '))
                                      else normalize-space(string-join($hit/ancestor-or-self::tei:TEI/descendant::tei:title[1]//text(),' '))
                     let $xmlID := replace(replace(substring-after($id,'://'),'/',''),'\.','-')
                     group by $recID := $id
                     return
                         <json:value json:array="true">
                            <id>{$recID}</id>
                            <title>
                                {
                                if($element = 'citation') then 
                                    <bibl xmlns="http://www.tei-c.org/ns/1.0">
                                        <bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$xmlID[1]}">
                                            <idno>{$hit/ancestor-or-self::tei:TEI/descendant::tei:title[@level='a'][1]//text()}</idno>
                                            <title>{$hit/ancestor-or-self::tei:TEI/descendant::tei:bibl[@type='formatted'][@subtype='citation']//text()}</title>
                                            <ptr target="{$recID}"/>
                                        </bibl>
                                        {$hit/ancestor-or-self::tei:TEI/descendant::tei:bibl[@type='formatted'][@subtype='citation']}
                                    </bibl>
                                else if($element = 'simpleCite') then 
                                    <bibl xmlns="http://www.tei-c.org/ns/1.0">
                                        <bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$xmlID[1]}">
                                            <title>{$hit/ancestor-or-self::tei:TEI/descendant::tei:bibl[@type='formatted'][@subtype='citation']//text()}</title>
                                            <ptr target="{$recID}"/>
                                        </bibl>
                                        {$hit/ancestor-or-self::tei:TEI/descendant::tei:bibl[@type='formatted'][@subtype='citation']}
                                    </bibl>  
                                else if($element = 'titleBibl') then 
                                    <bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$xmlID[1]}">
                                        <title>{$hit/ancestor-or-self::tei:TEI/descendant::tei:title[@level='a'][1]//text()}</title>
                                        <ptr target="{$recID}"/>
                                    </bibl> 
                                else if($element = 'biblWorksAuthor') then 
                                   <bibl xmlns="http://www.tei-c.org/ns/1.0">
                                        <bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$xmlID[1]}">
                                            {
                                            element {xs:QName(request:get-parameter('wrapElement', ''))}
                                            {attribute { "ref" } { $recID }, $headword[1]}
                                            }
                                            <ptr target="{$recID}"/>
                                        </bibl>
                                        {$hit/ancestor-or-self::tei:TEI/descendant::tei:bibl[@type='formatted'][@subtype='citation']}
                                    </bibl> 
                                else if($element = 'biblWorksCitation') then 
                                   <bibl xmlns="http://www.tei-c.org/ns/1.0">
                                        <bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$xmlID[1]}">
                                            <title>{$hit/ancestor-or-self::tei:TEI/descendant::tei:title[1]//text()}</title>
                                            <ptr target="{$recID}"/>
                                        </bibl>
                                        {$hit/ancestor-or-self::tei:TEI/descendant::tei:bibl[@type='formatted'][@subtype='citation']}
                                    </bibl>   
                                else if($element = 'mutual' or $element = 'active' or $element = 'passive') then 
                                    let $type := if(contains($recID,'person')) then '[person] '
                                                 else if(contains($recID,'place')) then '[place] '
                                                 else if(contains($recID,'manuscript')) then '[manuscript] '
                                                 else if(contains($recID,'relation')) then '[relation] '
                                                 else if(contains($recID,'work')) then '[work] '
                                                 else if(contains($recID,'bibl')) then '[citation]'
                                                 else ()
                                   return  
                                    if($type = '[citation]') then () 
                                    else 
                                        if($element = 'mutual') then 
                                            <mutual xmlns="http://www.tei-c.org/ns/1.0">
                                                {attribute { "ref" } { $recID }, concat($type,$headword[1]) }
                                            </mutual>  
                                        else if($element = 'active') then
                                            <active xmlns="http://www.tei-c.org/ns/1.0">
                                                {attribute { "ref" } { $recID }, concat($type,$headword[1]) }
                                            </active>  
                                        else if($element = 'passive') then
                                            <passive xmlns="http://www.tei-c.org/ns/1.0">
                                                {attribute { "ref" } { $recID }, concat($type,$headword[1]) }
                                            </passive>
                                        else ()                                       
                                else if(request:get-parameter('wrapElement', '') != '') then
                                    if(request:get-parameter('wrapElement', '') = 'author') then 
                                        element {xs:QName(request:get-parameter('wrapElement', ''))}
                                            {attribute { "ref" } { $recID }, $headword[1]}
                                    else if(request:get-parameter('wrapElement', '') = 'relation') then 
                                        element {xs:QName(request:get-parameter('wrapElement', ''))}
                                            {attribute { "ref" } { $recID }, $headword[1]}                                            
                                    else 
                                        element {xs:QName(request:get-parameter('wrapElement', ''))}
                                            {attribute { "ref" } { $recID }, 
                                                element {xs:QName($element)}
                                                {attribute { "ref" } { $recID }, $headword[1] }
                                            }
                                else 
                                    element {xs:QName($element)}
                                        {attribute { "ref" } { $recID }, $headword[1] }
                                }
                            </title>
                            {'' (:Not sure what the utility is here :)
                            (:
                                for $h in $hit
                                return 
                                    if($element = 'citation') then 
                                        <bibl>
                                            <ptr target="{$recID}"/>
                                        </bibl>
                                    else 
                                        (element {xs:QName($element)}
                                            {attribute { "ref" } { $recID }, normalize-space(string-join($h//text(),' ')) },
                                        if($element = 'persName') then 
                                            <date>{
                                            normalize-space(string-join($hit/ancestor-or-self::tei:TEI/descendant::tei:body/descendant::tei:birth/descendant-or-self::text() 
                                            | $hit/ancestor-or-self::tei:TEI/descendant::tei:body/descendant::tei:death/descendant-or-self::text() | 
                                            $hit/ancestor-or-self::tei:TEI/descendant::tei:body/descendant::tei:floruit/descendant-or-self::text(),' '))
                                            }</date>
                                        else ()
                                        )
                            :)}
                         </json:value>                           
                     }
                </results>
            </json:value>
        else   
            <json:value>
                <json:value json:array="true">
                    <action>{$q} in {$element}</action>
                    <info>No results</info>
                    <start>1</start>
                </json:value>
            </json:value>              
};

(:~
 : Search API, returns coordinates     
:)
declare function local:coordinates($type as xs:string?, $collection as xs:string*){          
   let $path := 
        if($type) then
            if(contains($type,',')) then 
                let $types := 
                    if(contains($type,',')) then  string-join(for $type-string in tokenize($type,',') return concat('"',$type-string,'"'),',')
                    else $type
                return concat(data:build-collection-path($collection),"[descendant::tei:place[@type = (",$types,")]//tei:geo]") 
            else concat(data:build-collection-path($collection),'[descendant::tei:place[@type=$type]]')
        else concat(data:build-collection-path($collection),'[descendant::tei:geo]')         
     return util:eval($path)
};

let $path := if(request:get-parameter('id', '')  != '') then 
                request:get-parameter('id', '')
             else if(request:get-parameter('doc', '') != '') then
                request:get-parameter('doc', '')
             else ()   
let $data :=
    if(request:get-parameter('id', '') != '' or request:get-parameter('doc', '') != '') then
        data:get-document()
    else if(request:get-parameter-names() != '') then 
        if(request:get-parameter('api', '') != '') then
            if(request:get-parameter('element', '') !='' and request:get-parameter('q', '') != '') then
                local:search-element(request:get-parameter('element', ''), request:get-parameter('q', ''), if(request:get-parameter('collection', '')) then request:get-parameter('collection', '') else ())
            else if(request:get-parameter('geo', '') != '') then
               local:coordinates(request:get-parameter('type', ''), request:get-parameter('collection', ''))
            else <div>Nothing, check params: {request:get-parameter-names()}</div>
        else
            let $collectionParam := 
                if(request:get-parameter('existCollection','') != '') then
                    tokenize(replace(request:get-parameter('existCollection',''),'/tei',''),'/')[last()]
                else ()
let $collection := $collectionParam  
            let $hits := data:search($collection,'','')
            return 
                if(count($hits) gt 0) then 
                    <root>
                        <action>{string-join(
                                    for $param in request:get-parameter-names()
                                    return concat('&amp;',$param, '=',request:get-parameter($param, '')),'')}</action>
                        <info count="{count($hits)}">hits: {count($hits)}</info>
                        {
                            let $start := if(request:get-parameter('start','') != '') then request:get-parameter('start','') else '1'
                            let $perpage := if(request:get-parameter('perpage', 10)) then request:get-parameter('perpage', 10) else 10
                            let $next := xs:integer($start) + xs:integer($perpage)
                            return 
                                (<start>{$start}</start>,
                                 if($next lt count($hits)) then
                                    <next>{$next}</next>
                                 else (),
                                <results>{

                                    for $hit in subsequence($hits,$start,$perpage)
                                    let $id := replace($hit/descendant::tei:idno[starts-with(.,$config:base-uri)][1],'/tei','')
                                    let $title := $hit/descendant::tei:titleStmt/tei:title[1]
                                    let $expanded := kwic:expand($hit)
                                    return 
                                        <json:value json:array="true">
                                            {   
                                                if(request:get-parameter('results', '') = 'manuForma') then 
                                                    <record src="{document-uri(root($hit))}" name="{$title}" idno="{concat('[',$id,']')}"/>
                                                else () 
                                            }
                                            <id>{$id}</id>
                                            {$title[1]}
                                            <hits>{normalize-space(string-join((tei2html:output-kwic($expanded, $id)),' '))}</hits>
                                        </json:value>
                                    }
                                </results>)
                        }
                        <facets>
                            <facetGrp label="country">
                                {
                                    let $country := ft:facets($hits, "country")
                                    return 
                                        map:for-each($country, function($label, $count) {
                                        <facet label="{$label}" count="{$count}"></facet>
                                    })
                                }
                            </facetGrp>
                            <facetGrp label="city">
                                {
                                    let $settlement := ft:facets($hits, "city")
                                    return 
                                        map:for-each($settlement, function($label, $count) {
                                        <facet label="{$label}" count="{$count}"></facet>
                                    })
                                }
                            </facetGrp>
                            <facetGrp label="repository">
                                {
                                    let $repository := ft:facets($hits, "repository")
                                    return 
                                        map:for-each($repository, function($label, $count) {
                                        <facet label="{$label}" count="{$count}"></facet>
                                    })
                                }
                            </facetGrp>
                            <facetGrp label="collection">
                                {
                                    let $collection := ft:facets($hits, "collection")
                                    return 
                                        map:for-each($collection, function($label, $count) {
                                        <facet label="{$label}" count="{$count}"></facet>
                                    })
                                }
                            </facetGrp>
                        </facets>
                    </root>
                else 
                    <root>
                        <json:value json:array="true">
                            <action>{string-join(
                                    for $param in request:get-parameter-names()
                                    return concat('&amp;',$param, '=',request:get-parameter($param, '')),'')}</action>
                            <info>No results</info>
                            <start>0</start>
                        </json:value>
                    </root>
       else ()
let $format := if(request:get-parameter('format', '') != '') then request:get-parameter('format', '') else 'xml'    
return  
    if(not(empty($data))) then
        if(request:get-parameter('api', '') != '') then
            if(request:get-parameter('geo', '')) then
                if($format = 'kml') then 
                    cntneg:content-negotiation($data,'kml',())
                else cntneg:content-negotiation($data,'geojson',())
            else 
                let $format := if(request:get-parameter('format', '') = 'xml') then 'xml' else 'json'
                return cntneg:content-negotiation($data, $format, ())
        else cntneg:content-negotiation($data, $format, $path)    
    else ()