xquery version "3.1";

(:~
 : Simple script to uninstall a package, and install a new
 : version of the package from a xar file uploaded to a
 : location in the db.
 :)
declare namespace repo = "http://exist-db.org/xquery/repo";
declare namespace util = "http://exist-db.org/xquery/util";

declare variable $existdb-public-repo-url := "http://exist-db.org/exist/apps/public-repo";

(:~
 : Name of the package to uninstall and install a new version of.
 :)
declare variable $pkg-name := "${package-name}";

(:~
 : Location where the new version of the xar file for the package
 : can be found in the database.
 :)
declare variable $pkg-db-tmp-path := "${db-tmp-collection}/${package-final-name}.xar";

declare variable $undeploy-error := xs:QName("undeploy-error");
declare variable $remove-error := xs:QName("remove-error");
declare variable $no-pkg-error := xs:QName("no-pkg-error");
declare variable $install-and-deploy-error := xs:QName("no-pkg-error");


declare function local:pkg-installed($pkg-name as xs:string) as xs:boolean {
  exists(repo:list()[. eq $pkg-name])
};

declare function local:undeploy-and-remove-pkg($pkg-name as xs:string) as empty-sequence() {
  let $undeploy-result := repo:undeploy($pkg-name)
  return
    if ($undeploy-result/@result ne "ok")
    then
      fn:error($undeploy-error, "Unable to undeploy existing package: " || $pkg-name)
    else
      let $remove-result := repo:remove($pkg-name)
      return
        if ($remove-result eq fn:false())
        then
          fn:error($remove-error, "Unable to remove existing package: " || $pkg-name)
        else
          ()
};


if (local:pkg-installed($pkg-name))
then
  local:undeploy-and-remove-pkg($pkg-name)
else ()

,

if (util:binary-doc-available($pkg-db-tmp-path) eq fn:false())
then
  fn:error($no-pkg-error, "Package: " || $pkg-name || ", cannot be found at: " || $pkg-db-tmp-path)
else
  let $install-and-deploy-result := repo:install-and-deploy-from-db($pkg-db-tmp-path)
  return
    if ($install-and-deploy-result/@result ne "ok")
    then
      fn:error($install-and-deploy-error, "Unable to install and deploy package: " || $pkg-name)
    else
      <success timestamp="{util:system-dateTime()}"/>
