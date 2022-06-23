<?xml version="1.0" encoding="UTF-8"?><cr id="b82a2823eb67b2ae80ad056921dd39fc5e33f895c151c6d8ac2cac8300310c8a" state="resolved">
    <title>git hooks shall be stackable</title>
    <reporter>sdevaux</reporter>
    <creation>2022-02-27 12:56:58+01:00</creation>
    <description>
        <p>Many modules may request to install their own check script for specific</p>
        <p>git processing steps. This shall not overwrite scripts from other modules</p>
        <p>and project specific scripts.</p>
        <p>Then a generic script is installed running all subscripts found in a</p>
        <p>STEP.d directory.</p>
    </description>
    <links>
        <link name="parent"> bfca44f877c9cb6e2fbd92dbec6ba421c47c889dc70d28b370b8aa9013a7f45e</link>
    </links>
    <cf v="null"> </cf>
</cr>
