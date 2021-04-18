Include (%callout, %occSAX, %occXSLT, %syNLS)

/// Utility class for ZPM Explorer project
Class dc.zpm.Utils
{

ClassMethod GetPackages() As %Status
{
    Set tSC = $$$OK 

    Try {
        Set httprequest = ##class(%Net.HttpRequest).%New()
        Set httprequest.Server = "pm.community.intersystems.com"
        Set httprequest.Https = 1
        Set httprequest.SSLConfiguration = "default"
        Set tSC = httprequest.Get("/packages/-/all")

        Set stream = httprequest.HttpResponse.Data
        Set arrJSON = ##class(%DynamicArray).%FromJSON(stream)
        
        Set iter = arrJSON.%GetIterator()
        While iter.%GetNext(.key , .value ) {
            Write arrJSON.%Get(key).name_ ", "_arrJSON.%Get(key).description_ ", "_arrJSON.%Get(key).repository_ ", "_arrJSON.%Get(key).versions.%Get(0) ,!
        }
    }
    Catch {
        Write httprequest.HttpResponse.StatusCode_" - "_httprequest.HttpResponse.ReasonPhrase,!
        Set tSC = $$$OK
    }

    Quit tSC
}

/// Installation Package method
ClassMethod InstallPackage() As %Status
{
    Set sc = $$$OK
    Set appName = ""
    Set errorMsg = ""
    
    Set obj = ##class(%DynamicAbstractObject).%FromJSON(%request.Content.Read())

    Set blnIsInstalled = ..IsInstalled(obj.name)

    If (blnIsInstalled = $$$NO) {
        Set dev = "/tmp/log-zpm-"_obj.name_"-"_$REPLACE($HOROLOG,",","")_".txt"
        Open dev:("ARW"):5
        Use dev

        Try {
            // Install ZPM package
            $$$TOE(sc, $zpm("install "_obj.name))

            // Save the package information on InstalledPackages class
            Set installedPackage = ##class(dc.zpm.InstalledPackages).%New()
            Set installedPackage.AppName = obj.name
            Set installedPackage.AppVersion = obj.version
            Set installedPackage.DateInstalled = +$HOROLOG
            $$$TOE(sc, installedPackage.%Save())

            Set json = {}
            Do json.%Set("status","success")
            Do json.%Set("msg","The package has been installed successfully")
            Write json.%ToJSON()
        }
        Catch ex {
            Set sc = ex.AsStatus()
            Set errorMsg = ex.DisplayString()
        }

        Close dev

        If ($$$ISERR(sc)) {
            Set json = {}
            Do json.%Set("status","error")
            Do json.%Set("msg",errorMsg)
            Write json.%ToJSON()
        }
    } Else {
        Set json = {}
        Do json.%Set("status","warning")
        Do json.%Set("msg","The package it's already installed")
        Write json.%ToJSON()
    }
    
    Return $$$OK
}

/// Check if a package it's already installed
ClassMethod IsInstalled(pPackageName As %String) As %Status
{
    Set sc = $$$OK
    
    Set indexPackageName = " "_$ZCONVERT(pPackageName,"U")

    If ($DATA(^dc.zpm.InstalledPackagesI("IndexAppName",indexPackageName,1)) = 0) {
        Set sc = $$$NO
    }

    Return sc
}

ClassMethod XPathQuery(url As %String, context As %String, expr As %String)
{
	Set req=##class(%Net.HttpRequest).%New()
	Set req.Https = 1
	Set req.SSLConfiguration = "default"
	$$$TOE(st, req.Get(url))
	Set data = req.HttpResponse.Data.Read()
	$$$TOE(st, ##class(%XML.XPATH.Document).CreateFromString(data,.tDoc))
    $$$TOE(st, tDoc.EvaluateExpression(context,expr,.tRes))
    $$$TOE(st, ##class(%ZEN.Auxiliary.jsonProvider).%WriteJSONStreamFromObject(.stream, tRes))
    #; Do ##class(%XML.XPATH.Document).ExampleDisplayResults(tRes)
    Return stream.Read($$$MaxLocalLength)
}

/// Get all tags from a package and its version
ClassMethod GetTags(pPackageName As %String, pPackageVersion As %String) As %DynamicArray
{
    Set json = ..XPathQuery(
        $$$FormatText("https://pm.community.intersystems.com/packages/%1/%2/manifest", pPackageName, pPackageVersion),
        "/Export/Document/Module/Keywords",
        "text()"
    )
    Set tags = [].%FromJSON(json)
    Set list = $LISTFROMSTRING(tags.%Get(0).%Get("Value"))

    Kill tags
    Set tags = []
    Set idx = 0
    While ($LISTNEXT(list, idx, val)) {
        Do tags.%Push(val)
    }
    Return tags
}

ClassMethod GetTagsTest() As %Status
{
    Return ..GetTags("iris-rad-studio", "1.1.0")
}

ClassMethod XPathTest()
{
    Write "Keywors: ",!
    Set json = ..XPathQuery(
        "https://pm.community.intersystems.com/packages/iris-rad-studio/1.1.0/manifest",
        "/Export/Document/Module/Keywords",
        "text()"
    )
    Write json,!

    Write "All dependencies names:",!
    Set json = ..XPathQuery(
        "https://pm.community.intersystems.com/packages/iris-rad-studio/1.1.0/manifest",
        "/Export/Document/Module/Dependencies/ModuleReference",
        "text()"
    )
    Write json,!
}

}
