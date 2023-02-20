<?xml version="1.0" encoding="utf-8"?>
<cr id="5299b8056324e1e12d6674cad8630ad7a8db336a1010ff43c6a36d3a63e20174" state="closed" delivered="abs-3.3.21">
<title>Charm post commit hook no more running with freshly created workspace</title>
<reporter>sdevaux</reporter>
<creation>2022-12-02 12:59:53+01:00</creation>
<description>
For some unknown reason, .git/hooks does not contain a sample for all
supported hook and post-commit.sample is not present, so the
installation of the post-commit hook is not done for projects using 
charm when performing the first build of a new workspace using an ABS 
version since CR b82a282 has been applied.

ABS version regression appeared at least in ABS-3.3.10.
It should be fixed on next ABS tag, expected to be 3.3.18.
</description>
<links>
<link name="parent">bfca44f877c9cb6e2fbd92dbec6ba421c47c889dc70d28b370b8aa9013a7f45e</link>
</links>
<cf v="sdevaux 2022-12-02T13:09:05+01:00"/>
</cr>
