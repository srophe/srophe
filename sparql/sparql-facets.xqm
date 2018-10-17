xquery version "3.1";
(:
 : Create a faceting module for SPARQL queries on SPEAR.
 : Accept a SPARQL conf file 
 : Custom facet functions 
:)
module namespace sparql-facets="http://syriaca.org/sparql-facets";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

(: SPARQL prefixes :)
declare variable $sparql-facets:prefixes {"
 prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
 prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
 prefix cwrc: <http://sparql.cwrc.ca/ontologies/cwrc#>
 prefix dcterms: <http://purl.org/dc/terms/>
 prefix foaf: <http://xmlns.com/foaf/0.1/>
 prefix lawd: <http://lawd.info/ontology/>
 prefix owl: <http://www.w3.org/2002/07/owl#>
 prefix person: <https://www.w3.org/ns/person>
 prefix skos: <http://www.w3.org/2004/02/skos/core#> 
 prefix snap: <http://data.snapdrgn.net/ontology/snap#>
 prefix syriaca: <http://syriaca.org/schema#>
 prefix xs: <http://www.w3.org/2001/XMLSchema>
 "
};

(: Build SPARQL different facet lists for each tab, on SPEAR browse. Called by run-sparql.xql to build facet lists.  :)
declare function sparql-facets:build-sparql-facets($parameters as node()*){
    if(matches($parameters/parameter[name = 'facet-name']/value/text(),'events')) then
        concat($sparql-facets:prefixes, "
            SELECT distinct ?key ?facet_value ?facet_label ?facet_count 
            WHERE 
              { # facets 
              ",
                    sparql-facets:spear-sources-facet($parameters),"UNION",
                    sparql-facets:event-facet($parameters),"UNION",
                    sparql-facets:sex-facet($parameters),"UNION",
                    sparql-facets:ethnic-labels-facet($parameters),"UNION",
                    sparql-facets:occupation-facet($parameters),"UNION",
                    sparql-facets:citizenship-facet($parameters),"UNION",
                    sparql-facets:rank-facet($parameters),"UNION",
                    sparql-facets:mental-state-facet($parameters),"UNION",
                    sparql-facets:physical-trait-facet($parameters),
                    "
              }")
    else if(matches($parameters/parameter[name = 'facet-name']/value/text(),'persons')) then
        concat($sparql-facets:prefixes, "
            SELECT distinct ?key ?facet_value ?facet_label ?facet_count 
            WHERE 
              { # facets 
              ",
                    sparql-facets:spear-sources-facet($parameters),"UNION",
                    sparql-facets:event-facet($parameters),"UNION",
                    sparql-facets:relations-facet($parameters),"UNION",
                    sparql-facets:sex-facet($parameters),"UNION",
                    sparql-facets:ethnic-labels-facet($parameters),"UNION",
                    sparql-facets:occupation-facet($parameters),"UNION",
                    sparql-facets:citizenship-facet($parameters),"UNION",
                    sparql-facets:rank-facet($parameters),"UNION",
                    sparql-facets:mental-state-facet($parameters),"UNION",
                    sparql-facets:physical-trait-facet($parameters),
                    "
              }")
    else if(matches($parameters/parameter[name = 'facet-name']/value/text(),'relations')) then
        concat($sparql-facets:prefixes, "
            SELECT distinct ?key ?facet_value ?facet_label ?facet_count 
            WHERE 
              { # facets 
              ",
                    sparql-facets:spear-sources-facet($parameters),"UNION",
                    sparql-facets:event-facet($parameters),"UNION",
                    sparql-facets:relations-categories-facet($parameters),"UNION",
                    sparql-facets:relations-facet($parameters),"UNION",
                    sparql-facets:sex-facet($parameters),"UNION",
                    sparql-facets:ethnic-labels-facet($parameters),"UNION",
                    sparql-facets:occupation-facet($parameters),"UNION",
                    sparql-facets:citizenship-facet($parameters),"UNION",
                    sparql-facets:rank-facet($parameters),"UNION",
                    sparql-facets:mental-state-facet($parameters),"UNION",
                    sparql-facets:physical-trait-facet($parameters),
                    "
              }")              
    else               
        concat($sparql-facets:prefixes, "
            SELECT distinct ?key ?facet_value ?facet_label ?facet_count 
            WHERE 
              { # facets 
              ",sparql-facets:spear-sources-facet($parameters),"
              }")
};

(: Construnct main query, add selects, groups and limits to base query, called by run-sparql.xql to return full results set.  :)
declare function sparql-facets:build-sparql($parameters as node()*){
 if(matches($parameters/parameter[name = 'type']/value/text(),'force|Force|sankey|Sankey')) then
    if(matches($parameters/parameter[name = 'facet-name']/value/text(),'events')) then
        concat($sparql-facets:prefixes,"
                SELECT DISTINCT * WHERE { 
                ",sparql-facets:build-base-query($parameters)
                ,"
                ?s dcterms:subject ?eventValue.
                FILTER CONTAINS(str(?eventValue), 'keyword').
                ?eventValue rdfs:label ?eventLabel.
                FILTER ( langMatches(lang(?eventLabel), 'en')).
                }  
                LIMIT 50 ")
    else if(matches($parameters/parameter[name = 'facet-name']/value/text(),'persons')) then
        concat($sparql-facets:prefixes,"
                SELECT DISTINCT  (?person as ?uri) (?persName as ?title) ?s ?label WHERE { 
                ",sparql-facets:build-base-query($parameters)
                ,"
                }  
                LIMIT 50 ")
    else if(matches($parameters/parameter[name = 'facet-name']/value/text(),'relations')) then
        concat($sparql-facets:prefixes,"
                SELECT DISTINCT  (?person as ?uri) (?persName as ?title) ?s ?label WHERE { 
                ",sparql-facets:build-base-query($parameters)
                ,"
                ?s dcterms:subject ?person.
                FILTER CONTAINS(str(?person), 'person').
                ?person rdfs:label ?persName.
                FILTER ( langMatches(lang(?persName), 'en')). 
                }  
                LIMIT 50 ")
    else if(matches($parameters/parameter[name = 'facet-name']/value/text(),'uri')) then
        concat($sparql-facets:prefixes,"
                SELECT DISTINCT ?factoid ?factoidLabel ?s ?label WHERE { 
                ",sparql-facets:build-base-query($parameters)
                ,"
                }  
                LIMIT 50 ")                
    else concat($sparql-facets:prefixes,"
                SELECT DISTINCT * WHERE { 
                ",sparql-facets:build-base-query($parameters)
                ,"
                ?s dcterms:subject ?person.
                FILTER CONTAINS(str(?person), 'person').
                ?person rdfs:label ?persName.
                FILTER ( langMatches(lang(?persName), 'en')). 
                } 
                LIMIT 50 ")
else if(matches($parameters/parameter[name = 'facet-name']/value/text(),'persons')) then
    concat($sparql-facets:prefixes,"
             SELECT distinct  (?person as ?uri) (?persName as ?title) WHERE {",
             sparql-facets:build-base-query($parameters),"
            } GROUP BY ?person ?persName
            LIMIT 50 ")
else if(matches($parameters/parameter[name = 'type']/value/text(),'List|list|Table|table')) then 
    if(matches($parameters/parameter[name = 'facet-name']/value/text(),'uri')) then
        concat($sparql-facets:prefixes,"
            SELECT DISTINCT (?s as ?uri) (?label as ?title) WHERE { 
            ",sparql-facets:build-base-query($parameters)
            ,"
            } GROUP BY ?s ?label 
            ORDER by ?label
            LIMIT 50 ")
    else
    concat($sparql-facets:prefixes,"
            SELECT DISTINCT (?s as ?uri) (?label as ?title) WHERE { 
            ",sparql-facets:build-base-query($parameters)
            ,"
            } GROUP BY ?s ?label
            LIMIT 50 ")
else 
    concat($sparql-facets:prefixes,"
            SELECT DISTINCT (?s as ?uri) (?label as ?title) WHERE { 
            ",sparql-facets:build-base-query($parameters),"
            } GROUP BY ?s ?label
            LIMIT 50 ")
};

(:
    Build SPARQL query based on parameters passed from SPEAR form. 
    @param $id, $event, $relationship
    Used as a subquery by facets.    
:)
declare function sparql-facets:build-main-query($parameters){
(:
if(matches($parameters/parameter[name = 'facet-name']/value/text(),'persons')) then
    concat("
             {SELECT distinct  (?person as ?uri) (?persName as ?title) WHERE {",
             sparql-facets:build-base-query($parameters),"
            } GROUP BY ?person ?persName
            }")
else
:)
    concat("{SELECT DISTINCT * WHERE { 
        ",sparql-facets:build-base-query($parameters),"
        } }")
};

(: Build SPARQL query based on parameters passed from SPEAR form. Parameters: id, event, relationship :)
declare function sparql-facets:build-base-query($parameters as node()*){
if(matches($parameters/parameter[name = 'facet-name']/value/text(),'persons')) then
    concat("
            ?s rdf:type <http://syriaca.org/schema#/personFactoid>;
                rdfs:label ?label.
            ?s dcterms:subject ?person.
            FILTER CONTAINS(str(?person), 'person').
            ?person rdfs:label ?persName.
            FILTER ( langMatches(lang(?persName), 'en')).   
                ",sparql-facets:spear-sources($parameters),
                sparql-facets:dates($parameters),
                sparql-facets:place($parameters), 
                sparql-facets:eventsType($parameters),
                sparql-facets:relationshipType($parameters),
                sparql-facets:personType($parameters),
                sparql-facets:sex($parameters),
                sparql-facets:ethnic-labels($parameters),
                sparql-facets:occupation($parameters),
                sparql-facets:citizenship($parameters),
                sparql-facets:rank($parameters),
                sparql-facets:mental-state($parameters)
        )   
else if(matches($parameters/parameter[name = 'facet-name']/value/text(),'events')) then
    concat(sparql-facets:eventsType($parameters),"
            ?s rdf:type <http://syriaca.org/schema#/eventFactoid>;
                   rdfs:label ?label.       
                ",sparql-facets:dates($parameters),
                sparql-facets:place($parameters),
                sparql-facets:spear-sources($parameters),
                sparql-facets:person($parameters))    
else if(matches($parameters/parameter[name = 'facet-name']/value/text(),'relations')) then
    concat(sparql-facets:eventsType($parameters),"
            ?s rdf:type <http://syriaca.org/schema#/relationFactoid>;
                   rdfs:label ?label.    
                ",sparql-facets:relations-categories($parameters),
                sparql-facets:dates($parameters),
                sparql-facets:place($parameters),
                sparql-facets:spear-sources($parameters),
                sparql-facets:eventsType($parameters),
                sparql-facets:person($parameters)
                )                  
else if(matches($parameters/parameter[name = 'facet-name']/value/text(),'uri')) then
let $uri := tokenize($parameters/parameter[name = 'uri']/value/text(),' ')
return
    concat("{<",$uri,"> rdfs:label ?factoidLabel;
                    dcterms:subject ?s.                    
            FILTER(LANG(?factoidLabel) = '' || LANGMATCHES(LANG(?factoidLabel), 'en'))
            ?s rdfs:label ?label.
            FILTER(LANG(?label) = '' || LANGMATCHES(LANG(?label), 'en'))
            BIND(if(bound(?factoidURI), ?factoidURI, <",$uri,">) as ?factoid)            
            } UNION { 
                ?factoid  dcterms:subject <",$uri,">.  
                ?factoid rdfs:label ?factoidLabel.
                ?factoid  dcterms:subject ?s.
                ?s rdfs:label ?label.
                FILTER(LANG(?label) = '' || LANGMATCHES(LANG(?label), 'en'))
             }    
            ")                  
else 
    concat("?s dcterms:isPartOf <http://syriaca.org/spear>;
                      rdfs:label ?label.",   
                  sparql-facets:spear-sources($parameters),
                  sparql-facets:dates($parameters),
                  sparql-facets:personID($parameters), 
                  sparql-facets:eventsType($parameters),
                  sparql-facets:place($parameters))
};

declare function sparql-facets:eventsType($parameters){
let $event := tokenize($parameters/parameter[name = 'eventType']/value/text(),' ')
return 
    if($event != '') then 
        string-join(for $e at $p in $event
                    return concat("?s  dcterms:subject <",$e,">.")
                    ," ")
    else ()   
};

declare function sparql-facets:event-facet($parameters){
    concat("{ # Event Types facet
                SELECT distinct ('eventType' as ?key) (?eventValue as ?facet_value) (?eventLabel as ?facet_label) (count(distinct ?s) as ?facet_count)
                WHERE{
                    ?s rdf:type <http://syriaca.org/schema#/eventFactoid> ;
                        dcterms:subject ?eventValue.
                    FILTER CONTAINS(str(?eventValue), 'keyword').
                    ?eventValue rdfs:label ?eventLabel.
                    FILTER ( langMatches(lang(?eventLabel), 'en')).
                    ",sparql-facets:build-main-query($parameters),"
                    } GROUP BY ?eventLabel ?eventValue   
                    ORDER BY asc(str(?eventLabel))
            }")
};

declare function sparql-facets:dates($parameters){
    let $startDate := tokenize($parameters/parameter[name = 'startDate']/value/text(),' ')
    let $endDate := tokenize($parameters/parameter[name = 'endDate']/value/text(),' ')
    return 
        if($startDate != '') then (: -0009 :)
            let $start := if(starts-with($startDate,'-0')) then concat(replace(substring($startDate,1,7),'-00','-'),'-01-01T00:00:00.000') 
                          else concat(substring($startDate,1,4),'-01-01T00:00:00.000')
            let $end := if(starts-with($endDate,'-0')) then concat(replace(substring($startDate,1,7),'-00','-0'),'-01-01T00:00:00.000') 
                          else concat(substring($endDate,1,4),'-01-01T00:00:00.000')
            return 
            concat("
                ?s dcterms:temporal ?dateValue.   
                BIND('",$start,"'^^<http://www.w3.org/2001/XMLSchema#dateTime> as ?minDate).
                BIND('",$end,"'^^<http://www.w3.org/2001/XMLSchema#dateTime> as ?maxDate).   
                FILTER(?dateValue > ?minDate)
                FILTER(?dateValue < ?maxDate)
            ")
    else ()            
};

declare function sparql-facets:dates-facets($parameters){
    concat($sparql-facets:prefixes, "
                SELECT distinct ('eventDate' as ?key) (?dateValue as ?facet_value) (?dateValue as ?facet_label) (count(distinct ?s) as ?facet_count)
                WHERE{
                    ?s dcterms:temporal ?dateValue.
                    ",sparql-facets:build-main-query($parameters),"
                    } GROUP BY ?dateValue  
                    ORDER BY ?dateValue
            ")
};

declare function sparql-facets:person-facet($parameters){
    "
    ?s dcterms:subject ?person.
    FILTER CONTAINS(str(?person), 'person').
    "
};

declare function sparql-facets:person($parameters){
concat(sparql-facets:personID($parameters),
    if($parameters/parameter[name = ('personType', 'sex','ethnicLabel','occupation','citizenship','socialRank','mentalStatus','physicalTrait')]/value[. != '']) then
      concat("{SELECT DISTINCT * WHERE { 
        ?s dcterms:subject ?person.
        FILTER CONTAINS(str(?person), 'person').
        ?person rdfs:label ?persName.
        FILTER ( langMatches(lang(?persName), 'en')).
        ",
        sparql-facets:relationshipType($parameters),
        sparql-facets:personType($parameters),
        sparql-facets:sex($parameters),
        sparql-facets:ethnic-labels($parameters),
        sparql-facets:occupation($parameters),
        sparql-facets:citizenship($parameters),
        sparql-facets:rank($parameters),
        sparql-facets:mental-state($parameters),
        "}}")
    else())            
};

declare function sparql-facets:personID($parameters){
let $person-parm := tokenize($parameters/parameter[name = 'personID']/value/text(),' ')
return 
    if($person-parm != '') then 
        string-join(for $e at $p in $person-parm
                    return concat("?s  dcterms:subject <",$person-parm,">.")
                    ," ")
    else ()    
};

declare function sparql-facets:place($parameters){
    let $place-parm := tokenize($parameters/parameter[name = 'placeID']/value/text(),' ') 
    return 
        if($place-parm != '') then 
            string-join(for $e at $p in $place-parm
                        return concat("?s  dcterms:subject <",$place-parm,">.
                        FILTER CONTAINS(str(?place), 'place').
                        ?place rdfs:label ?placeName.
                        FILTER ( langMatches(lang(?placeName), 'en')).
                        ")
                        ," ")
        else ()   
};

declare function sparql-facets:spear-sources($parameters){
    let $source-parm := tokenize($parameters/parameter[name = 'sourceText']/value/text(),' ') 
    return 
       if($source-parm != '') then 
            concat("
            {
              ?s dcterms:source ?source .
              ?source dcterms:isPartOf <", $source-parm, ">.
             }
             UNION
             {
                 ?s dcterms:source <", $source-parm, ">.
              }
              ")
        else ()              
};

declare function sparql-facets:spear-sources-facet($parameters){
    concat("{ # Sources facet
                SELECT distinct ('sourceText' as ?key) (?sourceValue as ?facet_value) (?sourceLabel as ?facet_label) (count(distinct ?s) as ?facet_count)
                WHERE{
                    ?s dcterms:source ?source.
                    FILTER CONTAINS(str(?source), '/work/'). 
                    ?source rdfs:label ?sourceLabel1.
                    FILTER ( langMatches(lang(?sourceLabel1), 'en')).
                    OPTIONAL{ 
                        ?source dcterms:isPartOf ?parentValue.
                        FILTER CONTAINS(str(?parentValue), '/work/').
                        ?parentValue rdfs:label ?parentLabel.
                        FILTER ( langMatches(lang(?parentLabel), 'en')).
                    }
                    
                    BIND(if(bound(?parentValue), ?parentValue, ?source) as ?sourceValue)
                    BIND(if(bound(?parentLabel), ?parentLabel, ?sourceLabel1) as ?sourceLabel)
                    ",sparql-facets:build-main-query($parameters),"
                  } GROUP BY ?sourceValue ?sourceLabel
                 ORDER BY asc(str(?sourceLabel))  
                }")
};

declare function sparql-facets:relationshipType($parameters){
    let $relation-parm := tokenize($parameters/parameter[name = 'relationshipType']/value/text(),' ') 
    return 
       if($relation-parm != '') then 
            concat("?s rdf:type <", $relation-parm, ">.
                    ?relationship  owl:sameAs <", $relation-parm, ">.
                    ?relationship rdfs:label ?relationshipLabel.")
        else ()              
};

declare function sparql-facets:relations-categories($parameters){
    let $relation-parm := tokenize($parameters/parameter[name = 'relationshipCategory']/value/text(),' ') 
    return 
       if($relation-parm != '') then 
            concat("?s rdf:type ?relationshipValue.
                    ?relationship  owl:sameAs ?relationshipValue .
                    ?relationship skos:broadMatch  <", $relation-parm, ">.
                   <", $relation-parm, "> rdfs:label ?relationshipCategoryLabel.")
        else ()              
};

declare function sparql-facets:relations-categories-facet($parameters) {
    concat("{ # relationshipCategory facet
                SELECT distinct ('relationshipCategory' as ?key) (?relationshipCategory as ?facet_value) (?relationshipCategoryLabel as ?facet_label) (count(distinct ?s) as ?facet_count)
                WHERE{
                    ?s rdf:type <http://syriaca.org/schema#/relationFactoid>;
                          rdf:type ?relationshipValue.
                    ?relationship  owl:sameAs ?relationshipValue .
                    ?relationship skos:broadMatch ?relationshipCategory.
                    ?relationshipCategory rdfs:label ?relationshipCategoryLabel.
                    ",sparql-facets:build-main-query($parameters),"
                    } GROUP BY ?relationshipCategory ?relationshipCategoryLabel
                    ORDER BY asc(str(?relationshipCategoryLabel))
            }")
};

declare function sparql-facets:relations-facet($parameters){
    concat("{ # relationshipType facet
                SELECT distinct ('relationshipType' as ?key) (?relationshipValue as ?facet_value) (?relationshipLabel as ?facet_label) (count(distinct ?s) as ?facet_count)
                WHERE{
                    ?s rdf:type <http://syriaca.org/schema#/relationFactoid>;
                          rdf:type ?relationshipValue.
                    ?relationship  owl:sameAs ?relationshipValue .
                    ?relationship rdfs:label ?relationshipLabel.
                    ",sparql-facets:build-main-query($parameters),"
                    } GROUP BY ?relationshipValue ?relationshipLabel
                    ORDER BY asc(str(?relationshipLabel))
            }")
};

declare function sparql-facets:personType($parameters){
    let $person-parm := tokenize($parameters/parameter[name = 'personType']/value/text(),' ') 
    return 
        if($person-parm = 'group') then 
            "?person a foaf:group."
        else ()
};

declare function sparql-facets:sex($parameters){
    let $sex-parm := tokenize($parameters/parameter[name = 'sex']/value/text(),' ') 
    return 
        if($sex-parm != '') then concat("?person syriaca:gender <",$sex-parm,">.")
        else () 
};

declare function sparql-facets:sex-facet($parameters){
    concat("{ # sex facet
                SELECT distinct ('sex' as ?key) (?sexValue as ?facet_value) (?sexLabel as ?facet_label) (count(distinct ?s) as ?facet_count)
                WHERE{",sparql-facets:person-facet($parameters),"
                    ?person syriaca:gender ?sexValue.
                    ?sexValue rdfs:label ?sexLabel.
                    FILTER ( langMatches(lang(?sexLabel), 'en')).
                    ",sparql-facets:build-main-query($parameters),"
                    } GROUP BY ?sexLabel ?sexValue
                    ORDER BY asc(str(?sexLabel))
            }")
};

declare function sparql-facets:ethnic-labels($parameters){
    let $ethinic-parm := tokenize($parameters/parameter[name = 'ethnicLabel']/value/text(),' ') 
    return
        if($ethinic-parm != '') then 
            string-join(for $e at $p in $ethinic-parm
                       return concat("?person cwrc:hasEthnicity <",$e,">.")
                    ," ")        
        else ()                   
};

declare function sparql-facets:ethnic-labels-facet($parameters){
   concat("{ # Ethnic-label facet
                SELECT distinct ('ethnicLabel' as ?key) (?ethnicValue as ?facet_value) (?ethnicLabel as ?facet_label) (count(distinct ?s) as ?facet_count)
                WHERE{",sparql-facets:person-facet($parameters),"
                    ?s dcterms:subject ?person.
                    FILTER CONTAINS(str(?person), 'person').
                    ?person cwrc:hasEthnicity ?ethnicValue.
                    ?ethnicValue rdfs:label ?ethnicLabel.
                    FILTER ( langMatches(lang(?ethnicLabel), 'en')).
                    ",sparql-facets:build-main-query($parameters),"
                    } GROUP BY ?ethnicValue ?ethnicLabel
                    ORDER BY asc(str(?ethnicValue))
            }")
};

declare function sparql-facets:occupation($parameters){
    let $occupation-parm := tokenize($parameters/parameter[name = 'occupation']/value/text(),' ') 
    return 
        if($occupation-parm != '') then            
           string-join(for $e at $p in $occupation-parm
                       return concat("?person snap:occupation <",$e,">.")
                    ," ")                 
        else ()                   
};

declare function sparql-facets:occupation-facet($parameters){
    concat("{ # occupation facet
                SELECT distinct ('occupation' as ?key) (?occupationValue as ?facet_value) (?occupationLabel as ?facet_label) (count(distinct ?s) as ?facet_count)
                WHERE{",sparql-facets:person-facet($parameters),"
                    ?s dcterms:subject ?person.
                    FILTER CONTAINS(str(?person), 'person').                
                    ?person snap:occupation ?occupationValue. 
                    ?occupationValue rdfs:label ?occupationLabel.
                    FILTER ( langMatches(lang(?occupationLabel), 'en')).
                    ",sparql-facets:build-main-query($parameters),"
                } GROUP BY ?occupationLabel ?occupationValue
                ORDER BY asc(str(?occupationLabel))
            }")
};

declare function sparql-facets:citizenship($parameters){
    let $citizenship-parm := tokenize($parameters/parameter[name = 'citizenship']/value/text(),' ') 
    return 
        if($citizenship-parm != '') then   
            string-join(for $e at $p in $citizenship-parm
                       return concat("?person person:citizenship <",$e,">.")
                    ," ")
        else ()                   
};

declare function sparql-facets:citizenship-facet($parameters){
    concat("{ # Citizenship facet
                SELECT distinct ('citizenship' as ?key) (?citizenshipValue as ?facet_value) (?citizenshipLabel as ?facet_label) (count(distinct ?s) as ?facet_count)
                WHERE{
                    ?s dcterms:subject ?person.
                    FILTER CONTAINS(str(?person), 'person').                
                    ?person person:citizenship ?citizenshipValue.
                    ?citizenshipValue rdfs:label ?citizenshipLabel.
                    FILTER ( langMatches(lang(?citizenshipLabel), 'en')).
                    ",sparql-facets:build-main-query($parameters),"
                    } GROUP BY ?citizenshipLabel ?citizenshipValue
                    ORDER BY asc(str(?citizenshipLabel))
            }")         
};

declare function sparql-facets:rank($parameters){
    let $rank-parm := tokenize($parameters/parameter[name = 'socialRank']/value/text(),' ') 
    return
        if($rank-parm != '') then
            string-join(for $e at $p in $rank-parm
                       return concat("?person syriaca:hasSocialRank <",$e,">.")
                    ," ") 
        else ()                   
};

declare function sparql-facets:rank-facet($parameters){
    concat("{ # Social rank facet
                SELECT distinct ('socialRank' as ?key) (?rankValue as ?facet_value) (?rankLabel as ?facet_label) (count(distinct ?s) as ?facet_count)
                WHERE{",sparql-facets:person-facet($parameters),"
                    ?s dcterms:subject ?person.
                    FILTER CONTAINS(str(?person), 'person').                
                    ?person syriaca:hasSocialRank ?rankValue.
                    ?rankValue rdfs:label ?rankLabel.
                    FILTER ( langMatches(lang(?rankLabel), 'en')).
                    ",sparql-facets:build-main-query($parameters),"
                    } GROUP BY ?rankLabel ?rankValue
                    ORDER BY asc(str(?rankLabel))
                }")     
};

declare function sparql-facets:mental-state($parameters){
    let $mental-state-parm := tokenize($parameters/parameter[name = 'mentalStatus']/value/text(),' ') 
    return 
        if($mental-state-parm != '') then
            string-join(for $e at $p in $mental-state-parm
                       return concat("?person syriaca:hasMentalState <",$e,">.")
                    ," ")        
        else ()                   
};

declare function sparql-facets:mental-state-facet($parameters){
    concat("{ # Mental Status facet
                SELECT distinct ('mentalStatus' as ?key) (?mentalState as ?facet_value) (?mentalStateLabel as ?facet_label) (count(distinct ?s) as ?facet_count)
                WHERE{",sparql-facets:person-facet($parameters),"
                    ?s dcterms:subject ?person.
                    FILTER CONTAINS(str(?person), 'person').                
                    ?person syriaca:hasMentalState ?mentalState.
                    ?mentalState rdfs:label ?mentalStateLabel.
                    FILTER ( langMatches(lang(?mentalStateLabel), 'en')).
                    ",sparql-facets:build-main-query($parameters),"
                    } GROUP BY ?mentalStateLabel ?mentalState
                    ORDER BY asc(str(?mentalStateLabel))
            }")
};

declare function sparql-facets:physical-trait($parameters){
    let $physical-trait-parm := tokenize($parameters/parameter[name = 'physicalTrait']/value/text(),' ') 
    return 
        if($physical-trait-parm != '') then
            string-join(for $e at $p in $physical-trait-parm
                       return concat("?person syriaca:hasPhysicalTrait <",$e,">.")
                    ," ")        
        else ()                   
};

declare function sparql-facets:physical-trait-facet($parameters){
    concat("{ # Physical trait facet
                SELECT distinct ('physicalTrait' as ?key) (?physicalTrait as ?facet_value) (?physicalTraitLabel as ?facet_label) (count(distinct ?s) as ?facet_count)
                WHERE{",sparql-facets:person-facet($parameters),"
                    ?s dcterms:subject ?person.
                    FILTER CONTAINS(str(?person), 'person').                
                    ?person syriaca:hasPhysicalTrait  ?physicalTrait.
                    ?physicalTrait rdfs:label ?physicalTraitLabel.
                    FILTER ( langMatches(lang(?physicalTraitLabel), 'en')).
                        ",sparql-facets:build-main-query($parameters),"
                    } GROUP BY ?physicalTraitLabel ?physicalTrait
                    ORDER BY asc(str(?physicalTraitLabel))
            }")
};

