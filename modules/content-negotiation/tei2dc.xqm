xquery version "3.0";
(:~
 : Builds tei conversions. 
 : Used by oai, can be plugged into other outputs as well.
 :)
 
module namespace tei2="http://syriaca.org/srophe/tei2dc";
declare namespace dc="http://purl.org/dc/elements/1.1/";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace util="http://exist-db.org/xquery/util";

declare function tei2:tei2dc($nodes as node()*) {
<oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" 
xmlns:dc="http://purl.org/dc/elements/1.1/" 
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
    {
       (
       for $idno in $nodes/descendant::tei:idno[@type='URI'][starts-with(.,'http://syriaca.org/')]
       return
           <dc:identifier>{$idno/string()}</dc:identifier>,
       for $title in $nodes/descendant::tei:titleStmt/tei:title
       return
           <dc:title>{$title/string()}</dc:title>,
       for $creator in $nodes/descendant::tei:author
       return
           <dc:creator>{$creator/string()}</dc:creator>,
       for $editor in $nodes/descendant::tei:editor
       return
           <dc:contributor>{$editor/string()}</dc:contributor>,           
       for $publisher in $nodes/descendant::tei:publisher
       return
           <dc:publisher>{$publisher/string()}</dc:publisher>, 
       for $date in $nodes/descendant::tei:publicationStmt/descendant::tei:date[1]
       return
           <dc:date>{$date/string()}</dc:date>,
       for $idno in $nodes/descendant::tei:availability
       return
           <dc:rights>{$idno/string()}</dc:rights>, 
       for $desc in $nodes/descendant::tei:desc
       return
           <dc:description>{$desc/string()}</dc:description>)        
    }
</oai_dc:dc>

};
