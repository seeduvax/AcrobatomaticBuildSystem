<?xml version="1.0" encoding="UTF-8"?><cr id="9327a9d1398b2ab2097723dbec919cd59c6b3dbb5e8229d0fc1b08a778ffbe08" state="working">
    <title>Complete revision identification with dirty and better tag id</title>
    <reporter>sdevaux</reporter>
    <creation>2020-08-27 16:41:07+02:00</creation>
    <description>
        <p>Improve the revision identifier written in generated binaries:</p>
        <ul>
            <li> On tagged configuration, the revision identifier is the tag name. Add the related commit short hash.</li>
            <li> When no tag is set yet in branch: give the commit hash code.</li>
            <li> Add indicator of non committed changes.</li>
        </ul>
    </description>
    <links>
        <link name="parent"> b895f70c84f49aad71079c808f7c87e076866f417d55ec8fcd59b545a3799156</link>
    </links>
    <cf v="null"> </cf>
</cr>
