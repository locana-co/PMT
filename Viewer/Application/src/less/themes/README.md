# The `src/less/themes` Directory

Remember that *only* `main.less` will be processed during the build, meaning that all other stylesheets must 
be *imported* into that one.

Themes are imported based on the **@theme** variable in `main.less`. By default the variable is alwasy set to
`spatialdev`, but this variable is overridden during the build process by the `--theme=` parameter.

In order for the build process to work properly using the theme variable, it is **very important** that the 
theme less files follow the naming convention of **theme variable**-theme.less

The theme variable must be the same as in the `app.config` file in `config.theme.alias`

###Examples

`spatialdev-theme.less`

`bmgf-theme.less`
