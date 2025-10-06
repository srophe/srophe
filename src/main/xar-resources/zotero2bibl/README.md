# zotero2bibl
Accesses Zotero API to load Zotero library into eXistdb and keep the eXistdb version up to date with the Zotero library. 
Canonical data lives in Zotero. Data stored in eXist uses the zotero2tei.xqm to transform Zotero records into Syriaca.org compliant TEI records. 

Current application transforms Zotero TEI output, or JSON output. Using the JSON output allows access to the Zotero tags and notes. 

To change the TEI output edit zotero2tei.xqm. 

## How to use:
1. Add folder to eXist, either in an existing application or as a standalone library.
2. Edit zotero-config.xml:
    
    a. Add your Zotero group id
    
    b. Specify Zotero export format, TEI or JSON, JSON will allow access to notes and tags. Note and tag rendering maybe repository specific and may need serialization may need to be changed in zotero2tei.xqm to match your needs. 
    
    c. Add the path to the data directory where you want to store Zotero bibliographic records in eXist
    
    d. Add the URI pattern to base an incremental URI on. example: http://syriaca.org/bibl  
    
    e. Change TEI header information to be specific to your repository. 

3. Load the library into eXistdb, access the application (ex: http://localhost:8080/exist/apps/zotero2bibl/index.html) and run either "intiate" (to load a new library) or "update" to check for updates in your Zotero library. 
