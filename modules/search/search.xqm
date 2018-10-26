xquery version "3.1";        
(:~  
 : Builds HTML search forms and HTMl search results Srophe Collections and sub-collections   
 :) 
module namespace search="http://syriaca.org/srophe/search";

(:eXist templating module:)
import module namespace templates="http://exist-db.org/xquery/templates" ;

(: Import KWIC module:)
import module namespace kwic="http://exist-db.org/xquery/kwic";

(: Import Srophe application modules. :)
import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";
import module namespace data="http://syriaca.org/srophe/data" at "../lib/data.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "../lib/global.xqm";
import module namespace facet="http://expath.org/ns/facet" at "facet.xqm";
import module namespace page="http://syriaca.org/srophe/page" at "../lib/paging.xqm";
import module namespace slider = "http://syriaca.org/srophe/slider" at "../lib/date-slider.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "../content-negotiation/tei2html.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(: Variables:)
declare variable $search:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $search:perpage {request:get-parameter('perpage', 20) cast as xs:integer};

(:~
 : Builds search result, saves to model("hits") for use in HTML display
:)

(:~
 : Search results stored in map for use by other HTML display functions
 data:search($collection)
:)
declare %templates:wrap function search:search-data($node as node(), $model as map(*), $collection as xs:string?){
    let $queryExpr := search:query-string($collection)                        
    return
        if(empty($queryExpr) or $queryExpr = "" or empty(request:get-parameter-names())) then ()
        else 
            let $hits := data:search($collection,$queryExpr)
            return
                map {
                        "hits" := $hits,
                        "query" := $queryExpr
                    } 
};


declare function search:group-results($node as node(), $model as map(*), $collection as xs:string?){
    let $hits := $model("hits")
    let $groups := distinct-values($hits//tei:relation[@ref="schema:containedInPlace"]/@passive)
    return 
        map {"group-by-sites" :=            
            for $place in $hits 
            let $site := $place/descendant::tei:relation[@ref="schema:containedInPlace"]/@passive
            group by $facet-grp-p := $site[1]
            (:let $label := string-join($model("hits")[//tei:idno[. = $site[1]]]//tei:title[1]/text(),''):)
            let $label := global:get-label($site[1])
            order by $label
            return  
                if($site != '') then 
                    <div class="indent" xmlns="http://www.w3.org/1999/xhtml" style="margin-bottom:1em;">
                            <a class="togglelink text-info" 
                            data-toggle="collapse" data-target="#show{replace($label,' ','')}" 
                            href="#show{replace($label,' ','')}" data-text-swap=" + "> - </a>&#160; 
                            <a href="{replace($facet-grp-p,$global:base-uri,$global:nav-base)}">{$label}</a> (contains {count($place)} buildings)
                            <div class="indent collapse in" style="background-color:#F7F7F9;" id="show{replace($label,' ','')}">{
                                for $p in $place
                                let $id := replace($p/descendant::tei:idno[1],'/tei','')
                                return 
                                    <div class="indent" style="border-bottom:1px dotted #eee; padding:1em">{tei2html:summary-view(root($p), '', $id)}</div>
                            }</div>
                    </div>
                else if($site = '' or not($site)) then
                    for $p in $place
                    let $id := replace($p/descendant::tei:idno[1],'/tei','')
                    return
                        if($groups[. = $id]) then () 
                        else 
                            <div class="col-md-11" style="margin-right:-1em; padding-top:.5em;">
                                 {tei2html:summary-view(root($p), '', $id)}
                            </div>                        
                else ()
        } 
};

(:~ 
 : Builds results output
:)
declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*), $collection as xs:string?, $kwic as xs:string?) {
<div class="indent" id="search-results" xmlns="http://www.w3.org/1999/xhtml">
    {
        if($collection = 'places') then 
            let $hits := $model("group-by-sites")
            for $hit at $p in subsequence($hits, $search:start, $search:perpage)
            return $hit
        else 
            let $hits := $model("hits")
            for $hit at $p in subsequence($hits, $search:start, $search:perpage)
            let $id := replace($hit/descendant::tei:idno[1],'/tei','')
            return 
             <div class="row record" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
                 <div class="col-md-1" style="margin-right:-1em; padding-top:.25em;">        
                     <span class="badge" style="margin-right:1em;">{$search:start + $p - 1}</span>
                 </div>
                 <div class="col-md-11" style="margin-right:-1em; padding-top:.25em;">
                     {tei2html:summary-view(root($hit), '', $id)}
                 </div>
             </div>   
   }  
</div>
};

(:~
 : Build advanced search form using either search-config.xml or the default form search:default-search-form()
 : @param $collection. Optional parameter to limit search by collection. 
 : @note Collections are defined in repo-config.xml
 : @note Additional Search forms can be developed to replace the default search form. 
:)
declare function search:search-form($node as node(), $model as map(*), $collection as xs:string?){
if(exists(request:get-parameter-names())) then ()
else 
    let $search-config := 
        if($collection != '') then concat($config:app-root, '/', string(config:collection-vars($collection)/@app-root),'/','search-config.xml')
        else concat($config:app-root, '/','search-config.xml')
    return 
        if(doc-available($search-config)) then 
            search:build-form($search-config) 
        else search:default-search-form()
};

(:~
 : Builds a simple advanced search from the search-config.xml. 
 : search-config.xml provides a simple mechinisim for creating custom inputs and XPaths, 
 : For more complicated advanced search options, especially those that require multiple XPath combinations
 : we recommend you add your own customizations to search.xqm
 : @param $search-config a values to use for the default search form and for the XPath search filters. 
:)
declare function search:build-form($search-config) {
    let $config := doc($search-config)
    return 
        <form method="get" class="form-horizontal indent" role="form">
            <h1 class="search-header">{if($config//label != '') then $config//label else 'Search'}</h1>
            {if($config//desc != '') then 
                <p class="indent info">{$config//desc}</p>
            else() 
            }
            <div class="well well-small search-box">
                <div class="row">
                    <div class="col-md-10">{
                        for $input in $config//input
                        let $name := string($input/@name)
                        let $id := concat('s',$name)
                        return 
                            <div class="form-group">
                                <label for="{$name}" class="col-sm-2 col-md-3  control-label">{string($input/@label)}: 
                                {if($input/@title != '') then 
                                    <span class="glyphicon glyphicon-question-sign text-info moreInfo" aria-hidden="true" data-toggle="tooltip" title="{string($input/@title)}"></span>
                                else ()}
                                </label>
                                <div class="col-sm-10 col-md-9 ">
                                    <div class="input-group">
                                        <input type="text" 
                                        id="{$id}" 
                                        name="{$name}" 
                                        data-toggle="tooltip" 
                                        data-placement="left" class="form-control keyboard"/>
                                        {($input/@title,$input/@placeholder)}
                                        {
                                            if($input/@keyboard='yes') then 
                                                <span class="input-group-btn">{global:keyboard-select-menu($id)}</span>
                                             else ()
                                         }
                                    </div> 
                                </div>
                            </div>}
                    </div>
                </div> 
            </div>
            <div class="pull-right">
                <button type="submit" class="btn btn-info">Search</button>&#160;
                <button type="reset" class="btn btn-warning">Clear</button>
            </div>
            <br class="clearfix"/><br/>
        </form> 
};

(:~
 : Simple default search form to us if not search-config.xml file is present. Can be customized. 
:)
declare function search:default-search-form() {
    <form method="get" class="form-horizontal indent" role="form">
        <h1 class="search-header">Search</h1>
        <div class="well well-small search-box">
            <div class="row">
                <div class="col-md-10">
                    <!-- Keyword -->
                    <div class="form-group">
                        <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="keyword" name="keyword" class="form-control keyboard"/>
                                <div class="input-group-btn">
                                {global:keyboard-select-menu('keyword')}
                                </div>
                            </div> 
                        </div>
                    </div>
                    <!-- Title-->
                    <div class="form-group">
                        <label for="title" class="col-sm-2 col-md-3  control-label">Title: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="title" name="title" class="form-control keyboard"/>
                                <div class="input-group-btn">
                                {global:keyboard-select-menu('title')}
                                </div>
                            </div>   
                        </div>
                    </div>
                   <!-- Place Name-->
                    <div class="form-group">
                        <label for="placeName" class="col-sm-2 col-md-3  control-label">Place Name: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="placeName" name="placeName" class="form-control keyboard"/>
                                <div class="input-group-btn">
                                {global:keyboard-select-menu('placeName')}
                                </div>
                            </div>   
                        </div>
                    </div>
                <!-- end col  -->
                </div>
                <!-- end row  -->
            </div>    
            <div class="pull-right">
                <button type="submit" class="btn btn-info">Search</button>&#160;
                <button type="reset" class="btn">Clear</button>
            </div>
            <br class="clearfix"/><br/>
        </div>
    </form>
};

(: Architectura Sinica functions :)
(:
 : TCADRT - display architectural features select lists
:)
declare %templates:wrap function search:architectural-features($node as node()*, $model as map(*)){ 
    <div class="row">{
        let $features := collection($global:data-root || '/keywords')/tei:TEI[descendant::tei:entryFree/@type='architectural-feature']
        for $feature in $features
        let $type := string($feature/descendant::tei:relation[@ref = 'skos:broadMatch'][1]/@passive)
        group by $group-type := $type
        return  
            <div class="col-md-6">
                <h4 class="indent">{string($group-type)}</h4>
                {
                    for $f in $feature
                    let $title := string-join($f/descendant::tei:titleStmt/tei:title[1]//text(),' ')
                    let $id := replace($f/descendant::tei:idno[1],'/tei','')
                    return 
                        <div class="form-group row">
                            <div class="col-sm-4 col-md-3" style="text-align:right;">
                                  { if($f/descendant::tei:entryFree/@sub-type='numeric') then
                                    <select name="{concat('feature-num:',$id)}" class="inline">
                                      <option value="">No.</option>
                                      <option value="1">1</option>
                                      <option value="2">2</option>
                                      <option value="3">3</option>
                                      <option value="4">4</option>
                                      <option value="5">5</option>
                                      <option value="6">6</option>
                                      <option value="7">7</option>
                                      <option value="8">8</option>
                                      <option value="9">9</option>
                                      <option value="10">10</option>
                                    </select>
                                    else ()}
                            </div>    
                            <div class="checkbox col-sm-8 col-md-9" style="text-align:left;margin:0;padding:0">
                                <label><input type="checkbox" value="true" name="{concat('feature:',$id)}"/>{$title}</label>
                            </div>
                        </div>
                    }
                </div>                    
    }</div>
};

(: TCADRT terms:)
declare function search:terms(){
    if(request:get-parameter('term', '')) then 
        data:element-search('term',request:get-parameter('term', '')) 
    else '' 
};

(: TCADRT architectural feature search functions :)
declare function search:features(){
    string-join(for $feature in request:get-parameter-names()[starts-with(., 'feature:' )]
    let $name := substring-after($feature,'feature:')
    let $number := 
        for $feature-number in request:get-parameter-names()[starts-with(., 'feature-num:' )][substring-after(.,'feature-num:') = $name]
        let $num-value := request:get-parameter($feature-number, '')
        return
            if($num-value != '' and $num-value != '0') then 
               concat("[descendant::tei:num[. = '",$num-value,"']]")
           else ()
    return 
        if(request:get-parameter($feature, '') = 'true') then 
            concat("[descendant::tei:relation[@ana='architectural-feature'][@passive = '",$name,"']",$number,"]")
        else ())          
};

(: TCADRT architectural feature search functions :)
declare function search:features(){
    string-join(for $feature in request:get-parameter-names()[starts-with(., 'feature:' )]
    let $name := substring-after($feature,'feature:')
    let $number := 
        for $feature-number in request:get-parameter-names()[starts-with(., 'feature-num:' )][substring-after(.,'feature-num:') = $name]
        let $num-value := request:get-parameter($feature-number, '')
        return
            if($num-value != '' and $num-value != '0') then 
               concat("[descendant::tei:num[. = '",$num-value,"']]")
           else ()
    return 
        if(request:get-parameter($feature, '') = 'true') then 
            concat("[descendant::tei:relation[@ana='architectural-feature'][@passive = '",$name,"']",$number,"]")
        else ())          
};

(:~   
 : Builds general search string from main syriaca.org page and search api.
:)
declare function search:query-string($collection as xs:string?) as xs:string?{
let $search-config := concat($global:app-root, '/', string(config:collection-vars($collection)/@app-root),'/','search-config.xml')
return
    if($collection != '') then 
        if(doc-available($search-config)) then 
           concat("collection('",$global:data-root,"/",$collection,"')//tei:body",facet:facet-filter(global:facet-definition-file($collection)),slider:date-filter(()),data:dynamic-paths($search-config))
        else if($collection = 'places') then  
            concat("collection('",$global:data-root,"')//tei:TEI",
            facet:facet-filter(global:facet-definition-file($collection)),
            slider:date-filter(()),
            data:keyword-search(),
            data:element-search('placeName',request:get-parameter('placeName', '')),
            data:element-search('title',request:get-parameter('title', '')),
            data:element-search('bibl',request:get-parameter('bibl', '')),
            data:uri(),
            search:terms(),
            data:element-search('term',request:get-parameter('term', '')),
            search:features()
          )
        else
            concat("collection('",$global:data-root,"/",$collection,"')//tei:TEI",
            facet:facet-filter(global:facet-definition-file($collection)),
            slider:date-filter(()),
            data:keyword-search(),
            data:element-search('placeName',request:get-parameter('placeName', '')),
            data:element-search('title',request:get-parameter('title', '')),
            data:element-search('bibl',request:get-parameter('bibl', '')),
            data:uri(),
            search:terms(),
            search:features()
          )
    else concat("collection('",$global:data-root,"')//tei:TEI",
        facet:facet-filter(global:facet-definition-file($collection)),
        slider:date-filter(()),
        data:keyword-search(),
        data:element-search('placeName',request:get-parameter('placeName', '')),
        data:element-search('title',request:get-parameter('title', '')),
        data:element-search('bibl',request:get-parameter('bibl', '')),
        data:uri(),
        search:features()
        )
};
