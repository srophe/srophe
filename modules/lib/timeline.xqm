xquery version "3.0";

module namespace timeline="http://srophe.org/srophe/timeline";

(:~
 : Module to build timeline json passed to http://cdn.knightlab.com/libs/timeline/latest/js/storyjs-embed.js widget
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2014-08-05
:)
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
import module namespace global="http://srophe.org/srophe/global" at "global.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


declare variable $timeline:startDate {request:get-parameter('startDate', '')};
declare variable $timeline:startDateFormated {
    if(empty($timeline:startDate)) then ()
    else if(starts-with($timeline:startDate,'-')) then concat('-',tokenize($timeline:startDate,'-')[2])
    else replace($timeline:startDate,'-',',')
};

(:
 : Display Timeline. Uses http://timeline.knightlab.com/
:)
declare function timeline:timeline($data as node()*, $title as xs:string*){
(: Test for valid dates json:xml-to-json() May want to change some css styles for font:)
if($data/descendant-or-self::*[@when or @to or @from or @notBefore or @notAfter]) then 
    <div class="timeline">
        <script type="text/javascript" src="http://cdn.knightlab.com/libs/timeline/latest/js/storyjs-embed.js"/>
        <script type="text/javascript">
        <![CDATA[
            $(document).ready(function() {
                var parentWidth = $(".timeline").width();
                createStoryJS({
                    start:      'start_at_end',
                    type:       'timeline',
                    width:      "'" +parentWidth+"'",
                    height:     '450',
                    source:     ]]>{timeline:get-all-dates($data, $title)}<![CDATA[,
                    embed_id:   'srophe-timeline'
                    });
                });
                ]]>
        </script>
    <div id="my-timeline"/>
    <p>*Timeline generated with <a href="http://timeline.knightlab.com/">http://timeline.knightlab.com/</a></p>
    </div>
else ()
};

(:
 : Display Timeline. Uses http://timeline.knightlab.com/
:)
declare function timeline:timeline($data as node()*, $title as xs:string*, $xpath as xs:string*){
(: Test for valid dates json:xml-to-json() May want to change some css styles for font:)
if($data/descendant-or-self::*[@when or @to or @from or @notBefore or @notAfter]) then 
    <div class="timeline">
        <script type="text/javascript" src="http://cdn.knightlab.com/libs/timeline/latest/js/storyjs-embed.js"/>
        <script type="text/javascript">
        <![CDATA[
            $(document).ready(function() {
                var dates = ]]>{if($xpath != '') then timeline:get-date-xpath($data, $title, $xpath) else timeline:get-all-dates($data, $title)}<![CDATA[;
                //var start_index = 0;
                var target_date = ']]>{if(request:get-parameter('startDate', '') != '') then $timeline:startDateFormated else 'start_at_end'}<![CDATA[';
                var dateArray = dates.timeline.date
                index = dateArray.findIndex(x => x.startDate === target_date);
                
                var target_id = ']]>{if(request:get-parameter('slideID', '') != '') then request:get-parameter('slideID', '') else 'start_at_end'}<![CDATA[';
                var slideID =  dateArray.findIndex(x => x.id === target_id);
                console.log('Index: ' + slideID + ' target-id ' + target_id);
                
                var parentWidth = $(".timeline").width();
                createStoryJS({
                    //start:      'start_at_end',
                    start_at_slide: slideID,
                    type:       'timeline',
                    width:      "'" +parentWidth+"'",
                    height:     '450',
                    source:     dates,
                    embed_id:   'my-timeline'
                    });
                });
                ]]>
        </script>
    <div id="my-timeline"/>
    <p>*Timeline generated with <a href="http://timeline.knightlab.com/">http://timeline.knightlab.com/</a></p>
    </div>
else ()
};

(:
 : Format specified dates as JSON to be passed to timeline widget.
:)
declare function timeline:get-date-xpath($data as node()*, $title as xs:string*, $xpath as xs:string*){
let $timeline-title := if($title != '') then $title else 'Timeline'
let $dates := 
    <root>
        <timeline>
            <headline>{$timeline-title}</headline>
            <type>default</type>
            <asset>
                <media>{$config:app-title}</media>
                <credit>{$config:app-title}</credit>
                <caption>{$timeline-title}</caption>
            </asset>
            <date>
                {for $p in $xpath
                 for $date in util:eval(concat('$data/descendant-or-self::', $p))
                 let $start :=  if($date/@when) then string($date/@when)
                                else if($date/@from) then string($date/@from)
                                else if($date/@notBefore) then string($date/@notBefore)
                                else if($date/tei:date/@when) then string($date/tei:date[@when][1]/@when)
                                else if($date/tei:date/@from) then string($date/tei:date[@from][1]/@from)
                                else if($date/tei:date/@notBefore) then string($date/tei:date[@notBefore][1]/@notBefore)
                                else ()
                 let $end :=    if($date/@when) then string($date/@when)
                                else if($date/@to) then string($date/@to)
                                else if($date/@notAfter) then string($date/@notAfter)
                                else if($date/tei:date[@when][2]) then string($date/tei:date[@when][2]/@when)
                                else if($date/tei:date/@to) then string($date/tei:date[@to][2]/@to)
                                else if($date/tei:date/@notAfter) then string($date/tei:date[@notAfter][2]/@notAfter)
                                else ()  
                let $root := root($date)
                let $id := $root/descendant::tei:publicationStmt/tei:idno[@type='URI'][1]                  
                let $title := string-join($root//tei:titleStmt/tei:title[1]//text(),' ')
                let $link := replace(replace($id,$config:base-uri,$config:nav-base),'/tei','')
                order by $start, $title
                return                   
                    if($start != '' or $end != '') then 
                        timeline:format-dates($start, $end, $title, string-join($date/descendant-or-self::text(),' '), $link, $id)
                    else () 
                 }</date>
        </timeline>
    </root>
return
    serialize($dates, 
        <output:serialization-parameters>
            <output:method>json</output:method>
        </output:serialization-parameters>)

};

(:
 : Format dates as JSON to be passed to timeline widget.
:)
declare function timeline:get-all-dates($data as node()*, $title as xs:string*){
let $timeline-title := if($title != '') then $title else 'Timeline'
let $dates := 
    <root>
        <timeline>
            <headline>{$timeline-title}</headline>
            <type>default</type>
            <asset>
                <media>syriaca.org</media>
                <credit>Syriaca.org</credit>
                <caption>Events for {$timeline-title}</caption>
            </asset>
            <date>
                {(
                    timeline:get-birth($data), 
                    timeline:get-death($data), 
                    timeline:get-floruit($data), 
                    timeline:get-state($data), 
                    timeline:get-events($data)
                    )}</date>
        </timeline>
    </root>
return
    serialize($dates, 
        <output:serialization-parameters>
            <output:method>json</output:method>
        </output:serialization-parameters>)

};

declare function timeline:format-dates($start as xs:string*, $end as xs:string*, $headline as xs:string*, $text as xs:string* ){
    if($start != '' or $end != '') then 
        <json:value json:array="true">
            {(
                if($start != '' or $end != '') then 
                    <startDate>
                        {
                            if(empty($start)) then $end
                            else if(starts-with($start,'-')) then concat('-',tokenize($start,'-')[2])
                            else replace($start,'-',',')
                        }
                    </startDate>
                 else (),
                if($end != '') then 
                    <endDate>
                        {
                            if(starts-with($end,'-')) then concat('-',tokenize($end,'-')[2])
                            else replace($end,'-',',')
                        }
                    </endDate>
                 else (),
                 if($headline != '') then 
                    <headline>{$headline}</headline>
                 else (),
                 if($text != '') then 
                    <text>{$text}</text> 
                else ()                 
                )}
        </json:value>
    else ()
};

(: Dates with link to resource :)
declare function timeline:format-dates($start as xs:string*, $end as xs:string*, $headline as xs:string*, $text as xs:string*, $link as xs:string*, $id as xs:string?){
    if($start != '' or $end != '') then 
        <json:value json:array="true">
            {(
                if($start != '' or $end != '') then 
                    <startDate>
                        {
                            if(empty($start)) then $end
                            else if(starts-with($start,'-')) then concat('-',tokenize($start,'-')[2])
                            else replace($start,'-',',')
                        }
                    </startDate>
                 else (),
                if($end != '') then 
                    <endDate>
                        {
                            if(starts-with($end,'-')) then concat('-',tokenize($end,'-')[2])
                            else replace($end,'-',',')
                        }
                    </endDate>
                 else (),
                 if($headline != '') then 
                    <headline>{$headline}</headline>
                 else (),
                 if($text != '') then 
                    <text>{$text}<![CDATA[ <a href="]]>{$link}<![CDATA["><span class="glyphicon glyphicon-circle-arrow-right"></span></a>]]></text> 
                else (),
                <id>{$id}</id>
                )}
        </json:value>
    else ()
};

(:~
 : Build birth date ranges
 : @param $data as node
:)
declare function timeline:get-birth($data as node()*) as node()?{
    if($data/descendant-or-self::tei:birth) then
        let $birth-date := $data/descendant-or-self::tei:birth[1]
        let $start := if($birth-date/@when) then string($birth-date/@when)
                      else if($birth-date/@from) then string($birth-date/@from)
                      else if($birth-date/@notBefore) then string($birth-date/@notBefore)
                      else if($birth-date/tei:date/@when) then string($birth-date/tei:date[@when][1]/@when)
                      else if($birth-date/tei:date/@from) then string($birth-date/tei:date[@from][1]/@from)
                      else if($birth-date/tei:date/@notBefore) then string($birth-date/tei:date[@notBefore][1]/@notBefore)
                      else ()
        let $end :=   if($birth-date/@when) then string($birth-date/@when)
                      else if($birth-date/@to) then string($birth-date/@to)
                      else if($birth-date/@notAfter) then string($birth-date/@notAfter)
                      else if($birth-date/tei:date[@when][2]) then string($birth-date/tei:date[@when][2]/@when)
                      else if($birth-date/tei:date/@to) then string($birth-date/tei:date[@to][2]/@to)
                      else if($birth-date/tei:date/@notAfter) then string($birth-date/tei:date[@notAfter][2]/@notAfter)
                      else ()                    
        return
            timeline:format-dates($start, $end, concat(string-join($birth-date/descendant-or-self::text(),' '), ' Birth'), '')
    else () 
};

(:~
 : Build death date ranges
 : @param $data as node
:)
declare function timeline:get-death($data as node()*) as node()?{
       if($data/descendant-or-self::tei:death) then 
        let $death-date := $data//tei:death[1]
        let $start := if($death-date/@when) then string($death-date/@when)
                      else if($death-date/@from) then string($death-date/@from)
                      else if($death-date/@notBefore) then string($death-date/@notBefore)
                      else if($death-date/tei:date/@when) then string($death-date/tei:date[@when][1]/@when)
                      else if($death-date/tei:date/@from) then string($death-date/tei:date[@from][1]/@from)
                      else if($death-date/tei:date/@notBefore) then string($death-date/tei:date[@notBefore][1]/@notBefore)
                      else ()
        let $end :=   if($death-date/@when) then string($death-date/@when)
                      else if($death-date/@to) then string($death-date/@to)
                      else if($death-date/@notAfter) then string($death-date/@notAfter)
                      else if($death-date/tei:date[@when][2]) then string($death-date/tei:date[@when][2]/@when)
                      else if($death-date/tei:date/@to) then string($death-date/tei:date[@to][2]/@to)
                      else if($death-date/tei:date/@notAfter) then string($death-date/tei:date[@notAfter][2]/@notAfter)
                      else () 
        return timeline:format-dates($start, $end, concat(string-join($death-date/descendant-or-self::text(),' '), ' Death'), '')        
    else () 
};

(:~
 : Build floruit date ranges
 : @param $data as node
:)
declare function timeline:get-floruit($data as node()*) as node()*{
   if($data/descendant-or-self::tei:floruit) then 
        for $floruit-date in $data//tei:floruit
        let $start := if($floruit-date/@when) then string($floruit-date/@when)
                      else if($floruit-date/@from) then string($floruit-date/@from)
                      else if($floruit-date/@notBefore) then string($floruit-date/@notBefore)
                      else if($floruit-date/tei:date/@when) then string($floruit-date/tei:date[@when][1]/@when)
                      else if($floruit-date/tei:date/@from) then string($floruit-date/tei:date[@from][1]/@from)
                      else if($floruit-date/tei:date/@notBefore) then string($floruit-date/tei:date[@notBefore][1]/@notBefore)
                      else ()
        let $end :=   if($floruit-date/@when) then string($floruit-date/@when)
                      else if($floruit-date/@to) then string($floruit-date/@to)
                      else if($floruit-date/@notAfter) then string($floruit-date/@notAfter)
                      else if($floruit-date/tei:date[@when][2]) then string($floruit-date/tei:date[@when][2]/@when)
                      else if($floruit-date/tei:date/@to) then string($floruit-date/tei:date[@to][2]/@to)
                      else if($floruit-date/tei:date/@notAfter) then string($floruit-date/tei:date[@notAfter][2]/@notAfter)
                      else () 
        return timeline:format-dates($start, $end, concat(string-join($floruit-date/descendant-or-self::text(),' '), ' Floruit'), '')        
    else () 
};

(:~
 : Build state date ranges
 : @param $data as node
:)
declare function timeline:get-state($data as node()*) as node()*{
    if($data/descendant-or-self::tei:state) then 
        for $state-date in $data//tei:state
        let $start := if($state-date/@when) then string($state-date/@when)
                      else if($state-date/@notBefore) then string($state-date/@notBefore)
                      else if($state-date/@from) then string($state-date/@from)
                      else if($state-date/tei:date/@when) then string($state-date/tei:date[@when][1]/@when)
                      else if($state-date/tei:date/@from) then string($state-date/tei:date[@from][1]/@from)
                      else if($state-date/tei:date/@notBefore) then string($state-date/tei:date[@notBefore][1]/@notBefore)
                      else ()
        let $end :=   if($state-date/@when) then string($state-date/@when)
                      else if($state-date/@notAfter) then string($state-date/@notAfter)
                      else if($state-date/@to) then string($state-date/@to)
                      else if($state-date/tei:date[@when][2]) then string($state-date/tei:date[@when][2]/@when)
                      else if($state-date/tei:date/@to) then string($state-date/tei:date[@to][2]/@to)
                      else if($state-date/tei:date/@notAfter) then string($state-date/tei:date[@notAfter][2]/@notAfter)
                      else () 
        let $office := if($state-date/@role) then concat(' ',string($state-date/@role)) else concat(' ',string($state-date/@type))                 
        return timeline:format-dates($start, $end, concat(string-join($state-date/descendant-or-self::text(),' '),' ', $office), '')
    else () 
};

(:~
 : Build events date ranges
 : @param $data as node
 : build end and start?
 replace(string($event/descendant-or-self::*[@from][1]/@from),'-',',')
:)
declare function timeline:get-events($data as node()*) as node()*{
     if($data/descendant-or-self::tei:event) then 
        for $event in $data/descendant-or-self::tei:event
        let $event-content := normalize-space(string-join($event/descendant-or-self::*/text(),' '))
        let $start := if($event/descendant-or-self::*/@when) then $event/descendant-or-self::*[@when][1]/@when
                      else if($event/descendant-or-self::*/@notBefore) then $event/descendant-or-self::*[@notBefore][1]/@notBefore
                      else if($event/descendant-or-self::*/@from) then $event/descendant-or-self::*[@from][1]/@from
                      else ()
        let $end :=   if($event/descendant-or-self::*/@when) then $event/descendant-or-self::*[@when][1]/@when
                      else if($event/descendant-or-self::*/@notAfter) then $event/descendant-or-self::*[@notAfter][1]/@notAfter
                      else if($event/descendant-or-self::*/@to) then $event/descendant-or-self::*[@to][1]/@to
                      else ()         
        return timeline:format-dates($start, $end, concat(substring($event-content,1, 30),'...'), $event-content)       
    else ()   
};
