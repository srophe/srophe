xquery version "3.0";
(:~
 : Builds search information for spear sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace bibls="http://syriaca.org/srophe/bibls";
import module namespace functx="http://www.functx.com";

import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";
import module namespace data="http://syriaca.org/srophe/data" at "../lib/data.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "../lib/global.xqm";
import module namespace facet="http://expath.org/ns/facet" at "facet.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $bibls:title {request:get-parameter('title', '')};
declare variable $bibls:author {request:get-parameter('author', '')};
declare variable $bibls:idno {request:get-parameter('idno', '')};
declare variable $bibls:subject {request:get-parameter('subject', '')};
declare variable $bibls:id-type {request:get-parameter('id-type', '')};
declare variable $bibls:pub-place {request:get-parameter('pub-place', '')};
declare variable $bibls:publisher {request:get-parameter('publisher', '')};
declare variable $bibls:date {request:get-parameter('date', '')};
declare variable $bibls:start-date {request:get-parameter('start-date', '')};
declare variable $bibls:end-date {request:get-parameter('end-date', '')};
declare variable $bibls:online {request:get-parameter('online', '')};


declare function bibls:title() as xs:string? {
    if($bibls:title != '') then concat("[ft:query(descendant::tei:title,'",data:clean-string($bibls:title),"',data:search-options())]")
    else ()    
};

declare function bibls:author() as xs:string? {
    if($bibls:author != '') then concat("[ft:query(descendant::tei:author,'",data:clean-string($bibls:author),"',data:search-options()) or ft:query(descendant::tei:editor,'",data:clean-string($bibls:author),"',data:search-options())]")
    else ()    
};

(:
 : NOTE: Forsee issues here if users want to seach multiple ids at one time. 
 : Thinking of how this should be enabled. 
:)
declare function bibls:idno() as xs:string? {
    if($bibls:idno != '') then  
            if($bibls:id-type != '') then concat("[descendant::tei:idno[@type='",$bibls:id-type,"'][matches(.,'",$bibls:idno,"$')]]")
            else concat("[descendant::tei:idno[matches(.,'",$bibls:idno,"$')]]")

    (:
        let $id := replace($bibls:idno,'[^\d\s]','')
        let $syr-id := concat('http://syriaca.org/bibl/',$id)
        return 
            if($bibls:id-type != '') then concat("[descendant::tei:idno[@type='",$bibls:id-type,"'][normalize-space(.) = '",$id,"']]")
            else concat("[descendant::tei:idno[normalize-space(.) = '",$id,"' or .= '",$syr-id,"']]")
    :)            
    else ()    
};

declare function bibls:pub-place() as xs:string? {
    if($bibls:pub-place != '') then 
        concat("[ft:query(descendant::tei:imprint/tei:pubPlace,'",data:clean-string($bibls:pub-place),"',data:search-options())]")
    else ()  
};

declare function bibls:publisher() as xs:string? {
    if($bibls:publisher != '') then 
        concat("[ft:query(descendant::tei:imprint/tei:publisher,'",data:clean-string($bibls:publisher),"',data:search-options())]")
    else ()  
};

declare function bibls:date() as xs:string? {
    if($bibls:date != '') then 
        concat("[ft:query(descendant::tei:imprint/tei:date,'",data:clean-string($bibls:date),"',data:search-options())]")
    else ()  
};

declare function bibls:online() as xs:string? {
    if($bibls:online = 'on') then 
        "[descendant::tei:idno[not(matches(.,'^(https://biblia-arabica.com|https://www.zotero.org|https://api.zotero.org)'))] or descendant::tei:ref/@target[not(matches(.,'^(https://biblia-arabica.com|https://www.zotero.org|https://api.zotero.org)'))]]"
    else ()  
};

(:~
 : Build date search string
 : @param $bibls:date-type indicates element to restrict date searches on, if empty, no element restrictions
 : @param $bibls:start-date start date
 : @param $bibls:end-date end date       
:)
declare function bibls:date-range() as xs:string?{
    if($bibls:start-date != '' and $bibls:end-date != '') then 
        concat("[descendant::tei:imprint/tei:date[(. >='", global:make-iso-date($bibls:start-date),"') and (. <= '",global:make-iso-date($bibls:end-date) ,"')]]")
    else if($bibls:start-date != ''  and $bibls:end-date = '') then
        concat("[descendant::tei:imprint/tei:date[. >= '",global:make-iso-date($bibls:start-date),"']]")
    else if($bibls:end-date != ''  and $bibls:start-date = '') then
        concat("[descendant::tei:imprint/tei:date[. <= '",global:make-iso-date($bibls:end-date) ,"']]")
    else ()
}; 

declare function bibls:subject() as xs:string?{
    if(request:get-parameter('subject', '') != '' or request:get-parameter('subject-exact', '')) then 
        if(request:get-parameter('subject', '')) then 
            concat("[descendant::tei:relation[@ref='dc:subject']/descendant::tei:desc[ft:query(.,'",data:clean-string(request:get-parameter('subject', '')),"',data:search-options())]]")     
        else if(request:get-parameter('subject-exact', '')) then 
            concat("[descendant::tei:relation[@ref='dc:subject']/descendant::tei:desc[. = '",request:get-parameter('subject-exact', ''),"']]")
        else()
    else ()  
};

declare function bibls:mss() as xs:string?{
    if(request:get-parameter('mss', '') != '') then
        concat("[descendant::tei:relation[@ref='dcterms:references']/descendant::tei:desc[ft:query(.,'",data:clean-string(request:get-parameter('mss', '')),"',data:search-options())]]")
    else ()  
};

(:~     
 : Build query string to pass to search.xqm 
:)
declare function bibls:query-string() as xs:string? { 
 concat("collection('",$config:data-root,"/bibl/tei')//tei:TEI",facet:facet-filter(global:facet-definition-file('bibl')),
    data:keyword-search(),
    bibls:title(),
    bibls:author(),
    bibls:pub-place(),
    bibls:publisher(),
    bibls:date(),
    bibls:date-range(),
    bibls:subject(),
    bibls:mss(),
    bibls:online(),
    bibls:idno()
    )
};

(:~
 : Build a search string for search results page from search parameters
:)
declare function bibls:search-string(){
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
        return 
            if(request:get-parameter($parameter, '') != '') then
                if($parameter = 'start' or $parameter = 'sort-element') then ()
                else if($parameter = 'q') then 
                    (<span class="param">Keyword: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
                else if ($parameter = 'author') then 
                    (<span class="param">Author/Editor: </span>,<span class="match">{$bibls:author}&#160; </span>)
                else if ($parameter = 'subject-exact') then 
                    (<span class="param">Subject: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)    
                else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)    
            else ()               
};

(: BA specific function to list all available subjects for dropdown list in search form :)
declare function bibls:get-subjects(){
 for $s in collection($config:data-root)//tei:relation[@ref='dc:subject']/descendant::tei:desc
 group by $subject-facet := $s/text()
 order by global:build-sort-string($subject-facet,'')
 return <option value="{$subject-facet}">{$subject-facet}</option>
};

(:~
 : Builds advanced search form for persons
 :)
declare function bibls:search-form() {   
<form method="get" action="search.html" xmlns:xi="http://www.w3.org/2001/XInclude"  class="form-horizontal" role="form">
    <div class="well well-small">
        {let $search-config := 
                if(doc-available(concat($config:app-root, '/bibl/search-config.xml'))) then concat($config:app-root, '/bibl/search-config.xml')
                else concat($config:app-root, '/search-config.xml')
            let $config := 
                if(doc-available($search-config)) then doc($search-config)
                else ()                            
            return 
                if($config != '' or doc-available($config:app-root || '/searchTips.html')) then 
                    (<button type="button" class="btn btn-info pull-right clearfix search-button" data-toggle="collapse" data-target="#searchTips">
                        Search Help <span class="glyphicon glyphicon-question-sign" aria-hidden="true"></span></button>,                       
                    if($config//search-tips != '') then
                        <div class="panel panel-default collapse" id="searchTips">
                            <div class="panel-body">
                            <h3 class="panel-title">Search Tips</h3>
                            {$config//search-tips}
                            </div>
                        </div>
                    else if(doc-available($config:app-root || '/searchTips.html')) then doc($config:app-root || '/searchTips.html')
                    else ())
                else ()}
        <div class="well well-small search-inner well-white">
        <!-- Keyword -->
            <div class="form-group">            
                <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                        <input type="text" id="qs" name="q" class="form-control keyboard" placeholder="Any word in citation"/>
                        <div class="input-group-btn">{global:keyboard-select-menu('qs')}</div>
                    </div>                 
                </div>
            </div> 
            <hr/>         
            <div class="form-group">            
                <label for="title" class="col-sm-2 col-md-3  control-label">Title: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                        <input type="text" id="title" name="title" class="form-control keyboard"  placeholder="Title of article, journal, book, or series"/>
                        <div class="input-group-btn">{global:keyboard-select-menu('title')}</div>
                    </div>                 
                </div>
            </div>
            <div class="form-group">            
                <label for="author" class="col-sm-2 col-md-3  control-label">Author/Editor: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                        <input type="text" id="author" name="author" class="form-control keyboard" placeholder="First Last or Last, First"/>
                        <div class="input-group-btn">{global:keyboard-select-menu('author')}</div>
                    </div>                
                </div>
            </div>  
            <!--
            <div class="form-group">            
                <label for="subject" class="col-sm-2 col-md-3  control-label">Subject: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                        <input type="text" id="subject" name="subject" class="form-control keyboard"  placeholder="Subject"/>
                        <div class="input-group-btn">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                {global:keyboard-select-menu('subject')}
                        </div>
                    </div>                 
                </div>
            </div>
            -->
            <div class="form-group">            
                <label for="subject-exact" class="col-sm-2 col-md-3  control-label">Select Subject: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                    <select name="subject-exact">
                        <option value="">Any subject</option>
                        {bibls:get-subjects()}
                    </select>
                    </div>                 
                </div>
            </div>
            <div class="form-group">            
                <label for="mss" class="col-sm-2 col-md-3  control-label">Manuscript: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                        <input type="text" id="mss" name="mss" class="form-control keyboard"  placeholder="Manuscript"/>
                        <div class="input-group-btn">{global:keyboard-select-menu('mss')}</div>
                    </div>                 
                </div>
            </div>            
            <div class="form-group">            
                <label for="pub-place" class="col-sm-2 col-md-3  control-label">Publication Place: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                        <input type="text" id="pubPlace" name="pub-place" class="form-control keyboard" placeholder="First Last or Last, First"/>
                        <div class="input-group-btn">{global:keyboard-select-menu('pubPlace')}</div>
                    </div>                
                </div>
            </div>
            <div class="form-group">            
                <label for="publisher" class="col-sm-2 col-md-3  control-label">Publisher: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                    <input type="text" id="publisher" name="publisher" class="form-control keyboard" placeholder="Publisher Name"/>
                    <div class="input-group-btn">{global:keyboard-select-menu('publisher')}</div>
                    </div>                 
                </div>
            </div>
            <!--
            <div class="form-group">            
                <label for="date" class="col-sm-2 col-md-3  control-label">Date: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="date" name="date" class="form-control" placeholder="Year as YYYY"/>
                </div>
            </div> 
            -->
            <div class="form-group">
                <label for="start-date" class="col-sm-2 col-md-3  control-label">Date: </label>
                <div class="col-sm-10 col-md-6 form-inline">
                    <input type="text" id="start-date" name="start-date" placeholder="Start Date" class="form-control"/>&#160;
                    <input type="text" id="end-date" name="end-date" placeholder="End Date" class="form-control"/>&#160;
                    <p class="hint">* Dates should be entered as YYYY or YYYY-MM-DD. Add a minus sign (-) in front of BC dates. <span><a href="http://syriaca.org/documentation/dates.html">more <i class="glyphicon glyphicon-circle-arrow-right"></i></a></span></p>
                </div>
            </div>  
            <hr/>
            <div class="form-group">            
                <label for="idno" class="col-sm-2 col-md-3  control-label">ISBN / DOI / URI: </label>
                <div class="col-sm-10 col-md-2 ">
                    <input type="text" id="idno" name="idno" class="form-control"  placeholder="Ex: 3490"/>
                </div>
            </div>
            <div class="form-group">     
                <label for="idno" class="col-sm-2 col-md-3  control-label">Only items viewable online: </label>
                <div class="col-sm-10 col-md-2 ">
                    <label class="switch">
                        <input id="online" name="online" type="checkbox"/>
                        <span class="slider round"></span>
                    </label>
                </div>
            </div> 
        </div>
        <div class="pull-right">
            <button type="submit" class="btn btn-info">Search</button>&#160;
            <button type="reset" class="btn">Clear</button>
        </div>
        <br class="clearfix"/><br/>
    </div>
</form>
};