<?xml version="1.0" encoding="utf-8"?>
<cr id="48c03297d89720a495fd5b3243602d607a986c583af6449f81662cd1f981f8e4" state="working">
<title>No more use find command</title>
<reporter>m026258</reporter>
<creation>2024-08-23 13:37:04+02:00</creation>
<description>
Can do recusrsive file search using only internal make macro. Doing so:
 - sould reduce underlying shell and command coupling
 - may give a slight performance improvement by no more spawning new process for each find.
</description>
<links>
<link name="parent">7bc74cc796c455a46d699ad91f6aca5b7c790f56a6a0968b4ecbce33efce9d25</link>
</links>
<cf v="Sebastien Devaux 2025-04-14T15:31:14+02:00"/>
</cr>
