<?xml version="1.0" encoding="UTF-8"?><cr id="8bcf1b216918ed84e942c7d710a611a3b768b3dbc31320361c29203976a08693" state="working">
    <title>Do not commit local uncommited changes on tag</title>
    <reporter>sdevaux</reporter>
    <creation>2023-02-16 14:23:43+01:00</creation>
    <description>
        <p>Ensure the git workspace is clean of any uncommitted change when tagging to avoid propagation of any unexpected state. User shall be warned and suggested to commit explicitely or stash its local changes before proceeding again.</p>
    </description>
    <links>
        <link name="parent"> bfca44f877c9cb6e2fbd92dbec6ba421c47c889dc70d28b370b8aa9013a7f45e</link>
    </links>
    <cf v="sdevaux 2023-02-17T18:11:42+01:00"/>
</cr>
