/// App Installed 
Class dc.zpm.InstalledPackages Extends %Persistent
{

/// ID of the App Installed
Property AppName As %String;

/// Version installed
Property AppVersion As %String;

/// Date Installed
Property DateInstalled As %Date;

/// Index On Installed App
Index IndexAppName On AppName;

Storage Default
{
<Data name="InstalledPackagesDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>AppName</Value>
</Value>
<Value name="3">
<Value>AppVersion</Value>
</Value>
<Value name="4">
<Value>DateInstalled</Value>
</Value>
</Data>
<DataLocation>^dc.zpm.InstalledPackagesD</DataLocation>
<DefaultData>InstalledPackagesDefaultData</DefaultData>
<IdLocation>^dc.zpm.InstalledPackagesD</IdLocation>
<IndexLocation>^dc.zpm.InstalledPackagesI</IndexLocation>
<StreamLocation>^dc.zpm.InstalledPackagesS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
