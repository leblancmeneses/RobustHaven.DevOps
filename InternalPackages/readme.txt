packages.content.config
===========================
<?xml version="1.0" encoding="utf-8"?>
<packages>
	<package id="RazorGenerator.Templating" action="remove" content="HandleFolders; SampleTemplate.cshtml; SampleTemplate.generated.cs"/>
<!--
where folder "HandleFolders" is recursively removed
and individual files "SampleTemplate.cshtml", "SampleTemplate.generated.cs" as also removed -->



	<package id="RazorGenerator.Templating" action="remove" />
	<package id="RazorGenerator.Templating" action="remove" content="*"/>
<!--
	all content items added are removed-->
</packages>
