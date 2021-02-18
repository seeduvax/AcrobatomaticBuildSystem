<?xml version="1.0" encoding="UTF-8"?><cr id="2624922de336af0013aa4e7f8c5194f09ddd16117a9978740c6b24c458883669" state="working">
    <title>ada compilation is confused by abs layout</title>
    <reporter>sdevaux</reporter>
    <creation>2021-02-18 18:23:43+01:00</creation>
    <description>
        <p>Ada compilation is confused and sometimes try to compile ads files from include dir.</p>
        <p>It looks like gnatmake triggers many gcc invoke for one adb file entry and this is clearly not expected.</p>
        <p>Try to call gcc instead of calling gnatmake.</p>
    </description>
    <links>
        <link name="parent"> 9b2cb585e80174165818a90ef9923292679363f36d0e6b345a0fd0d918d62a3d</link>
    </links>
    <cf v="null"> </cf>
</cr>
