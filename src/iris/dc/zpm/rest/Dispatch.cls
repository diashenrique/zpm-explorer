/// Dispatch Class
Class dc.zpm.rest.Dispatch Extends %CSP.REST
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>

<Route Url="/" Method="GET" Call="Test" Cors="true"/>
<Route Url="/package" Method="GET" Call="dc.zpm.Utils:GetPackages" Cors="true"/>
<Route Url="/package" Method="POST" Call="dc.zpm.Utils:InstallPackage" Cors="true"/>

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

}
