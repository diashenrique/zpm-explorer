/// Utility class for ZPM Explorer project
Class dc.zpm.Charts
{

/// Split Tags
ClassMethod SplitTag(pArrayTags As %DynamicArray) As %Status
{
    Set sc = $$$OK
    
    set N = pArrayTags.%Size()
    Write N,! 
    For i=0:1:N-1 {
        write pArrayTags.%Get(i),!
    }

    Return sc
}

/// Call Tags
ClassMethod CallTags(pPackageName As %String, pVersion As %String) As %Status
{
    Set sc = $$$OK
    
    set arrTags = ##class(dc.zpm.Utils).GetTags(pPackageName,pVersion)

    write arrTags,!

    do ..SplitTag(arrTags)

    Return sc
}

/// Load tags / dependences modules
ClassMethod LoadPackages() As %Status
{
    Set sc = $$$OK
    
    kill ^zpmXplorerTags
    kill ^zpmXplorerDependence

    if ($data(^zpmXplorerVersion) = 0) {
        do ##class(dc.zpm.Utils).GetPackages()
    }
    
    set packName = ""
    for { 
        set packName = $order(^zpmXplorerVersion(packName))
        quit:packName=""

        set version = $get(^zpmXplorerVersion(packName))
        write packName_":"_version,!

        set arrTags = ##class(dc.zpm.Utils).ReadManifest(packName,$zconvert(version,"O","URL"),"K")
        if (arrTags '= "") {
            set ^zpmXplorerTags(packName) = $listtostring($listbuild(arrTags))
        }

        set arrDepend = ##class(dc.zpm.Utils).ReadManifest(packName,$zconvert(version,"O","URL"),"D")
        if (arrDepend '= "") {
            set ^zpmXplorerDependence(packName) = $listtostring($listbuild(arrDepend))
        }
    }

    Return sc
}

/// Build Word Cloud chart datasource
ClassMethod BuildWordCloudDatasource() As %Status
{
    Set %response.ContentType = "application/json"

    kill ^zpmXplorerTagCount
    
    Set sc = $$$OK
    // data structure for Word Cloud chart 
    // [{"name": "tag1", "weight": countNum},{"name": "tag2", "weight": countNum}]
    set wcPackName = ""
    for {
        set wcPackName = $order(^zpmXplorerTags(wcPackName))
        quit:wcPackName=""

        set idTag = ""
        set tagCount = 0
        set strkeyWords = $listget($get(^zpmXplorerTags(wcPackName)))
        set strkeyWords = $zconvert($zstrip(strkeyWords,"<>W"),"L")
        if $find(strkeyWords,$char(32)) {
            set strkeyWords = $translate(strkeyWords,$char(32),",")
        }
        
        for {
            set tagCount = $increment(tagCount)
            set idTag = $piece(strkeyWords,",",tagCount)
            quit:idTag=""

            set countTag = 1
            set ^zpmXplorerTagCount(idTag) = countTag + $get(^zpmXplorerTagCount(idTag))
        }
    }

    set arrWordCloud = []
    set idTagCount = ""
    for {
        set idTagCount = $order(^zpmXplorerTagCount(idTagCount))
        quit:idTagCount=""

        set json = {}
        do json.%Set("name",idTagCount)
        do json.%Set("weight",$number($get(^zpmXplorerTagCount(idTagCount))))
        do arrWordCloud.%Push(json)
    }

    Set start = $G(^zpmXplorerTaskInfo("RunLoadPackages", "start"), "")
    Set finish = $G(^zpmXplorerTaskInfo("RunLoadPackages", "finish"), "")
    Set start = $Replace($Replace($Replace(start, "-", ""), ":", ""), " ", "")
    Set finish = $Replace($Replace($Replace(finish, "-", ""), ":", ""), " ", "")
    Set lastUpdate = ""
    If (start = "") {
        Set loadingStatus = "NO_DATA"
    } ElseIf (start < finish) {
        Set msg = "ZPM data loaded (last update: "_^zpmXplorerTaskInfo("RunLoadPackages", "finish")_")"
        Set loadingStatus = "DONE"
        Set lastUpdate = ^zpmXplorerTaskInfo("RunLoadPackages", "finish")
    } Else {
        Set msg = "Updating ZPM data... displaying partial info."
        Set loadingStatus = "LOADING"
    }
    Set resp = {
        "loadingStatus": (loadingStatus),
        "lastUpdate": (lastUpdate),
        "data": (arrWordCloud)
    }
    do resp.%ToJSON()

    Return sc
}

/// Build Sankey diagram datasource
ClassMethod BuildSankeyDataSource() As %Status
{
    Set sc = $$$OK
    // data structure for Sankey diagram
    //  keys: ['from', 'to', 'weight'],
    //  data: [
    //      ['Brazil', 'Portugal', 1],
    //      ['Brazil', 'France', 1]
    //  ] 

    set arrDataSouce = []
    set idPackName = ""
    for {
        set idPackName = $order(^zpmXplorerDependence(idPackName))
        quit:idPackName=""

        set listDependence =  ^zpmXplorerDependence(idPackName)
        
        set i=1
        set arrDependence = []

        for i=1:1:$listlength(listDependence) {
            set dependenceModule = $listget(listDependence,i)
            do arrDependence.%Push(idPackName)
            do arrDependence.%Push(dependenceModule)
            do arrDependence.%Push(1)
            do arrDataSouce.%Push(arrDependence)
        }
        break
    }

    Set resp = {
        "data": (arrDataSouce)
    }
    do resp.%ToJSON()

    Return sc
}

/// Runs LoadPackages method logging it output to a file
ClassMethod RunLoadPackages() As %Status
{
    Set sc = $$$OK

    Set dev = $$$FormatText("/tmp/log-load-packages-%1.txt", $REPLACE($HOROLOG,",",""))
    Open dev:("ARW"):5
    Use dev
    Set ^zpmXplorerTaskInfo("RunLoadPackages", "start") = $ZDT($H, 3)
    Try {
        Do ##class(dc.zpm.Charts).LoadPackages()
        Set ^zpmXplorerTaskInfo("RunLoadPackages", "status") = 1
    }
    Catch ex {
        Set sc = ex.AsStatus()
        ZW sc
        Set ^zpmXplorerTaskInfo("RunLoadPackages", "status") = sc
    }
    Set ^zpmXplorerTaskInfo("RunLoadPackages", "finish") = $ZDT($H, 3)
    Close dev

    Return sc
}

/// Creates a task for grab data for ZPM packages
/// Runs every day at 0h
/// Based on iris-cron-task
ClassMethod CreateSankeyDataSourceTask(ByRef tid As %Integer) As %Status
{
    Set sc = $$$OK

    Set task=##class(%SYS.Task).%New()
    Set taskdef = ##class(%SYS.Task.RunLegacyTask).%New()

    Set runcode = "Do ##class(dc.zpm.Charts).RunLoadPackages()"

    Set task.Name = "RunLoadPackages"
    Set task.NameSpace = $Namespace
    Set task.TimePeriod = 0 // Daily
    Set task.TimePeriodEvery = 1 // Every 1 day
    Set task.DailyFrequency = 0 // Run once in a day
    Set task.StartDate = $p($H + 1,",",1) // Start tomorrow

    Set task.TaskClass = $classname(taskdef)
    Set taskdef.ExecuteCode = runcode

    Do task.AssignSettings(taskdef)
    Set sc = task.%Save()
    Return:$$$ISERR(sc) sc

    set tid = task.%Id()
    set sc = ##class(%SYS.Task).RunNow(tid)

    Kill ^zpmXplorerTaskInfo
    Kill ^zpmXplorerTags
    Kill ^zpmXplorerTagCount
    Kill ^zpmXplorerDependence

    Return sc
}

}
