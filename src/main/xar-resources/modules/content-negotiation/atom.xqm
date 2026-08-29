xquery version "3.0";
(:
 : Build atom feed for all syrica.org modules
 : Module is used by atom.xql and rest.xqm 
 : @param $collection selects data collection for feed 
 : @param $id return single entry matching xml:id
 : @param $start start paged results
 : @param $perpage default set to 25 can be changed via perpage param
:)
module namespace feed="http://srophe.org/srophe/atom";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace georss="http://www.georss.org/georss";

declare option exist:serialize "method=xml media-type=application/rss+xml omit-xml-declaration=no indent=yes";

(:~
 : Return subsequence of full feed passed from search results or search api
 : @param $nodes name of syriaca.org subcollection 
 : @param $start start position for results
 : @param $perpage number of pages to return 
 : @return An atom entry element
:)
declare function feed:build-search-feed($nodes as node()*,$start as xs:integer?, $perpage as xs:integer?){
    for $rec in subsequence($nodes,$start, $perpage)
    return feed:build-entry($rec)
};

(:~
 : @depreciated
 : Get most recently updated date from feed results
 : @param $collection name of syriaca.org subcollection 
 : @return A string
:)
(:
declare function feed:updated-date($collection as xs:string?) as xs:string?{
    for $recent in feed:get-feed($collection)[1]
    let $date := $recent/ancestor::tei:TEI//tei:publicationStmt[1]/tei:date[1]/text()
    return $date
};
:)

(:~
 : Correctly format dates in the TEI
 : @param $date date passed from TEI records
 : @return A string
:)
declare function feed:format-dates($date as xs:string?) as xs:string?{
    if($date) then 
        if(string-length($date) = 10) then concat($date,'T12:00:00Z')
        else if(string-length($date) = 4) then concat($date,'01-01T12:00:00Z')
        else if(string-length($date) gt 10) then concat(substring($date,1,10),'T12:00:00Z')
        else ()
    else ()
};

(:~
 : Get single entry 
 : @param $node tei data passed to library function 
 : @param $id record id
 : @return As atom feed element
:)
declare function feed:get-entry($node as node()?) as element()?{ 
    let $rec := if($node/self::tei:TEI) then $node else $node/ancestor::tei:TEI
    let $subtitle := if($rec//tei:titleStmt/tei:title[2]) then concat(': ',$rec//tei:titleStmt/tei:title[2]) else ()
    let $title := concat(string($rec//tei:titleStmt/tei:title[1]),$subtitle)
    let $date := $node[1]//tei:publicationStmt[1]/tei:date[1]/text()
    let $rec-id := substring-before($rec//tei:idno[@type='URI'][starts-with(.,'http://syriaca.org/')][1],'/tei')
    return 
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:georss="http://www.georss.org/georss"> 
            <title>{$title}</title>
            <link rel="self" type="application/atom+xml" href="{$rec-id}/atom"/>
            <id>tag:syriaca.org,2013:{$rec-id}/atom</id>
            <updated xmlns="http://www.w3.org/2005/Atom">{feed:format-dates($date)}</updated>
            {feed:build-entry($rec)}
        </feed>
};
 
(:~
 : Build atom entry from TEI record data
 : @param $rec TEI record
 : @return A atom entry element
:)
declare function feed:build-entry($node as element()*) as element(entry){
    let $rec := if($node/self::tei:TEI) then $node else $node/ancestor::tei:TEI
    let $rec-id := substring-before($rec//tei:idno[@type='URI'][starts-with(.,'http://syriaca.org/')][1],'/tei')
    let $subtitle := if($rec//tei:titleStmt/tei:title[2]) then concat(': ',$rec//tei:titleStmt/tei:title[2]) else ()
    let $title := concat(string($rec//tei:titleStmt/tei:title[1]),$subtitle)
    let $date := $rec//tei:publicationStmt[1]/tei:date[1]/text()
    let $geo := if($rec//tei:geo) then <georss:point>{string($rec//tei:geo)}</georss:point> else ()         
    let $res-pers :=  
                let $author-name := distinct-values($rec//tei:titleStmt/tei:editor) 
                for $author in $author-name
                return <author xmlns="http://www.w3.org/2005/Atom"><name>{$author}</name></author>
    let $summary := 
        if($rec//tei:desc[contains(@xml:id,'abstract')]) then
            <summary xmlns="http://www.w3.org/2005/Atom">
                {
                    for $sum in $rec//tei:desc[contains(@xml:id,'abstract')]
                    return feed:tei2atom($sum)
                }
            </summary>
        else ()
    return    
    <entry xmlns="http://www.w3.org/2005/Atom" xmlns:georss="http://www.georss.org/georss">
        <title>{normalize-space($title)}</title>
        <link rel="alternate" type="text/html" href="{$rec-id}"/>
        <link rel="alternate" type="text/xml" href="{$rec-id}/tei"/>
        <link rel="self" type="application/atom+xml" href="{$rec-id}/atom"/>
        <id>tag:syriaca.org,2013:{$rec-id}</id>
        {$geo}
        <updated>{feed:format-dates($date)}</updated>
        {($summary, $res-pers)}
    </entry>  
};

(:~
 : Build atom feed
 : @param $nodes passed to module from search or browse 
 : @param $start
 : @param $perpage
 : @return A atom feed element
:)
declare function feed:build-atom-feed($nodes as node()*, $start as xs:integer?, $perpage as xs:integer?, $q as xs:string*, $total as xs:integer?) as element(feed)?{
let $self := 
            if($q != '') then concat('http://syriaca.org/api/search?q=', $q) 
            else 'http://syriaca.org/api/atom'
let $next := 
            if($total gt $perpage) then 
                if($q !='') then 
                    <link rel="next" href="{concat('http://syriaca.org/api/search?q=', $q,'&amp;start=',$start + $perpage)}"/>
                else 
                    <link rel="next" href="{concat('http://syriaca.org/api/atom?start=',$start + $perpage)}"/>
            else ()
let $last :=
            if($total gt $perpage) then 
                if($q !='') then <link rel="last" href="{concat('http://syriaca.org/api/search?q=', $q,'&amp;start=',$total - $perpage)}"/>
                else <link rel="last" href="{concat('http://syriaca.org/api/atom?start=',$total - $perpage)}"/>
                
            else ()    
let $title := if($q !='') then concat(':search.api.results.',$q) 
            else ()
return             
    <feed xmlns="http://www.w3.org/2005/Atom" xmlns:georss="http://www.georss.org/georss"> 
        <title>Syriaca.org: {$total} Results</title>
        <link href="http://syriaca.org/"/>
        <link rel="self" type="application/atom+xml" href="{$self}"/>
        {($next)}
        <id>tag:syriaca.org,2013{$title}</id>
        <updated xmlns="http://www.w3.org/2005/Atom">{feed:format-dates($nodes[1]//tei:publicationStmt[1]/tei:date[1])}</updated>
        <author>
          <name>syriaca.org</name>
        </author>
        {feed:build-search-feed($nodes,$start,$perpage)}
    </feed>
};

(:~
 : Typeswitch to output all child elements in atom summary
 : @param $node elements passed to function
:)
declare function feed:tei2atom($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case text() return
                $node
            case comment() return ()
            case element() return
                feed:tei2atom($node/node())
            default return
                $node/string()
};