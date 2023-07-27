xquery version "3.0";
(:~
 : Paging module for reuse by search and browse pages
 : Adds page numbers and sort options to HTML output.  
 :) 
module namespace page="http://srophe.org/srophe/page";
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
import module namespace global="http://srophe.org/srophe/global" at "global.xqm";

import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare namespace xlink = "http://www.w3.org/1999/xlink";


(:~
 : Build paging menu for search results, includes search string
 : $param @hits hits as nodes
 : $param @start start number passed from url
 : $param @perpage number of hits to show 
 : $param @sort include search options 
:)
declare function page:pages(
    $hits as node()*, 
    $collection,
    $start, 
    $perpage, 
    $search-string,
    $sort-options){
let $perpage := if($perpage) then 
                    if($perpage[1] castable as xs:integer) then 
                        xs:integer($perpage[1]) 
                    else 20
                 else 20
let $start := if($start) then 
                if($start[1] castable as xs:integer) then 
                    xs:integer($start[1]) 
                else 1 
              else 1               
let $total-result-count := count($hits)
let $end := 
    if ($total-result-count lt $perpage) then 
        $total-result-count
    else 
        $start + $perpage
let $number-of-pages :=  xs:integer(ceiling($total-result-count div $perpage))
let $current-page := xs:integer(($start + $perpage) div $perpage)
let $cleanParams :=
        string-join(
        for $pramName in request:get-parameter-names()
        return 
            if($pramName = ('start','perpage','sort-element','sort')) then () 
            else 
                for $param in request:get-parameter($pramName, '')
                where $param != ''
                return ($pramName || '=' || $param)
                ,'&amp;')
let $sortParams := 
        if(request:get-parameter('sort-element', '') != '') then 
            ('sort-element'|| '=' || request:get-parameter('sort-element', '')[1])
        else()
let $param-string := 
        if($cleanParams != '' and $sortParams != '') then 
            ('?' || $cleanParams || '&amp;' || $sortParams ||'&amp;start=')
        else if($cleanParams != '') then 
            ('?' || $cleanParams ||'&amp;start=')
        else if($sortParams != '') then 
            ('?' || $sortParams || '&amp;start=')
        else '?start='
return 
    <div class="row alpha-pages" xmlns="http://www.w3.org/1999/xhtml">
            {
            if($search-string = ('yes','Yes')) then  
                if(page:display-search-params($collection) != '') then 
                <div class="col-sm-5 search-string">
                    <h3 class="hit-count paging">Search results: </h3>
                    <p class="col-md-offset-1 hit-count">{$total-result-count} matches for {page:display-search-params($collection)} </p>
                    <p class="col-md-offset-1 hit-count note small">
                        You may wish to expand your search by using wildcard characters to increase results. See  
                        <a href="#" data-toggle="collapse" data-target="#searchTips">search tips</a> for more details.
                    </p> 
                    <div id="searchTips" class="panel panel-default collapse">
                        {
                        let $search-config := 
                            if($collection != '') then concat($config:app-root, '/', string(config:collection-vars($collection)/@app-root),'/','search-config.xml')
                            else concat($config:app-root, '/','search-config.xml')
                        return 
                            if(doc-available($search-config)) then 
                                doc($search-config)//*:search-tips
                            else ()
                        }
                    </div>
                 </div>
                else ()
             else ()
             }
            <div>
                {if($search-string = ('yes','Yes')) then attribute class { "col-md-7" } else attribute class { "col-md-12" } }
                {
                if($total-result-count gt $perpage) then 
                <ul class="pagination pull-right">
                    {((: Show 'Previous' for all but the 1st page of results :)
                        if ($current-page = 1) then ()
                        else <li><a href="{concat($param-string, $perpage * ($current-page - 2)) }">Prev</a></li>,
                        (: Show links to each page of results :)
                        let $max-pages-to-show := 8
                        let $padding := xs:integer(round($max-pages-to-show div 2))
                        let $start-page := 
                                      if ($current-page le ($padding + 1)) then
                                          1
                                      else $current-page - $padding
                        let $end-page := 
                                      if ($number-of-pages le ($current-page + $padding)) then
                                          $number-of-pages
                                      else $current-page + $padding - 1
                        for $page in ($start-page to $end-page)
                        let $newstart := 
                                      if($page = 1) then 1 
                                      else $perpage * ($page - 1)
                        return 
                            if ($newstart eq $start) then <li class="active"><a href="#" >{$page}</a></li>
                             else <li><a href="{concat($param-string, $newstart)}">{$page}</a></li>,
                        (: Shows 'Next' for all but the last page of results :)
                        if ($start + $perpage ge $total-result-count) then ()
                        else <li><a href="{concat($param-string, $start + $perpage)}">Next</a></li>,
                        if($sort-options != '') then page:sort($param-string, $start, $sort-options)
                        else(),
                        if($search-string != '') then
                            <li class="pull-right search-new"><a href="search.html"><span class="glyphicon glyphicon-search"/> New</a></li>
                        else ()    
                        )}
                </ul>
                else 
                <ul class="pagination pull-right">
                {(
                    if($sort-options != '') then page:sort($param-string, $start, $sort-options)
                    else(),
                    if($search-string = ('yes','Yes')) then   
                        <li class="pull-right"><a href="search.html" class="clear-search"><span class="glyphicon glyphicon-search"/> New</a></li>
                    else() 
                    )}
                </ul>
                }
            </div>
    </div>
};

(:~
 : Build sort options menu for search/browse results
 : $param @param-string search parameters passed from URL, empty for browse
 : $param @start start number passed from url 
 : $param @options include search options a comma separated list
:)
declare function page:sort($param-string as xs:string?, $start as xs:integer?, $options as xs:string*){
let $cleanParams :=
        string-join(
        for $pramName in request:get-parameter-names()
        return 
            if($pramName = ('start','perpage','sort-element','sort')) then () 
            else 
                for $param in request:get-parameter($pramName, '')
                where $param != ''
                return ($pramName || '=' || $param)
                ,'&amp;')
let $param-string := 
        if($cleanParams != '') then 
            ('?' || $cleanParams ||'&amp;start=')
        else '?start='                
return 
<li xmlns="http://www.w3.org/1999/xhtml">
    <div class="btn-group">
        <div class="dropdown"><button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">Sort <span class="caret"/></button>
            <ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dropdownMenu1">
                {
                    for $option in tokenize($options,',')
                    return 
                    <li role="presentation">
                        <a role="menuitem" tabindex="-1" href="{($param-string || $start || '&amp;sort-element=' || $option)}" id="rel">
                            {
                                if($option = 'pubDate' or $option = 'persDate') then 'Date'
                                else if($option = 'pubPlace') then 'Place of publication'
                                else functx:capitalize-first($option)
                            }
                        </a>
                    </li>
                }
            </ul>
        </div>
    </div>
</li>
};

(:~
 : User friendly display of search parameters for HTML pages
 : Filters out $start, $sort-element and $perpage parameters. 
:)
declare function page:display-search-params($collection as xs:string?){
<span xmlns="http://www.w3.org/1999/xhtml">
{(
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
    return 
        if(request:get-parameter($parameter, '') != '') then
            if($parameter = 'start' or $parameter = 'sort-element' or $parameter = 'fq') then ()
            else if($parameter = ('q','keyword')) then 
                (<span class="param">Keyword: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160;</span>)
            else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)    
        else ())
        }
</span>
};