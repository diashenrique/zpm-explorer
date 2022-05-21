Include (%callout, %occSAX, %occXSLT, %syNLS)

/// Utility class for ZPM Explorer project
Class dc.zpm.Utils
{

ClassMethod GetPackages() As %Status
{
    Set tSC = $$$OK 
    kill ^zpmXplorerVersion
    kill ^["%SYS"]zpmXplorerInstalledPkg

    do ..GetPackageAllNamespaces()

    set arrApps = []

    Quit tSC

    Try {
        Set httprequest = ##class(%Net.HttpRequest).%New()
        Set httprequest.Server = "pm.community.intersystems.com"
        Set httprequest.Https = 1
        Set httprequest.SSLConfiguration = "pm.community.intersystems.com"
        Set tSC = httprequest.Get("/packages/-/all")

        Set stream = httprequest.HttpResponse.Data
        Set arrJSON = ##class(%DynamicArray).%FromJSON(stream)
        
        Set iter = arrJSON.%GetIterator()
        While iter.%GetNext(.key , .value ) {
            set ^zpmXplorerVersion(arrJSON.%Get(key).name) = arrJSON.%Get(key).versions.%Get(0)
            set json = {}
            do json.%Set("name",arrJSON.%Get(key).name)
            do json.%Set("description",arrJSON.%Get(key).description)
            do json.%Set("repository",arrJSON.%Get(key).repository)
            do json.%Set("versions",arrJSON.%Get(key).versions.%Get(0))
            do arrApps.%Push(json)
        }      
    }
    Catch {
        Write httprequest.HttpResponse.StatusCode_" - "_httprequest.HttpResponse.ReasonPhrase,!
        Set tSC = $$$OK
    }

    do arrApps.%ToJSON()

    Quit tSC
}

/// Installation Package method
ClassMethod InstallPackage() As %Status
{
    Set sc = $$$OK
    Set appName = ""
    Set errorMsg = ""
    set blnUpdate = $$$NO 
    
    Set obj = ##class(%DynamicAbstractObject).%FromJSON(%request.Content.Read())

    Set blnIsInstalled = ..IsInstalled(obj.name, obj.namespace)
    Set blnUpdate = obj.update

    If ((blnIsInstalled = $$$NO) || (blnUpdate = $$$YES)) {
        New $Namespace
        Set $Namespace = obj.namespace
        
        Set dev = $$$FormatText("/tmp/log-zpm-%1-%2.txt", obj.name, $REPLACE($HOROLOG,",",""))
        Open dev:("ARW"):5
        Use dev

        Try {
            // Install ZPM package
            $$$TOE(sc, $zpm("install "_obj.name))
        }
        Catch ex {
            Set sc = ex.AsStatus()
            Set errorMsg = ex.DisplayString()
        }

        Close dev

        Set json = {}
        If ('$$$ISERR(sc)) {
            Do json.%Set("status","success")
            Do json.%Set("msg","The package has been installed successfully")
        } Else {
            Do json.%Set("status","error")
            Do json.%Set("msg",errorMsg)
        }
        Write json.%ToJSON()
    } Else {
        Set json = {}
        Do json.%Set("status","warning")
        Do json.%Set("msg","The package it's already installed")
        Write json.%ToJSON()
    }
    
    Return $$$OK
}

/// Check if a package it's already installed
ClassMethod IsInstalled(pPackageName As %String, pNamespace As %String) As %Status
{
    New $Namespace
    Set $Namespace = pNamespace
    Return ##class(%ZPM.PackageManager.Developer.Module).NameExists(pPackageName)
}

/// Uninstall a ZPM package
ClassMethod UninstallPackage(pPackageName As %String) As %Status
{
    Set sc = $$$OK
    Set errorMsg = ""

    Set dev = $$$FormatText("/tmp/log-zpm-%1-%2.txt", pPackageName, $REPLACE($HOROLOG,",",""))
    Open dev:("ARW"):5
    Use dev

    Try {

        Set listDelete = $LISTFROMSTRING(pPackageName)
        Set ptr = 0
        While ($LISTNEXT(listDelete, ptr, tDeleteApp)) {
            set strNamespace = $piece(tDeleteApp,"||",1)
            set strDeleteApp = $piece(tDeleteApp,"||",2)
            
            new $Namespace
            set $Namespace = strNamespace
            
            $$$TOE(sc, $zpm("uninstall "_strDeleteApp))
        }
    }
    Catch ex {
        Set sc = ex.AsStatus()
        Set errorMsg = ex.DisplayString()
    }

    Close dev

    Set json = {}
    If ('$$$ISERR(sc)) {
        Do json.%Set("status","success")
        Do json.%Set("msg","The package has been uninstalled successfully")
    } Else {
        Do json.%Set("status","error")
        Do json.%Set("msg",errorMsg)
    }
    Write json.%ToJSON()

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

/// Get installed packages 
ClassMethod GetInstalledPackages(pNamespace As %String) As %Status
{
    New $Namespace
    Set $Namespace = pNamespace
    
    Set sc = $$$OK

    Set tSC = $System.Status.OK()

    kill ^["%SYS"]zpmXplorerInstalled($Namespace) 

    Try {

		Set oRS = ##class(%SQL.Statement).%New()

        Set sql = "Select Name, LastModifiedTimestamp, VersionString from %ZPM_PackageManager_Developer.""Module"" Order By Name"

        Set tSC = oRS.%Prepare(sql)

        Quit:$System.Status.IsError(tSC)

        Set result = oRS.%Execute()

        If (result.%SQLCODE '< 0) {
	        While result.%Next() {
                set ^["%SYS"]zpmXplorerInstalled($Namespace,result.Name) = $listbuild(result.LastModifiedTimestamp,result.VersionString,..GetCurrentVersion(result.name))
                set ^["%SYS"]zpmXplorerInstalledPkg(result.Name) = ""
            }
        }
        Else {
            Throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE,result.%Message)
        }
    }
    Catch (oException) {
        Set tSC = oException.AsStatus()
    }

    quit tSC
}

ClassMethod GetCurrentVersion(pPackageName As %String) As %String
{
    Set tSC = $$$OK 

    if ($data(^zpmXplorerVersion) = 0) {
        do ..GetPackages()
    }
    set tSC = $get(^zpmXplorerVersion(pPackageName))

    Quit tSC
}

/// Generate a module.xml with current dependencies
/// pDependencies must be a comma separated values of the form <package>:<version> or <package>:* for the last package version
ClassMethod ExportDependecies(pDependencies As %String) As %Status
{
    Set sc = $$$OK
    Set tPath = "/tmp/"
    Set tName = "your-awesome-project-name"
    Set tVersion = "1.0.0"
    Set tDescription = "Detail the amazing things you've done"
    Set tKeywords = "tag1, tag2"
	Set tTemplate = ##class(%ZPM.PackageManager.Developer.ModuleTemplate).NewTemplate(tPath, tName, tVersion, tDescription, tKeywords)
    Set listDep = $LISTFROMSTRING(pDependencies)
    Set ptr = 0
    While ($LISTNEXT(listDep, ptr, tDependant)) {
        Do tTemplate.AddDependant(tDependant)
    }
	Do tTemplate.ProcessResources()
	$$$TOE(sc, tTemplate.SaveFile(tPath))

    Set file = ##class(%File).%New(tPath_"module.xml")
    $$$TOE(sc, file.Open("R"))
    Set module = ""
    while('file.AtEnd){
        Set module = module_$CHAR(13,10)_file.Read()
    }

    Set json = {
        "module": ($System.Encryption.Base64Encode(module))
    }
    Write json.%ToJSON()

    Return sc
}

/// Read Manifest
/// pPathType: K - Keywords, D - Dependencies
ClassMethod ReadManifest(pPackageName As %String, pPackageVersion As %String, pPathType As %String) As %String
{
    set sc = $$$OK
    set tReturn = ""
    set strPath = ""
    set url = $$$FormatText("https://pm.community.intersystems.com/packages/%1/%2/manifest", pPackageName, pPackageVersion)
    set req=##class(%Net.HttpRequest).%New()
	set req.Https = 1
	set req.SSLConfiguration = "default"
	$$$TOE(st, req.Get(url))
	set data = req.HttpResponse.Data.Read()
    set status=##class(%XML.TextReader).ParseStream(data,.textreader)
    //check status
    if $$$ISERR(status) {do $System.Status.DisplayError(status) quit}

    if (pPathType="K") {
        set strPath = "/Export/Document/Module/Keywords"
    } else {
        set strPath = "/Export/Document/Module/Dependencies/ModuleReference/Name"
    }

    //iterate through document, node by node
    while textreader.Read()
    {   
        if (textreader.Path = strPath) { 
            If textreader.Value'="" {
                set tReturn = tReturn_$listbuild(textreader.Value)
            }
        }
    }
    
    quit tReturn
}

/// do ##class(dc.zpm.Utils).getNamespaceList()
ClassMethod getNamespaceList() As %Status
{

	New $Namespace
	Set $Namespace = "%SYS"

	Set tSC = $System.Status.OK()
	Set arrayEnsNamespace = []

	Try {

		Set oRS = ##class(%SQL.Statement).%New()

		Set tSC = oRS.%PrepareClassQuery("Config.Namespaces", "List")

		Quit:$System.Status.IsError(tSC)

		Set result = oRS.%Execute()

		If (result.%SQLCODE '< 0) {
			While result.%Next() {
				Set json = { }

                ;Skip %ALL
				Continue:(result.%GetData(1) = "%ALL")

		  		Do json.%Set("id",result.%GetData(1))
				Do json.%Set("text",result.%GetData(1)) 
				Do arrayEnsNamespace.%Push(json)
			}
		}
		Else {
			Throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE,result.%Message)
		}
	}
	Catch (oException) {
		Set tSC = oException.AsStatus()
	}

	Write arrayEnsNamespace.%ToJSON() 

	Quit tSC
}

/// Get Installed Packages in all Namespaces
ClassMethod GetPackageAllNamespaces() As %Status
{
    New $Namespace
	Set $Namespace = "%SYS"
    
	Set tSC = $System.Status.OK()
	Set arrayEnsNamespace = []

	Try {
        // Listing All Namespaces
		Set oRS = ##class(%SQL.Statement).%New()
		Set tSC = oRS.%PrepareClassQuery("Config.Namespaces", "List")
		Quit:$System.Status.IsError(tSC)
		
        Set result = oRS.%Execute()

		If (result.%SQLCODE '< 0) {
			While result.%Next() {		
                ;Skip %ALL
				Continue:(result.%GetData(1) = "%ALL")
                do ..GetInstalledPackages(result.%GetData(1))
			}
		}
		Else {
			Throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE,result.%Message)
		}
	}
	Catch (oException) {
		Set tSC = oException.AsStatus()
	}

    Quit tSC
}

/// Get Installed Packages in all Namespaces
ClassMethod GetInstalledPackageAllNamespaces() As %Status
{
    Set tCurrentNamespace = $Namespace
    
    do ..GetPackageAllNamespaces()

    New $Namespace
	Set $Namespace = tCurrentNamespace
    
    // Read ^["%SYS"]zpmXplorerInstalled and return json
    Set arrayApp = []
    
    set idNamespace = ""
    for {
        set idNamespace = $order(^["%SYS"]zpmXplorerInstalled(idNamespace))
        quit:idNamespace=""

        set idPackage = ""
        for {
            set idPackage = $order(^["%SYS"]zpmXplorerInstalled(idNamespace,idPackage))
            quit:idPackage=""

            set listPackage = $get(^["%SYS"]zpmXplorerInstalled(idNamespace,idPackage))
            set installDate = $listget(listPackage,1)
            set installVersion = $listget(listPackage,2)
            set currentVersion = ..GetCurrentVersion(idPackage)

            set json = {}
            do json.%Set("id",idNamespace_"||"_idPackage)
            do json.%Set("namespace",idNamespace)
            do json.%Set("name",idPackage)
            do json.%Set("dateTimeInstallation",installDate)
            do json.%Set("version",installVersion)
            do json.%Set("currentVersion",currentVersion)
            do arrayApp.%Push(json)
        }
    }

    do arrayApp.%ToJSON()

    Quit $$$OK
}

}
