xquery version "3.1";
(:~ The post-install runs after contents are copied to db.
 :
 : @version 3.0.0
 :)
declare namespace repo="http://exist-db.org/xquery/repo";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

(
(: Set UID for inexing function,git-sync and rdf functions. :)   
   sm:chmod(xs:anyURI($target || '/modules/index.xql'), "rwsr-xr-x"),
   sm:chmod(xs:anyURI($target || '/modules/git-sync.xql'), "rwsr-xr-x"),
   sm:chmod(xs:anyURI($target || '/sparql/update-rdf.xql'), "rwsr-xr-x")
)