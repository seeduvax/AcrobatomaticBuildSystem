<?xml version="1.0" encoding="UTF-8"?><cr id="480c6aa9e411034c81c6855e69349b6fd3b95812e66d260b01a4afaf3ac6598d" state="working">
    <title>Java package handling issues on make dist with cygwin</title>
    <reporter>sdevaux</reporter>
    <creation>2023-02-09 13:02:43+01:00</creation>
    <description>
        <p>When packaging Java application such as graem with make dist, the build fails on</p>
        <p>windows/cygwin because of symbolic links created that are not accessible to the</p>
        <p>native Java commands.</p>
    </description>
    <links>
        <link name="parent"> bfca44f877c9cb6e2fbd92dbec6ba421c47c889dc70d28b370b8aa9013a7f45e</link>
    </links>
    <cf v="sdevaux 2023-02-09T13:10:53+01:00"/>
</cr>
