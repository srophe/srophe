d3xquery
===========
### This is a work in progress. 

A d3js library for interacting with TEI relationships and building dynamic d3js visualizations. Created for Syriaca.org [http://syriaca.org/]. Tested in eXist v3.5. 

Javascript library is a branch of https://github.com/ktym/d3sparql with modifications and additions. 

Syriaca.org data can be used as examples: [https://github.com/srophe/srophe-app-data]


### What it does
The library queries tei:relation elements and returns the results to the JavaScript for graphing. You can run a query to return all relationships (Bar Charts, Pie Charts and Bubble graphs work best with this kind of data), you can run a query on a specific relationship type, or get all relationships about a specific id/entity.  

When you load index.html a script runs in the background to create a drop down list of all your relationship options, based on the tei:relation/@ref attrubute. You can then select any relation, run 'query' to see the results visualized. These queries can be constrained to a particular entity by using the 'Record ID' text box to submit the id of a specific entity. (In this case the id is specified in the @active, @passive and @mutual attributes of the tei:relation element)


### Currently supports
* Charts
  * barchart, piechart, scatterplot*
* Graphs
  * force graph, sankey graph
* Trees
  * roundtree*, dendrogram*, treemap*, sunburst*, circlepack*, bubble
* Maps
  * coordmap*, namedmap*
* Tables
  * htmltable, htmlhash*
  
  *Javascript code exists for these but they have not yet been adapted to the XQuery results. 
  
### Data expectations
Relationships are expected to look like this: 

```<relation xmlns="http://www.tei-c.org/ns/1.0" ana="epistolary" ref="syriaca:Epistolary" active="http://syriaca.org/person/2531" passive="http://syriaca.org/person/51"/>
<relation xmlns="http://www.tei-c.org/ns/1.0" ana="epistolary" ref="syriaca:Epistolary" active="http://syriaca.org/person/51" passive="http://syriaca.org/person/2531"/>
<relation xmlns="http://www.tei-c.org/ns/1.0" ana="epistolary" ref="syriaca:EpistolaryReferenceTo" active="http://syriaca.org/person/51 http://syriaca.org/person/2531" passive="http://syriaca.org/person/3041"/>
```

Other formats may work but have not been tested. The queries will look for any tei:relation, and will tokenize the values of the @active, @passive, and @mutual attributes, if your ids have spaces, this will cause an issue.  If you use tei:relation/@name instead of tei:relation/@ref you can change the relationships.xql and the list-relationships.xql queries. 
  
### Usage
 
Add folders to an eXist application, change the 
```<input type="hidden" name="format" id="collection" value="/db/apps/srophe-data/data/spear"/>``` in index.html to point to your data collection.

Run queries, enjoy your visualizations.  
 
