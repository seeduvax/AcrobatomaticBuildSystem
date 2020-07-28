<?xml version="1.0" encoding="utf-8"?>
<cr id="708fe2ce565f1ef3b0c5b081a9217653b4330952aceb1ba59b0d0c8b9b04897e" state="open">
<title>Hide git error message appearing when no tag has been set yet</title>
<reporter>sdevaux</reporter>
<creation>2020-07-28 11:53:51+02:00</creation>
<description>
<p>When invoking make in an ABD project, when working in a git branch where no tag has been set yet, the followin confusing message appears:</p>
<pre>fatal: No names found, cannot describe anything.</pre>
<p>This message is confusing and let user think its build is failing, but not. Then the message should not be displayed.</p>
</description>
<links>
<link name="parent">b895f70c84f49aad71079c808f7c87e076866f417d55ec8fcd59b545a3799156</link>
</links>
<cf v="null"/>
</cr>
