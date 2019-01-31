# The `src/less` Directory

This is the applications less directory. On build **only** the ```main.less``` file gets processed. All other
less file are **imported** into this file.

Only app-wide styles should be place in this file.

Themes are applied on build, by using the ```--theme``` paramter. [Read more about themes](themes/README.md).
