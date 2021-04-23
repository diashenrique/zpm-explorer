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
            write idTag,!
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

    do arrWordCloud.%ToJSON()
    
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
    }

    do arrDataSouce.%ToJSON()

    Return sc
}

}
