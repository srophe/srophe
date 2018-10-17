# Srophé Application
A TEI publishing application.

The Srophé Application is an open source TEI publishing framework. Originally developed as a digital publication platform for 
Syriaca.org [http://syriaca.org/] the Srophé software has been generalize for use with any TEI publications. 

## The Srophé Application offers
* Multi-lingual Browse 
* Multi-lingual Search
* Faceted searching and browsing
* Maps (Google or Leafletjs) for records with coordinates. 
* Timelines (https://timeline.knightlab.com/)
* D3js visualizations for TEI relationships
* RDF and SPARQL integration and data conversion
* Multi-format publishing: HTML, TEI, geoJSON, KML, JSON-LD, RDF/XML, RDF/TTL, Plain text

## Requirements 
The Srophé Application runs on eXist-db v3.5.0 and up. 

In order to use the git-sync feature 
(syncing your online website with your github repository) you will need to install the eXist-db EXPath Cryptographic Module Implementation [http://exist-db.org/exist/apps/public-repo/packages/expath-crypto-exist-lib.html]. 


To use the RDF triplestore and SPARQL endpoint you will need to install the exist-db SPARQL and RDF indexing module [http://exist-db.org/exist/apps/public-repo/packages/exist-sparql.html?eXist-db-min-version=3.0.3]


## Getting started
Clone or fork the repository.

Create a data repository, clone or fork the https://github.com/srophe/srophe-app-data repository, or create your own. 

### Add your data
Add your TEI the data directory in srophe-app-data/data. 
The Srophé Application depends on a unique identifier, for Syriaca.org uses `tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='URL']` as a unique identifier. 
It is also possible to use the document uri, changes would have to made in repo-config.xml and in controller.xql to enable use of the document uri rather then the tei:idno. 

### Deploy data and application
In the root directory of each of your new repositories run 'ant' [link to ant instructions] to build the eXist-db application. 
A new .xar file will be built and saved in srophe/build/ and srophe-data/build. You can install these applications via the eXist-db dashboard [http://localhost:8080/exist/apps/dashboard/index.html] using the Package Manager. 

Once deployed the application should show up as 'The Srophe web application' on your dashboard. 
Click on the icon to be taken to the app. 

Learn how to customize the application. 
