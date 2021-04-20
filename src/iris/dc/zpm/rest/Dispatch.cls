/// Dispatch Class
Class dc.zpm.rest.Dispatch Extends %CSP.REST
{

Parameter CONTENTTYPE = "application/json";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>

<Route Url="/" Method="GET" Call="Test" Cors="true"/>
<Route Url="/package" Method="GET" Call="dc.zpm.Utils:GetPackages" Cors="true"/>
<Route Url="/package" Method="POST" Call="dc.zpm.Utils:InstallPackage" Cors="true"/>
<Route Url="/package/delete/:appname" Method="POST" Call="dc.zpm.Utils:UninstallPackage" Cors="true"/>
<Route Url="/installed" Method="GET" Call="dc.zpm.Utils:GetInstalledPackages" Cors="true"/>
<Route Url="/export" Method="POST" Call="ExportDependencies" Cors="true"/>

</Routes>
}

ClassMethod Test() As %Status
{
	Set %response.ContentType = "application/json"
	Set retObj = { }
	Set retMessage = "Hello World!"
	Set retObj.Message = retMessage
	Write retObj.%ToJSON()
	Quit $$$OK
}

/// Description
ClassMethod ExportDependencies() As %Status
{
	Set sc = $$$OK
	Set obj = ##class(%DynamicAbstractObject).%FromJSON(%request.Content.Read())
	Set sc = ##class(dc.zpm.Utils).ExportDependecies(obj.dependencies)
	Return sc
}

}
