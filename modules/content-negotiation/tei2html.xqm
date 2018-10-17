xquery version "3.0";
(:~
 : Builds tei conversions. 
 : Used by oai, can be plugged into other outputs as well.
 :)
 
module namespace tei2html="http://syriaca.org/srophe/tei2html";
import module namespace bibl2html="http://syriaca.org/srophe/bibl2html" at "bibl2html.xqm";
import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";

declare namespace html="http://purl.org/dc/elements/1.1/";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace util="http://exist-db.org/xquery/util";

(:~
 : Simple TEI to HTML transformation
 : @param $node   
:)
declare function tei2html:tei2html($nodes as node()*) as item()* {
    for $node in $nodes
    return 
        typeswitch($node)
            case text() return $node
            case comment() return ()
            case element(tei:biblScope) return element span {
                let $unit := if($node/@unit = 'vol') then concat($node/@unit,'.') 
                             else if($node[@unit != '']) then string($node/@unit) 
                             else if($node[@type != '']) then string($node/@type)
                             else () 
                return 
                    if(matches($node/text(),'^\d')) then concat($unit,' ',$node/text())
                    else if(not($node/text()) and ($node/@to or $node/@from)) then  concat($unit,' ',$node/@from,' - ',$node/@to)
                    else $node/text()
            }
            case element(tei:category) return element ul {tei2html:tei2html($node/node())}
            case element(tei:catDesc) return element li {tei2html:tei2html($node/node())}
            
            case element(tei:imprint) return element span {
                    if($node/tei:pubPlace/text()) then $node/tei:pubPlace[1]/text() else (),
                    if($node/tei:pubPlace/text() and $node/tei:publisher/text()) then ': ' else (),
                    if($node/tei:publisher/text()) then $node/tei:publisher[1]/text() else (),
                    if(not($node/tei:pubPlace) and not($node/tei:publisher) and $node/tei:title[@level='m']) then <abbr title="no publisher">n.p.</abbr> else (),
                    if($node/tei:date/preceding-sibling::*) then ', ' else (),
                    if($node/tei:date) then $node/tei:date else <abbr title="no date of publication">n.d.</abbr>,
                    if($node/following-sibling::tei:biblScope[@unit='series']) then ', ' else ()
            }
            case element(tei:label) return element span {tei2html:tei2html($node/node())}
            case element(tei:orig) return 
                <span class="tei-orig">{
                if($node/tei:date) then 
                    <span class="tei-date">{(' (',tei2html:tei2html($node/tei:date),')')}</span>
                else tei2html:tei2html($node/node())
                }</span>
            case element(tei:placeName) return 
                <span class="tei-placeName">{
                    let $name := tei2html:tei2html($node/node())
                    return
                        if($node/@ref) then
                            element a { attribute href { $node/@ref }, $name }
                        else $name                                 
                        }</span>
            case element(tei:persName) return 
                <span class="tei-persName">{
                    let $name := if($node/child::*) then 
                                    for $part in $node/child::*
                                    order by $part/@sort ascending, string-join($part/descendant-or-self::text(),' ') descending
                                    return tei2html:tei2html($part/node())
                                 else tei2html:tei2html($node/node())
                    return
                        if($node/@ref) then
                            element a { attribute href { $node/@ref }, $name }
                        else $name                                 
                        }</span>
            case element(tei:title) return 
                let $titleType := 
                        if($node/@level='a') then 
                            'title-analytic'
                        else if($node/@level='m') then 
                            'title-monographic'
                        else if($node/@level='j') then 
                            'title-journal'
                        else if($node/@level='s') then 
                            'title-series'
                        else if($node/@level='u') then 
                            'title-unpublished'
                        else if($node/parent::tei:persName) then 
                            'title-person'                             
                        else ()
                return  
                    <span class="tei-title {$titleType}"> {
                        (if($node/@xml:lang) then attribute lang { $node/@xml:lang } else (),
                        if($node/child::*) then 
                            ($node/text(),
                            for $part in $node/child::*
                            return tei2html:tei2html($part/node()))
                        else tei2html:tei2html($node/node()))                 
                    }</span>
            default return tei2html:tei2html($node/node())
};

(:~ 
 : Display idno with copy icon and paging (if relevant)
:)
declare function tei2html:idno-title-display($id){
    let $id-string := substring-after(tokenize($id,'/')[last()],'-')
    let $id-num := if($id-string castable as xs:integer) then $id-string cast as xs:integer else 0
    let $next := $id-num + 1
    let $prev := $id-num - 1
    let $next-url := concat(substring-before($id,'-'),'-',string($next))
    let $prev-url := concat(substring-before($id,'-'),'-',string($prev))
    return 
        <div style="margin:0 1em 1em; color: #999999;" xmlns="http://www.w3.org/1999/xhtml">
            <small>
                <span class="uri">
                    <a href="{replace($prev-url, $config:base-uri, $config:nav-base)}"><span class="glyphicon glyphicon-backward" aria-hidden="true"/></a>
                    &#160;<button type="button" class="btn btn-default btn-xs" id="idnoBtn" data-clipboard-action="copy" data-clipboard-target="#syriaca-id">
                        <span class="srp-label">URI</span>
                    </button>&#160;
                    <span id="syriaca-id">{$id}</span>
                    <script>
                        <![CDATA[
                            var clipboard = new Clipboard('#idnoBtn');
                            clipboard.on('success', function(e) {
                            console.log(e);
                            });
                            
                            clipboard.on('error', function(e) {
                            console.log(e);
                            });]]>
                    </script>
                    <a href="{replace($next-url,$config:base-uri, $config:nav-base)}"><span class="glyphicon glyphicon-forward" aria-hidden="true"/></a>
                </span>
            </small>
        </div>
};

(:
 : Used for short views of records, browse, search or related items display. 
:)
declare function tei2html:summary-view($nodes as node()*, $lang as xs:string?, $id as xs:string?) as item()* {
    let $id := if($id) then 
                    if(ends-with($id,'/tei')) then
                        replace($id,'/tei','')
                    else $id 
                else replace($nodes/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='URL'],'/tei','')
    let $title := if($nodes/descendant-or-self::tei:title[@syriaca-tags='#syriaca-headword'][@xml:lang='en']) then 
                    $nodes/descendant-or-self::tei:title[@syriaca-tags='#syriaca-headword'][@xml:lang='en'][1]/text()
                  else $nodes/descendant-or-self::tei:title[1]/text()
    let $series := for $a in distinct-values($nodes/descendant::tei:seriesStmt/tei:biblScope/tei:title)
                   return $a
    return 
        <div class="short-rec-view">
            <div>{string($nodes/@sort)}</div>
            <a href="{replace($id,$config:base-uri,$config:nav-base)}" dir="ltr">{$title}</a>
            <button type="button" class="btn btn-sm btn-default copy-sm clipboard"  
                data-toggle="tooltip" title="Copies record title &amp; URI to clipboard." 
                data-clipboard-action="copy" data-clipboard-text="{normalize-space($title[1])} - {normalize-space($id[1])}">
                    <span class="glyphicon glyphicon-copy" aria-hidden="true"/>
            </button>
            {if($series != '') then <span class="results-list-desc type" dir="ltr" lang="en">{(' (',$series,') ')}</span> else ()}
            {if($nodes/descendant-or-self::*[starts-with(@xml:id,'abstract')]) then 
                for $abstract in $nodes/descendant::*[starts-with(@xml:id,'abstract')]
                let $string := string-join($abstract/descendant-or-self::*/text(),' ')
                let $blurb := 
                    if(count(tokenize($string, '\W+')[. != '']) gt 25) then  
                        concat(string-join(for $w in tokenize($string, '\W+')[position() lt 25]
                        return $w,' '),'...')
                     else $string 
                return 
                    <span class="results-list-desc desc" dir="ltr" lang="en">{
                        if($abstract/descendant-or-self::tei:quote) then concat('"',normalize-space($blurb),'"')
                        else $blurb
                    }</span>
            else()}
            {
            if($id != '') then 
            <span class="results-list-desc uri"><span class="srp-label">URI: </span><a href="{replace($id,$config:base-uri,$config:nav-base)}">{$id}</a></span>
            else()
            }
        </div>   
};

(:~ 
 : Reworked  KWIC to be more 'Google like' 
 : Passes content through  tei2html:kwic-format() to output only text and matches 
 : Note: could be made more robust to match proximity operator, it it is greater the 10 it may be an issue.
 : To do, pass search params to record, highlight hits in record 
   let $search-params := 
        string-join(
            for $param in request:get-parameter-names()
            return 
                if($param = ('fq','start')) then ()
                else if(request:get-parameter($param, '') = ' ') then ()
                else concat('&amp;',$param, '=',request:get-parameter($param, '')),'')
:)
declare function tei2html:output-kwic($nodes as node()*, $id as xs:string*){
    let $results := <results xmlns="http://www.w3.org/1999/xhtml">{tei2html:kwic-format($nodes)}</results>
    let $count := count($results//*:match)
    for $node at $p in subsequence($results//*:match,1,8)
    let $prev := $node/preceding-sibling::text()[1]
    let $next := $node/following-sibling::text()[1]
    let $prevString := 
        if(string-length($prev) gt 60) then 
            concat(' ...',substring($prev,string-length($prev) - 100, 100))
        else $prev
    let $nextString := 
        if(string-length($next) lt 100 ) then () 
        else concat(substring($next,1,100),'... ')
    let $link := concat($config:nav-base,'/',tokenize($id,'/')[last()],'#',$node/@n)
    return 
        <span>{$prevString}&#160;<span class="match" style="background-color:yellow;"><a href="{$link}">{$node/text()}</a></span>&#160;{$nextString}</span>
};

(:~
 : Strips results to just text and matches. 
 : Note, could pass though tei2html:tei2html() to hide hidden content (choice/orig)
:)
declare function tei2html:kwic-format($nodes as node()*){
    for $node in $nodes
    return 
        typeswitch($node)
            case text() return $node
            case comment() return ()
            case element(exist:match) return 
                let $n := if($node/ancestor-or-self::*[@n]) then concat('Head-id.',$node/ancestor-or-self::*[@n][1]/@n) else ()
                return 
                <match xmlns="http://www.w3.org/1999/xhtml">
                    {(if($n != '') then attribute n {$n} else (), 
                    $node/node()
                    )}
                </match>
            default return tei2html:kwic-format($node/node())                
};