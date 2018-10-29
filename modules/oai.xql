xquery version "3.0";
(:
 : Module Name: xqOAI
 : Module Version: 1.4
 : Updated: Feb. 16, 2015
 : Date: September, 2007
 : Copyright: Michael J. Giarlo and Winona Salesky
 : Proprietary XQuery Extensions Used: eXist-db
 : XQuery Specification: November 2005
 : Module Overview: Adapted from xqOAI to provide OAI-PMH data provider for 
 : TEI records. Output includes TEI, MADS, and RDF records.
 :)

(:~
 : OAI-PMH data provider for TEI records within an eXist 
 :
 : @author Michael J. Giarlo
 : @author Winona Salesky
 : @since April, 2010
 : @version 1.4
 :)
import module namespace tei2="http://syriaca.org/tei2dc" at "lib/tei2dc.xqm";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
(: declare namespaces for each metadata schema we care about :)
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace dcterms = "http://purl.org/dc/terms/";
declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/";
declare namespace request="http://exist-db.org/xquery/request";

declare option exist:serialize "method=xml media-type=text/xml omit-xml-declaration=no indent=yes";

(: configurable variables :)
declare variable $base-url           := 'http://syriaca.org/api/oai';
declare variable $repository-name    := 'Syriaca.org';
declare variable $admin-email        := 'david.a.michelson@vanderbilt.edu';
declare variable $hits-per-page      := 25;
declare variable $earliest-datestamp := '2012-01-01';
declare variable $_docs              := collection($global:data-root)//tei:TEI;
declare variable $oai-domain         := 'syriaca.org';
declare variable $id-scheme          := 'oai';

(: params from OAI-PMH spec :)
declare variable $verb {request:get-parameter('verb', '')};
declare variable $identifier {request:get-parameter('identifier', '')};
declare variable $from {request:get-parameter('from', '')};
declare variable $until {request:get-parameter('until', '')};
declare variable $set {request:get-parameter('set', '')};
declare variable $start {request:get-parameter('resumptionToken', 1) cast as xs:integer};
declare variable $metadataPrefix {request:get-parameter('metadataPrefix', 'tei') cast as xs:string};
declare variable $resumptionToken {request:get-parameter('resumptionToken', '')};

(: set to true in argstring for extra debugging information :)
declare variable $verbose {request:get-parameter('verbose', '')};

(:~
 : Print datetime of OAI response. 
 : - Uses substring and concat to get the date in the format OAI wants
 :
 : @return XML
 :)
declare function local:oai-response-date() {
    <responseDate xmlns="http://www.openarchives.org/OAI/2.0/">{ 
        concat(substring(current-dateTime() cast as xs:string, 1, 19), 'Z') 
    }</responseDate>
};

(:~
 : Build the OAI request element 
 :
 : @return XML
  oai_dc
 http://www.openarchives.org/OAI/2.0/oai_dc/
 :)
declare function local:oai-request() {
   element {xs:QName("oai_dc:request")}
   {
       (
       if ($metadataPrefix != '')  then attribute metadataPrefix {$metadataPrefix}   else (),
       if ($verb != '')           then attribute verb {$verb}                       else (),
       if ($identifier != '')      then attribute identifier {$identifier}           else (),
       if ($from != '')            then attribute from {$from}                       else (),
       if ($until != '')           then attribute until {$until}                     else (),
       if ($set != '')             then attribute set {$set}                         else (),
       if ($resumptionToken != '') then attribute resumptionToken {$resumptionToken} else (),
       'http:syriaca.org/api/oai'
       )
   }
};

(:~
 : Get resumptionToken
 : - this is a stub
 : TO-DO: real resumptionTokens, using xquery update to store result sets in the db
 :
 : @return valid resumptionToken in appropriate format
 :)
declare function local:get-cursor-token() {
    if ($resumptionToken = '') then 
        1
    else 
        $resumptionToken cast as xs:integer
};

declare function local:validateParams(){
    let $parameters :=  request:get-parameter-names()
    for $param in $parameters
    return
        if($param = 'verb' or $param = 'identifier' or $param = 'from' or $param = 'until' or $param = 'set' or $param = 'metadataPrefix' or $param = 'resumptionToken' or $param = 'perpage' or $param = 'start') 
            then ''
        else <error code="badArgument">Invalid OAI-PMH parameter : {$param}</error>
};

declare function local:errorCheck(){
     if (exists($verb) and $verb = 'GetRecord') then
            (if(not(exists($identifier))) then <error code="badArgument">identifier is a required argument</error> else (),
            if (exists($identifier) and $identifier = '') then <error code="badArgument">identifier is a required argument</error> else (),
            if (exists($metadataPrefix)) then
                if($metadataPrefix != 'oai_dc' and $metadataPrefix != 'tei') then 
                    <error code="cannotDisseminateFormat">only oai_dc and tei is supported</error> 
                else ()
             else (),
             if (exists($metadataPrefix) and count($metadataPrefix) gt 1) then <error code="badArgument">Only one metadataPrefix argument acceptable</error> else ())
     else if (exists($verb) and $verb = 'ListIdentifiers' or $verb = 'ListRecords') then 
           (if(exists($resumptionToken) and $resumptionToken != '' and not(matches($resumptionToken, '^\d+$'))) then <error code="badResumptionToken">bad resumptionToken</error> else (),
            if (exists($metadataPrefix)) then
                if($metadataPrefix != 'oai_dc' and $metadataPrefix != 'tei') then 
                    <error code="cannotDisseminateFormat">only oai_dc and tei is supported</error> 
                else ()
             else (),
            if (exists($metadataPrefix) and count($metadataPrefix) gt 1) then <error code="badArgument">Only one metadataPrefix argument acceptable</error> else (),
            if(exists($from) and $from !='' or exists($until) and $until !='')  then
                if(local:validate-dates() = 'true') then 
                    if(exists($from) and $from lt $earliest-datestamp) then <error code="noRecordsMatch">Earliest date available is {$earliest-datestamp}</error> else ()
                else <error code="badArgument">From/until arguments are not valid</error>
            else ()   
            )  
     else ()
};

(:Begin Error checking, accept only valid paremters:)
declare function local:testParameters(){
let $error :=
    if(local:validateParams() != '') then  local:validateParams()
    else local:errorCheck()
return $error
};

(:~
 : Validate from and until params
 : - dates are valid only if they match date-pattern and are in same format
 : - note that date-pattern also matches an empty string
 :
 : @return boolean
 :)
declare function local:validate-dates() {
    let $date-pattern := '^(\d{4}-\d{2}-\d{2}){0,1}$'
    let $from-len     := string-length($from)
    let $until-len    := string-length($until)
    return
        if ($from-len > 0 and $until-len > 0 and $from-len != $until-len) then
            'false'
        else
            if(matches($from, $date-pattern) and matches($until, $date-pattern)) then 'true' else 'false'
 };

(:~
  : Modifies dates extracted from TEI records to be OAI compliant
:)
declare function local:modDate($date){    
    let $date := string($date)
    let $shortDate :=  
         if(string-length($date) = 10) then concat($date,'T12:00:00Z')
             else if(string-length($date) = 4) then concat($date,'01-01T12:00:00Z')
             else if(string-length($date) gt 10) then concat(substring($date,1,10),'T12:00:00Z')
             else ()
    return if(exists($shortDate) and $shortDate != '') then $shortDate else '2006-01-01' 
};

(:~
 : Filter by set title
:)
declare function local:set-paths(){
    if($set != '') then concat("[.//tei:title[. = '",$set,"']]")
    else ()
};

(:~
 : Build xpath for selecting records based on date range or sets
:)
declare function local:buildPath(){
let $results := util:eval(concat("$_docs",local:set-paths()))
return 
    if($from != '' and $until != '') then $results[local:modDate(descendant::tei:publicationStmt/descendant::tei:date[1]) gt $from and local:modDate(descendant::tei:publicationStmt/descendant::tei:date[1]) lt $until]
    else if($from != '' and not($until)) then $results[local:modDate(descendant::tei:publicationStmt/descendant::tei:date[1]) gt $from]
    else if($until !='' and not($from)) then  $results[local:modDate(descendant::tei:publicationStmt/descendant::tei:date[1]) lt $until]
    else $results
};

(:~
 : Branch processing based on client-supplied "verb" param
 :
 : @param $_hits a sequence of XML docs
 : @param $_end an integer reflecting the last item in the current page of results
 : @param $_count an integer reflecting total hits in the result set
 : @return XML if errors, nothing if not
 :)
declare function local:oai-response() { 
    if (exists(local:testParameters()) and local:testParameters() !='') then local:testParameters()
    else 
            if      ($verb = 'ListSets')            then local:oai-list-sets()
            else if ($verb = 'ListRecords')         then local:oai-list-records()
            else if ($verb = 'ListIdentifiers')     then local:oai-list-identifiers()
            else if ($verb = 'GetRecord')           then local:oai-get-record()
            else if ($verb = 'ListMetadataFormats') then local:oai-list-metadata-formats()
            else if ($verb = 'Identify')            then local:oai-identify()
            else <error code="badVerb">Invalid OAI-PMH verb : { $verb }</error>        
};

(:~
 : Print a metadata record
 : - the mods/ead brancher is inelegant -- more abstraction may be helpful here
 : TO-DO: find a way to make this easier to extend, e.g., for new metadata formats
 :
 : @param $_record an XML record
 : @return XML
 :)
declare function local:oai-metadata($record) {
      <metadata xmlns="http://www.openarchives.org/OAI/2.0/">
      {
        if($metadataPrefix = 'oai_dc') then
            local:get-dc($record)
        else local:get-TEI($record)
            
          (:local:buildDC($record),:)
          
          (:,
          local:buildRDF($record):)
      }
      </metadata>
};

(:~
 : Extract OAI identifier from MODS or EAD
 : - currently assumes only mods and ead are relevant
 : TO-DO: get rid of hard-coding
 :
 : @param $_record an XML record
 : @return a string representing an OAI identifier
 :)
declare function local:get-identifier($record) {
   let $id := string($record/descendant::tei:idno[@type='URI'][starts-with(.,'http://syriaca.org/')][1])
   let $oaiID := concat('oai:',$oai-domain,':',$id)
   return $oaiID
};

(:~
 : Print the resumptionToken
 : TO-DO: fix this up when resumptionToken support is built-in
 :
 : @param $_end integer, index of last item in current page of results
 : @param $_count integer, total number of hits in result set
 : @return XML or nothing
 :)
declare function local:print-token($_end, $_count) {
    if ($_end + 1 < $_count) then 
        let $token :=  $_end + 1  
        return
            <resumptionToken completeListSize="{ $_count }" cursor="{ $start - 1 }">{ $token }</resumptionToken>
    else ()
};

(:~
 : OAI GetRecord verb
 :
 : @param $_hits a sequence of XML docs
 : @return XML corresponding to a single OAI record
 :)
declare function local:oai-get-record() { 
    let $record := $_docs[descendant::tei:body/descendant::tei:idno[. = $identifier]]
    let $date := string($record/descendant::tei:publicationStmt/descendant::tei:date[1])
    let $oaiDate := concat(string($date),'Z')
    return 
        if($record !='') then
        <GetRecord xmlns="http://www.openarchives.org/OAI/2.0/">
            <record>{
                        (<header>
                        <identifier>{local:get-identifier($record)}</identifier>
                        <datestamp>{$oaiDate}</datestamp>
                        {
                            let $set := $record//tei:title[@level='m'][1] | $record//tei:title[@level='s'][1]
                            for $oaiSet in $set
                            let $idString := $set
                            return
                                <setSpec>{$idString}</setSpec>
                         }
                    </header>, local:oai-metadata($record) )
            }</record>
            { 
                if ($verbose = 'true') then 
                    <debug>{ $record }</debug> 
                else ()
            }
        </GetRecord> 
        else
        <error code="idDoesNotExist">No Records matched your criteria.</error>
};

(:~
 : OAI Identify verb
 :
 : @return XML describing the OAI provider
 :)
declare function local:oai-identify() {
      <Identify xmlns="http://www.openarchives.org/OAI/2.0/">
        <repositoryName>{ $repository-name }</repositoryName>
        <baseURL>{ $base-url }</baseURL>
        <protocolVersion>2.0</protocolVersion>
        <adminEmail>{ $admin-email }</adminEmail>
        <earliestDatestamp>{ $earliest-datestamp }</earliestDatestamp>
        <deletedRecord>no</deletedRecord>
        <granularity>YYYY-MM-DD</granularity>
        <compression>deflate</compression>
     </Identify>
};

(:~
 : OAI ListIdentifiers verb
 :
 : @param $_hits a sequence of XML docs
 : @param $_end integer, index of last item in page of results
 : @param $_count integer, total number of hits in result set
 : @return XML corresponding to a list of OAI identifier records
 :)
declare function local:oai-list-identifiers() {
let $_hits := local:buildPath()
let $_count := count($_hits)
let $max := 
    if(request:get-parameter('perpage','') != '') then 
        if(request:get-parameter('perpage','') cast as xs:integer lt 101) then 
            (request:get-parameter('perpage','') cast as xs:integer)
        else $hits-per-page    
    else $hits-per-page
let $_end := if ($start + $max - 1 < $_count) then 
                $start + $max - 1 
            else 
                $_count 
return           
    if($_count eq 0) then  <error code="noRecordsMatch" count="{$_count}">No Records matched your criteria.</error>
    else
    <ListIdentifiers xmlns="http://www.openarchives.org/OAI/2.0/">{
        for $i in $start to $_end
        let $record := $_hits[$i]
        let $date := string($record/descendant::tei:publicationStmt/descendant::tei:date[1])
        let $oaiDate := concat(string($date),'Z')
        return 
          (<header xmlns="http://www.openarchives.org/OAI/2.0/">
          <identifier>{local:get-identifier($record)}</identifier>
          <datestamp>{$oaiDate}</datestamp>
          {
             let $set := $record/descendant::tei:titleStmt/tei:title[@level='m']
             for $oaiSet in $set
             let $idString := string($oaiSet)
             return
                <setSpec>{$idString}</setSpec>
            }

         </header>
         )
         } 
         { local:print-token($_end, $_count)}
    </ListIdentifiers>
};

(:~
 : OAI ListMetadataFormats verb
 :
 : @return XML corresponding to a list of supported metadata formats
 :)
declare function local:oai-list-metadata-formats() {
    <ListMetadataFormats xmlns="http://www.openarchives.org/OAI/2.0/">
      <metadataFormat>
        <metadataPrefix>oai_dc</metadataPrefix>
        <schema>http://www.openarchives.org/OAI/2.0/oai_dc.xsd</schema>
        <metadataNamespace>http://www.openarchives.org/OAI/2.0/oai_dc/</metadataNamespace>
      </metadataFormat>
      <metadataFormat>
        <metadataPrefix>tei</metadataPrefix>
        <schema>http://syriaca.org/documentation/syriaca-tei-main.rnc</schema>
        <metadataNamespace>http://www.tei-c.org/ns/1.0</metadataNamespace>
      </metadataFormat>
    </ListMetadataFormats>
};

(:~
 : OAI ListRecords verb
 :
 : @param $_hits a sequence of XML docs
 : @param $_end integer, index of last item in page of results
 : @param $_count integer, total number of hits in result set
 : @return XML corresponding to a list of full OAI records
 :)
declare function local:oai-list-records() {
let $_hits := local:buildPath()
let $_count := count($_hits)
let $max :=     
        if(request:get-parameter('perpage','') != '') then 
            if(request:get-parameter('perpage','') cast as xs:integer lt 101) then 
                (request:get-parameter('perpage','') cast as xs:integer)
            else $hits-per-page    
        else $hits-per-page   
let $_end := if ($start + $max - 1 < $_count) then 
                $start + $max - 1 
            else 
                $_count 
return 
    if($_count eq 0) then  <error code="noRecordsMatch">No Records matched your criteria.</error>
    else
    <ListRecords xmlns="http://www.openarchives.org/OAI/2.0/">{    
      for $i in $start to $_end
      let $record := $_hits[$i]
      let $date := string($record/descendant::tei:publicationStmt/descendant::tei:date[1])
      let $oaiDate := concat(string($date),'Z')
      return
          (<record xmlns="http://www.openarchives.org/OAI/2.0/">{ 
            <header>
              <identifier>{local:get-identifier($record)}</identifier>
              <datestamp>{$oaiDate}</datestamp>
                {
                 let $set := $record//tei:titleStmt/tei:title[@level='m']
                 for $oaiSet in $set
                 let $idString := string($oaiSet)
                 return
                    <setSpec>{$idString}</setSpec>
                 }

            </header>,
            if($metadataPrefix = 'tei') then $record 
            else tei2:tei2dc($record)
          }</record>
          )  
      }
      {local:print-token($_end, $_count) }
    </ListRecords>
};

(:~
 : OAI ListSets verb
 :
 : @param $_hits a sequence of XML docs
 : @return XML corresponding to a list of OAI set records
 :)
declare function local:oai-list-sets() {
    <ListSets xmlns="http://www.openarchives.org/OAI/2.0/">
       {
        for $set in $global:get-config//*:collections/*:collection
        return
            <set>
                <setSpec>{string($set/@name)}</setSpec>
                <setName>{if(string($set/@series != '')) then string($set/@series) else string($set/@title)}</setName>
                <setDescription>
                    <dc:relation xml:lang="en">{concat('http://syriaca.org/',string($set/@app-root),'/index.html')}</dc:relation>
                </setDescription>
            </set>
        }
   </ListSets>
};

declare function local:get-TEI($record){
    $record/ancestor::tei:TEI
};

declare function local:get-dc($record){
    tei2:tei2dc($record/ancestor::tei:TEI)
};
(: OAI-PMH wrapper for request and response elements :)
<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
         { 
            (local:oai-response-date(),local:oai-request(), local:oai-response())
           }
</OAI-PMH>