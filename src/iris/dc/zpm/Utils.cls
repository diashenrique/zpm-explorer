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
        Set json = ##class(%DynamicObject).%FromJSON(stream)
        
        write json,!        
    }
    Catch {
        Write httprequest.HttpResponse.StatusCode_" - "_httprequest.HttpResponse.ReasonPhrase,!
        Set tSC = $$$OK
    }

    Quit tSC
}

}
