# Srophé Application
[![Build Status](https://github.com/majlis-erc/srophe/actions/workflows/ci.yml/badge.svg)](https://github.com/majlis-erc/srophe/actions/workflows/ci.yml)
[![Java 11+](https://img.shields.io/badge/java-11+-blue.svg)](https://bell-sw.com/pages/downloads/)

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

## Building the Majlis EXPath Package

The Majlis application can be compiled into an EXPath Package for deployment to an Elemental (or eXist-db) server.

Build Requirements:
* [Java JDK](https://bell-sw.com/pages/downloads/) version 8 (or newer)

To build the Majlis application:

### macOS / Linux / Unix Platforms
Run the following from a Terminal/Shell:

```shell
./mvnw clean package
```

### Microsoft Windows Platforms
Run the following from a Command Prompt:
```cmd
mvnw.cmd clean package
```

You can then find the EXPath Package file in the `target/` folder, it will be named like `majlis-X.Y.Z-SNAPSHOT.xar`. You can take this file and upload it into Elemental (or eXist-db) via its `autodeploy` folder or its Package Manager application.

## Docker Image
The Majlis application can also be compiled into a Docker Image where its EXPath Package is already deployed to Elemental.

If you would like to build the Docker Image, you simply need to make sure you have Docker installed,
and then include the build argument `-Pdocker`, for example:

### macOS / Linux / Unix Platforms
Run the following from a Terminal/Shell:

```shell
./mvnw -Pdocker clean package
```

### Microsoft Windows Platforms
Run the following from a Command Prompt:
```cmd
mvnw.cmd -Pdocker clean package
```

### Running manuForma with Docker
You should first create a Docker Volume to hold your Elemental database files. You need do this only once:
```shell
docker volume create majlis-database
```

Once you have built (or obtained) the Docker Image, you can run Majlis in Docker like so:

```shell
docker run -it -p 8080:8080 --mount type=volume,src=majlis-database,dst=/elemental/data majlis-erc/majlis:latest
```

Majlis will then be available in your web-browser at `http://localhost:8080/exist/apps/majlis/index.html`
NOTE: The first time you use the Docker Image, you will need to deploy the [Majlis Data Package](https://github.com/majlis-erc/majlis-data/blob/main/build/majlis-data-0.01.xar).