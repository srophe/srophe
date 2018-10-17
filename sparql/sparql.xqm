xquery version "3.1";
(:
 : Srophe SPARQL queries
:)
module namespace sprql-queries="http://syriaca.org/sprql-queries";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

(: Subjects counts all the records that reference this idno  :)
declare function sprql-queries:related-subjects($ref){
    concat("prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>      
                                
        SELECT *
        WHERE {
          ?s dcterms:relation <",$ref,">.}
    ")
};

(: Subjects counts all the records that reference this idno  :)
declare function sprql-queries:related-subjects-count($ref){
    concat("prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>      
                                
        SELECT (COUNT(*) AS ?count)
        WHERE {
          ?s dcterms:relation <",$ref,">.}
    ")
};

declare function sprql-queries:related-citations($ref){
    concat("prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>      
                                
        SELECT *
        WHERE {
          <",$ref,"> lawd:hasCitation ?o.
          OPTIONAL{
          <",$ref,"> skos:closeMatch ?o.}
        }")
};

declare function sprql-queries:related-citations-count($ref){
    concat("prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>      
                                
        SELECT (COUNT(*) AS ?count)
        WHERE {
          <",$ref,"> lawd:hasCitation ?o.
          OPTIONAL{
          <",$ref,"> skos:closeMatch ?o.}
        }")
};

declare function sprql-queries:label($ref){
    concat("prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>      
                                
        SELECT *
        WHERE {
          <",$ref,"> rdfs:label ?o;
        }")
};

declare function sprql-queries:label-desc($ref){
    concat("prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>      
                                
        SELECT *
        WHERE {
          <",$ref,"> rdfs:label ?o;
            
        }")
};


(:SPEAR relationship and events Queries :)
(: relationships and counts :)
declare function sprql-queries:personFactoids(){
    "prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>  
        prefix syriaca: <http://syriaca.org/schema#>
                                
        SELECT *
        WHERE {
          ?factoid syriaca:personFactoid ?person;
            rdfs:label  ?factoidLabel.
        }"
};

(: Test query :)
declare function sprql-queries:test-q(){
    "prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>  
        prefix syriaca: <http://syriaca.org/schema#>
                                
        SELECT *
        WHERE {
          ?factoid <http://syriaca.org/schema#/personFactoid> ?person.
        }"
(:
let $q := "
    prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    prefix owl: <http://www.w3.org/2002/07/owl#>
    prefix skos: <http://www.w3.org/2004/02/skos/core#>
    prefix xsd: <http://www.w3.org/2001/XMLSchema#>
    prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    prefix lawd: <http://lawd.info/ontology/>
    prefix dcterms: <http://purl.org/dc/terms/>
    prefix foaf: <http://xmlns.com/foaf/0.1/>
    prefix dc: <http://purl.org/dc/terms/>      
                                                    
    SELECT *
    WHERE {
        ?relatedID <http://purl.org/dc/terms/relation> <http://syriaca.org/place/78>;
            skos:prefLabel  ?relatedLabel.
        FILTER ( langMatches(lang(?relatedLabel), 'en')) .
        }
    LIMIT 25"
    
    Realted to edessa, with edessa
                       
                    prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
                    prefix owl: <http://www.w3.org/2002/07/owl#>
                    prefix skos: <http://www.w3.org/2004/02/skos/core#>
                    prefix xsd: <http://www.w3.org/2001/XMLSchema#>
                    prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                    prefix lawd: <http://lawd.info/ontology/>
                    prefix dcterms: <http://purl.org/dc/terms/>
                    prefix foaf: <http://xmlns.com/foaf/0.1/>
                    prefix dc: <http://purl.org/dc/terms/>      
                                                                    
                    SELECT *
                    WHERE {
                        ?relatedID <http://purl.org/dc/terms/relation> ?objectID.
                        ?relatedID skos:prefLabel  ?relatedLabel.
                        ?objectID skos:prefLabel  ?objectLabel.
                        FILTER ( ?objectID = <http://syriaca.org/place/78>) .
                        FILTER ( langMatches(lang(?relatedLabel), 'en')) .
                        FILTER ( langMatches(lang(?objectLabel), 'en')) .
                        }
                    LIMIT 25 

                    prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
                    prefix owl: <http://www.w3.org/2002/07/owl#>
                    prefix skos: <http://www.w3.org/2004/02/skos/core#>
                    prefix xsd: <http://www.w3.org/2001/XMLSchema#>
                    prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                    prefix lawd: <http://lawd.info/ontology/>
                    prefix dcterms: <http://purl.org/dc/terms/>
                    prefix foaf: <http://xmlns.com/foaf/0.1/>
                    prefix dc: <http://purl.org/dc/terms/>      
                                                                    
                    SELECT *
                    WHERE {
                        ?relatedID <http://purl.org/dc/terms/relation> ?relatedObject.
                        ?relatedID skos:prefLabel  ?relatedLabel.
                        ?relatedObject skos:prefLabel  ?relatedObjectLabel.
                        FILTER ( ?relatedObject = <http://syriaca.org/place/78>) .
                        }
                    LIMIT 25

    :)
       
};