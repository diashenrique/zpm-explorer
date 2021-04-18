/// Package info
Class dc.zpm.Packages Extends %Persistent
{

/// Name of the App
Property Name As %String;

/// App Description
Property Description As %String;

/// Repository
Property Repository As %String;

/// App Version
Property Version As %String;

/// Index based on Name
Index IndexName On Name;

Storage Default
{
<Data name="PackagesDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>Repository</Value>
</Value>
<Value name="5">
<Value>Version</Value>
</Value>
</Data>
<DataLocation>^dc.zpm.PackagesD</DataLocation>
<DefaultData>PackagesDefaultData</DefaultData>
<IdLocation>^dc.zpm.PackagesD</IdLocation>
<IndexLocation>^dc.zpm.PackagesI</IndexLocation>
<StreamLocation>^dc.zpm.PackagesS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
