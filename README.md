2026-07-21: Archiving this repository as no longer needed. Syriaca.org has migrated from the Srophe application infrastructure to the [Gaddel](https://github.com/srophe/Gaddel/) infrastructure. The upstream Srophe application (this repository) is no longer being developed or maintained, though several project forks remain under active development. 

# Srophé Application
[![Build Status](https://github.com/srophe/srophe/actions/workflows/ci.yml/badge.svg)](https://github.com/srophe/srophe/actions/workflows/ci.yml)
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
The Srophé Application runs on eXist-db v6.0.0 and up.

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
In the root directory of each of your new repositories run `./mvnw clean package` (or `mvnw.cmd` if you are on Windows) to build the application. 
A new `srophe-3.1.0-SNAPSHOT.xar` file will be built and saved in `target/`. You can install these applications via the Elemental (or eXist-db) dashboard [http://localhost:8080/exist/apps/dashboard/index.html] using the Package Manager. 

Once deployed the application should show up as 'The Srophé web application' on your dashboard. 
Click on the icon to be taken to the app. 

Learn how to customize the application.

### Developing this Code Base
You can run the integration tests by executing `./mvnw clean package -Pintegration-test`.

#### Docker Image
The Srophe application can also be compiled into a Docker Image where its EXPath Package is already deployed to Elemental.

If you would like to build the Docker Image, you simply need to make sure you have Docker installed,
and then include the build argument `-Pdocker`, for example:

##### macOS / Linux / Unix Platforms
Run the following from a Terminal/Shell:

```shell
./mvnw -Pdocker clean package
```

##### Microsoft Windows Platforms
Run the following from a Command Prompt:
```cmd
mvnw.cmd -Pdocker clean package
```

#### Running Srophe with Docker
You should first create a Docker Volume to hold your Elemental database files. You need do this only once:
```shell
docker volume create srophe-database
```

Once you have built (or obtained) the Docker Image, you can run Srophe in Docker like so:

```shell
docker run -it -p 8080:8080 --mount type=volume,src=srophe-database,dst=/elemental/data srophe/srophe:latest
```

Srophe will then be available in your web-browser at `http://localhost:8080/exist/apps/srophe/index.html`
**NOTE**: The first time you use the Docker Image, you will need to deploy data for Srophe to use!