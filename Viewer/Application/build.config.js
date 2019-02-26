/**********************************************************************
 * This file/module contains all configuration for the Grunt build
 * process in Gruntfile.js.
 ***********************************************************************/
module.exports = {
    /**
     * The `build_dir` folder is where our application is compiled during
     * development and the `compile_dir` folder is where our application
     * compiled for publication (web server).
     */
    build_dir: 'build',
    compile_dir: 'bin',

    /**
     * This is a collection of file patterns that refer to our app code (the
     * stuff in `src/`). These file paths are used in the configuration of
     * build tasks. `js` is all project javascript, less tests. `ctpl` contains
     * our reusable components' (`src/common`) template HTML files, while
     * `atpl` contains the same, but for our app's code. `html` is just our
     * main HTML file, `less` is our main stylesheet, and `unit` contains our
     * app's unit tests.
     */
    app_files: {
        appjs: 'src/app/app.js', // the app.js file only
        js: ['src/**/*.js', '!src/**/*.spec.js', '!src/assets/**/*.js'], // only app js (no testing)
        jsunit: ['src/**/*.spec.js'], // testing files only

        atpl: ['src/app/**/*.tpl.html'], // templates from the app directory
        ctpl: ['src/common/**/*.tpl.html'], // templates from the common directory
        tpl: ['src/**/**/*.tpl.html'], // all templates

        html: ['src/index.html'],
        less: 'src/less/main.less' // we only include the main.less, all other includsions should be imported into this file
    },

    /**
     * This is a collection of files used during testing only.
     */
    test_files: {
        js: [
            'vendor/angular-mocks/angular-mocks.js'
        ]
    },

    /**
     * All bower installs are stored in the vendor directory.
     * This is the same as `app_files`, except it contains patterns that
     * reference vendor code (`vendor/`) that we need to place into the build
     * process somewhere. While the `app_files` property ensures all
     * standardized files are collected for compilation, it is the user's job
     * to ensure non-standardized (i.e. vendor-related) files are handled
     * appropriately in `vendor_files.js`.
     *
     * The `vendor_files.js` property holds files to be automatically
     * concatenated and minified with our project source files.
     *
     * The `vendor_files.css` property holds any CSS files to be automatically
     * included in our app.
     *
     * The `vendor_files.assets` property holds any assets to be copied along
     * with our app's assets. This structure is flattened, so it is not
     * recommended that you use wildcards.
     */
    vendor_files: {
        // vendor js files
        js: [
            'vendor/jquery/dist/jquery.min.js',
            'vendor/jquery-ui/jquery-ui.min.js',
            'vendor/angular/angular.min.js',
            'vendor/angular-bootstrap/ui-bootstrap-tpls.min.js',
            'vendor/angular-ui-router/release/angular-ui-router.min.js',
            'vendor/angular-block-ui/dist/angular-block-ui.min.js',
            'vendor/bootstrap/dist/js/bootstrap.min.js',
            'vendor/underscore/underscore-min.js',
            'vendor/leaflet/dist/leaflet-src.min.js',
            'node_modules/leaflet-label/dist/leaflet.label.js',
            'node_modules/esri-leaflet/dist/esri-leaflet.js',
            'node_modules/turf/turf.min.js',
            'src/common/Leaflet.MapboxVectorTile.min.js',
            'vendor/angular-animate/angular-animate.min.js',
            'vendor/angular-aria/angular-aria.min.js',
            'vendor/angular-messages/angular-messages.min.js',
            'vendor/angular-material/angular-material.min.js',
            'vendor/d3/d3.min.js',
	        'src/common/sankey.min.js',
	        'vendor/angularjs-slider/dist/rzslider.min.js',
            'vendor/angular-sortable-view/src/angular-sortable-view.min.js',
            'vendor/angular-material-data-table/dist/md-data-table.min.js',
            'vendor/html2canvas/dist/html2canvas.min.js',
            'vendor/html2canvas/dist/html2canvas.svg.min.js',
            'vendor/canvas2image/canvas2image/canvas2image.min.js',
            'vendor/materialize/dist/js/materialize.min.js',
            'vendor/angular-materialize/src/angular-materialize.min.js',
            'vendor/angular-sanitize/angular-sanitize.min.js',
            'vendor/moment/min/moment.min.js',
            'vendor/ng-idle/angular-idle.min.js',
            'vendor/ng-file-upload/ng-file-upload.min.js',
            'vendor/mdPickers/dist/mdPickers.min.js'
        ],
        // vendor css files
        css: [
            'vendor/leaflet/dist/leaflet.min.css',
            'node_modules/leaflet-label/dist/leaflet.label.css',
            'vendor/angular-block-ui/dist/angular-block-ui.min.css',
            'vendor/bootstrap/dist/css/bootstrap.min.css',
            'vendor/angular-material/angular-material.min.css',
            'vendor/angularjs-slider/dist/rzslider.min.css',
            'vendor/angular-material-data-table/dist/md-data-table.min.css',
            'vendor/mdPickers/dist/mdPickers.min.css'
        ],
        // vendor assets (images/fonts/etc)
        assets: [
            'vendor/leaflet/dist/images/*.*',
            'src/assets/fonts/*.*'
        ],
        themed_assets: {
            "spatialdev": null,
            "bmgf": [
                'src/assets/bmgf-fonts.css',
                'src/assets/gadm0.geojson',
                'src/assets/gadm1.geojson',
                'src/assets/gadm2.geojson'
            ],
            "tanaim": null,
            "ethaim": [
                'src/assets/eth_acc_dissolved.geojson',
                'src/assets/eth_acc.geojson',
                'src/assets/gadm0.geojson',
                'src/assets/eth1.geojson',
                'src/assets/eth2.geojson',
                'src/assets/eth3.geojson',                
                'src/assets/continent.geojson',
                'src/assets/font-awesome.min.css',
                'src/assets/icon_analysis.svg',
                'src/assets/icon_handshake.svg',
                'src/assets/icon_globe.svg',
                'src/assets/icon_orgs.svg',
                'src/assets/icon_key.svg'
            ],
            "agra": [
                'src/assets/agra-fonts.css',
                'src/assets/gadm0.geojson',
                'src/assets/gadm1.geojson',
                'src/assets/gadm2.geojson',                
                'src/assets/continent.geojson',
                'src/assets/font-awesome.min.css',
                'src/assets/icon_analysis.svg',
                'src/assets/icon_handshake.svg',
                'src/assets/icon_globe.svg',
                'src/assets/icon_orgs.svg',
                'src/assets/icon_key.svg',
                'src/assets/century_gothic_bold.eot',
                'src/assets/century_gothic_bold.ttf',
                'src/assets/century_gothic.eot',
                'src/assets/century_gothic.ttf',
                'src/assets/icomoon-locs.eot',
                'src/assets/icomoon-locs.ttf',
                'src/assets/icomoon.eot',
                'src/assets/icomoon.ttf'
            ]
        }
    }
};