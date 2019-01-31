# PMT Build Process

The PMT Viewer application uses [Grunt](http://gruntjs.com/) to take
all the developed code and publish (_web server ready_) a web application 
for a specific [PMT Theme](PMTTheme.md). The following documents the 
[Grunt](http://gruntjs.com/) process.


## File Overview

Files used in the build process and a brief description of their role:

- **[app.config.js](app.config.js)** - The application and theme configuration. (_This 
file is covered in detail in the [PMT Theme](PMTTheme.md) documentation. This document
covers what the build process does with this file, not its contents._)

- **[build.config.js](build.config.js)** - The build configuration. This file contains 
variables, which are used by the Gruntfile.js. Each file contains comprehensive in-line
documentation.

- **[Gruntfile.js](Gruntfile.js)** - The Grunt build file. This file contains all the 
logic for the build process, which is executed by [Grunt](http://gruntjs.com/). Each 
file contains comprehensive in-line documentation.

## How to Build

Execute the build using the following command from the projects SourceCode directory:

```
grunt -theme=<name_of_the_theme>
```

#### Examples:

SpatialDev theme (spatialdev) is the default theme:
```
grunt
```
is the same as:
```
grunt -theme=spatialdev
```
BMGF theme:
```
grunt -theme=bmgf
```


## Process Detail

There are two main Grunt tasks: build and compile. Both are documented with a 
description, name of the grunt task and the variables used from the 
[build.config.js](build.config.js) build configuration file.


### build

The build task takes all the development code in SourceCode and builds it into a web 
application in the _build_ directory. The build processes executes
the following tasks to accomplish this:

1. Deletes all the files in the build process directories (_build_, _bin_)
  - **task**: clean
  - **variables**: build_dir, compile_dir
2. Create the Angularjs module with the constants from app.config.js for the 
specificed theme and places the module in the _src/app_ directory.
  - **task**: 'ngconstant:' + theme
  - **file**: src/app/config.js
3. Validates all the javascript files specified by _app_files.js_..
  - **task**: jshint
  - **variables**: app_files.js
4. Compile the main.less file into one CSS. Only the main.less file should be targeted. 
All other less. files should be imported into this file. Theme based less should follow
guidelines specificed in [PMT Themes](PMTThemes.md) and are imported based on the 
_theme_ variable used in the grunt command.
  - **task**: less:build
  - variable: app_files.less
  - **file**: build/assets/PMT-Viewer-3.0.1.css
5. Concatenate the CSS created in _step 3_ with all the vendor CSS files.
  - **task**: concat:build_css
  - variable: vendor_files.css 
  - **file**: build/assets/PMT-Viewer-3.0.1.css
6. Copy everything in src/assets (images/fonts) to the build directory's _assets_ directory.
  - **task**: copy:build_app_assets
  - **variables**: build_dir
  - **file**: src/assets  &rightarrow;  build/assets
7. Copy everything listed in _vendor_files.assets_ to the build directory's _assets_ 
directory.
  - **task**: copy:build_vendor_assets
  - **variables**: build_dir, vendor_files.assets
  - **file**: vendor/assets  &rightarrow;  build/assets
8. Copy all the application javascript files (keeping directory structure) to the build 
directory's _src_ directory.
  - **task**: copy:build_appjs
  - **variables**: build_dir, app_files.js
  - **file**: src/app  &rightarrow;  build/src/app (all .js files) 
9. Copy all the vendor javascript files (keeping directory structure) listed in 
vendor_files.js to the build directory's _vendor_ directory.
  - **task**: copy:build_vendorjs
  - **variables**: build_dir, vendor_files.js
  - **file**: vendor  &rightarrow;  build/vendor 
10. Copy all the vendor css files (keeping directory structure) listed in 
vendor_files.css to the build directory's _vendor_ directory.
  - **task**: copy:build_vendorcss
  - **variables**: build_dir, vendor_files.css
  - **file**: vendor  &rightarrow;  build/vendor 
11. Copy the index.html file, while inserting all the correct file source tags (```<script>```, 
```<link>```) with their current location after the build process.
  - **task**: index:build ([multiTask](http://gruntjs.com/creating-tasks#multi-tasks))
  - **variables**: most
  - **file**: src/index.html &rightarrow;  build/index.html
12. Compile templates into index.html. 
  - **task**: bake:build
  - **file**: build/index.html
13. Copy karma-unit.js over to the build directory adding all js files as data sources.
  - **task**: karmaconfig ([multiTask](http://gruntjs.com/creating-tasks#multi-tasks))
  - **file**: karma/karma-unit.tpl.js &rightarrow;  build/karma-unit.js
14. Execute karma unit tests.
  - **task**: karma:continuous
  - **variables**: build_dir

### compile

The compile task takes all the development code in SourceCode and builds it
into a web application in the _build_ directory. The build processes executes
the following tasks to accomplish this:

1. Compresses and compile the main.less file into one CSS. Only the main.less file should be targeted. 
All other less. files should be imported into this file. Theme based less should follow
guidelines specified in [PMT Themes](PMTThemes.md) and are imported based on the 
_theme_ variable used in the grunt command.
  - **task**: less:compile
  - variable: app_files.less
  - **file**: build/assets/PMT-Viewer-3.0.1.css
2. Copy everything in build directory's _assets_ (images/fonts) to the compile directory's 
_assets_ directory. Then copy all the vendor css files to the compile directory's _assets_
directory.
  - **task**: copy:compile_assets
  - **variables**: build_dir, compile_dir
  - **file**: build/assets  &rightarrow;  bin/assets
2. ngAnnotate all js sources. Prepares Angular code for minification.
  - **task**: ngAnnotate:compile
  - **variables**: build_dir, app_files.js
3. Concatenate the all the js files from the application and vendors into a single file.
  - **task**: concat:compile_js
  - variable: vendor_files.js
  - **file**: bin/assets/PMT-Viewer-3.0.1.js
4. Minify the single concatenated js file in step 3, with UglifyJS.
  - **task**: uglify
  - **file**: bin/assets/PMT-Viewer-3.0.1.js
5. Copy the index.html file, while inserting all the correct file source tags (```<script>```, 
```<link>```) with their current location after the build and compile process.
  - **task**: index:compile ([multiTask](http://gruntjs.com/creating-tasks#multi-tasks))
  - **variables**: most
  - **file**: src/index.html &rightarrow;  bin/index.html
6. Compile all the templates into index.html. 
  - **task**: bake:compile
  - **file**: bin/index.html