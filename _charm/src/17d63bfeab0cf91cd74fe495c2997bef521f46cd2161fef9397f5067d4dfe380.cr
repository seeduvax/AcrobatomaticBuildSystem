<?xml version="1.0" encoding="UTF-8"?><cr id="17d63bfeab0cf91cd74fe495c2997bef521f46cd2161fef9397f5067d4dfe380" state="resolved">
    <title>Python support broken with python 3</title>
    <reporter>sdevaux</reporter>
    <creation>2022-06-20 22:22:52+02:00</creation>
    <description>
        <p>Sample project's python modules build fails on debian 11 that use python 3.9 as default python version.</p>
        <ul>
            <li> sample python code uses `print 'str'` instead of `print('str')`</li>
            <li> move error of src/sampleprj/pysubpckA/__main__.pyc. Is py to pyc compiler still available with python3? </li>
        </ul>
    </description>
    <links>
        <link name="parent"> bfca44f877c9cb6e2fbd92dbec6ba421c47c889dc70d28b370b8aa9013a7f45e</link>
    </links>
    <cf v="null"> </cf>
</cr>
