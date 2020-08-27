<?xml version="1.0" encoding="utf-8"?>
<cr id="708fe2ce565f1ef3b0c5b081a9217653b4330952aceb1ba59b0d0c8b9b04897e" state="closed">
<title>Hide git error message appearing when no tag has been set yet</title>
<reporter>sdevaux</reporter>
<creation>2020-07-28 11:53:51+02:00</creation>
<description>
<p>*** resolved by 9327a9d ***</p>
<p>When invoking make in an ABD project, when working in a git branch where no tag has been set yet, the followin confusing message appears:</p>
<pre>fatal: No names found, cannot describe anything.</pre>
<p>This message is confusing and let user think its build is failing, but not. Then the message should not be displayed.</p>
</description>
<links>
<link name="parent">b895f70c84f49aad71079c808f7c87e076866f417d55ec8fcd59b545a3799156</link>
<link name="relates">9327a9d1398b2ab2097723dbec919cd59c6b3dbb5e8229d0fc1b08a778ffbe08</link>
</links>
<cf v="null"/>
</cr>
