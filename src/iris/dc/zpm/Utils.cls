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
            write arrJSON.%Get(key).name_ ", "_arrJSON.%Get(key).description_ ", "_arrJSON.%Get(key).repository_ ", "_arrJSON.%Get(key).versions.%Get(0) ,!
        }
    }
    Catch {
        Write httprequest.HttpResponse.StatusCode_" - "_httprequest.HttpResponse.ReasonPhrase,!
        Set tSC = $$$OK
    }

    Quit tSC
}

}
