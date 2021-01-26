<?xml version="1.0" encoding="UTF-8"?><cr id="d562593b9886cb8d2bccf1870ac590280da2719c30d3fd3b1d6bc7fcc77af9e0" state="working">
    <title>whitespace are improperly added into the generated import.mk when applying extra_import_defs configuration</title>
    <reporter>sdevaux</reporter>
    <creation>2021-01-26 17:15:06+01:00</creation>
    <description>
        <p>The content of extra_import_def shall be expansed in the generation of the import.mk.</p>
        <p>When it is a multi line definition, the processus improperly add a whitespace at the end of each line except the last one.</p>
        <p>This may produce unexpected make variable definition once the import.mk is parsed when running make in a user project and the related macro can't be contenate to other string without an explicit stripping.</p>
        <p>Rework the extra_import_def handling to have a more strict application of the extra_import_def content.</p>
    </description>
    <links>
        <link name="parent"> 9b2cb585e80174165818a90ef9923292679363f36d0e6b345a0fd0d918d62a3d</link>
    </links>
    <cf v="null"> </cf>
</cr>
