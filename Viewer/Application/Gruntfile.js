module.exports = function (grunt) {
    /** 
     * Theme argument option. Each theme option needs to have a cooresponding theme 
     * target in the app.config file. See the PMT Theme documentation for more 
     * information on themes.
     */
    var theme = grunt.option('theme');
    if (!theme) {
        theme = 'spatialdev';
    }

    /** 
     * Environment argument option. Each theme in the app.config file must have a settings 
     * object that contains an env parameter. See the PMT Theme documentation for more 
     * information on themes and required settings.
     */
    var environment = grunt.option('env');
    if (!environment) {
        environment = 'stage';
    }

    /** 
     * Load required Grunt tasks. These are installed based on the versions listed
     * in `package.json` when you do `npm install` in this directory.
     */
    grunt.loadNpmTasks('grunt-contrib-clean'); // https://github.com/gruntjs/grunt-contrib-clean
    grunt.loadNpmTasks('grunt-contrib-copy'); //https://github.com/gruntjs/grunt-contrib-copy
    grunt.loadNpmTasks('grunt-contrib-jshint'); //https://github.com/gruntjs/grunt-contrib-jshint
    grunt.loadNpmTasks('grunt-contrib-concat'); //https://github.com/gruntjs/grunt-contrib-concat
    grunt.loadNpmTasks('grunt-contrib-watch'); //https://github.com/gruntjs/grunt-contrib-watch
    grunt.loadNpmTasks('grunt-contrib-uglify'); //https://github.com/gruntjs/grunt-contrib-uglify
    grunt.loadNpmTasks('grunt-contrib-less'); //https://github.com/gruntjs/grunt-contrib-less
    grunt.loadNpmTasks('grunt-karma'); //https://github.com/karma-runner/grunt-karma
    grunt.loadNpmTasks('grunt-ng-annotate'); //https://github.com/mzgol/grunt-ng-annotate
    grunt.loadNpmTasks('grunt-ng-constant'); //https://github.com/werk85/grunt-ng-constant
    grunt.loadNpmTasks('grunt-bake'); //https://github.com/MathiasPaumgarten/grunt-bake
    grunt.loadNpmTasks('grunt-browserify'); //https://github.com/jmreidy/grunt-browserify

    /**
     * Load in our build configuration file.
     */
    var userConfig = require('./build.config.js');

    /**
      * Load in our application configuration file.
      */
    var appConfig = require('./app.config.js');

    /**
     * Update the application configuration file with the environmet setting.
     */
    appConfig.ngconstant[theme].constants.pmt.env = environment;

    /**
     * This is the configuration object Grunt uses to give each plugin its 
     * instructions.
     */
    var taskConfig = {
        /**
         * We read in our `package.json` file so we can access the package name and
         * version. It's already there, so we don't repeat ourselves here.
         */
        pkg: grunt.file.readJSON("package.json"),

        /**
         * The banner is the comment that is placed at the top of our compiled 
         * source files. It is first processed as a Grunt template, where the `<%=`
         * pairs are evaluated based on this very configuration object.
         */
        meta: {
            banner:
            '/**\n' +
            ' * <%= pkg.name %> - v<%= pkg.version %> - <%= grunt.template.today("yyyy-mm-dd") %>\n' +
            ' * <%= pkg.homepage %>\n' +
            ' *\n' +
            ' * Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author %>\n' +
            ' * Licensed <%= pkg.licenses.type %> <<%= pkg.licenses.url %>>\n' +
            ' */\n'
        },
        /**
         * The directories to delete when `grunt clean` is executed.
         */
        clean: [
            '<%= build_dir %>',
            '<%= compile_dir %>'
        ],
        /**
         * The `copy` task just copies files from A to B. We use it here to copy
         * our project assets (images, fonts, etc.) and javascripts into
         * `build_dir`, and then to copy the assets to `compile_dir`.
         */
        copy: {
            build_theme_assets: {
                // copy theme based assets
                files: [
                    {
                        src: [userConfig.vendor_files.themed_assets[theme]],
                        dest: '<%= build_dir %>/assets/',
                        cwd: '.',
                        flatten: true,
                        expand: true
                    }
                ]
            },
            build_app_assets: {
                // copy everything in assets (images/fonts) to build directory assets directory
                files: [
                    {
                        src: [userConfig.vendor_files.assets],
                        dest: '<%= build_dir %>/assets/',
                        cwd: '.',
                        flatten: true,
                        expand: true
                    }
                ]
            },
            build_vendor_assets: {
                files: [
                    {
                        src: ['<%= vendor_files.assets %>'],
                        dest: '<%= build_dir %>/',
                        cwd: '.',
                        expand: true
                    }
                ]
            },
            build_appjs: {
                files: [
                    {
                        src: ['<%= app_files.js %>'],
                        dest: '<%= build_dir %>/',
                        cwd: '.',
                        expand: true
                    }
                ]
            },
            build_vendorjs: {
                files: [
                    {
                        src: ['<%= vendor_files.js %>'],
                        dest: '<%= build_dir %>/',
                        cwd: '.',
                        expand: true
                    }
                ]
            },
            build_vendorcss: {
                files: [
                    {
                        src: ['<%= vendor_files.css %>'],
                        dest: '<%= build_dir %>/',
                        cwd: '.',
                        expand: true
                    }
                ]
            },
            compile_assets: {
                files: [
                    {
                        src: ['**'],
                        dest: '<%= compile_dir %>/assets',
                        cwd: '<%= build_dir %>/assets',
                        expand: true
                    },
                    {
                        src: ['<%= vendor_files.css %>'],
                        dest: '<%= compile_dir %>/',
                        cwd: '.',
                        expand: true
                    }
                ]
            }
        },

        /**
         * `grunt concat` concatenates multiple source files into a single file.
         */
        concat: {
            /**
             * The `build_css` target concatenates compiled CSS and vendor CSS
             * together.
             */
            build_css: {
                src: [
                    '<%= vendor_files.css %>',
                    '<%= build_dir %>/assets/<%= pkg.name %>-<%= pkg.version %>.css'
                ],
                dest: '<%= build_dir %>/assets/<%= pkg.name %>-<%= pkg.version %>.css'
            },
            /**
             * The `compile_js` target is the concatenation of our application source
             * code and all specified vendor source code into a single file.
             */
            compile_js: {
                options: {
                    banner: '<%= meta.banner %>'
                },
                src: [
                    '<%= vendor_files.js %>',
                    'module.prefix',
                    '<%= build_dir %>/src/**/*.js',
                    'module.suffix'
                ],
                dest: '<%= compile_dir %>/assets/<%= pkg.name %>-<%= pkg.version %>.js'
            }
        },

        /**
         * `ngAnnotate` annotates the sources before minifying. That is, it allows us
         * to code without the array syntax.
         */
        ngAnnotate: {
            compile: {
                files: [
                    {
                        src: ['<%= app_files.js %>'],
                        cwd: '<%= build_dir %>',
                        dest: '<%= build_dir %>',
                        expand: true
                    }
                ]
            }
        },

        /**
         * Minify the sources!
         */
        uglify: {
            compile: {
                options: {
                    beautify: true
                },
                files: {
                    '<%= concat.compile_js.dest %>': '<%= concat.compile_js.dest %>'
                }
            },
            build: {
                options: {
                    beautify: true
                },
                files: {
                    '<%= build_dir %>/assets/<%= pkg.name %>-<%= pkg.version %>.js': '<%= build_dir %>/assets/<%= pkg.name %>-<%= pkg.version %>.js'
                }
            }
        },

        /**
         * `grunt-contrib-less` handles our LESS compilation and uglification automatically.
         * Only our `main.less` file is included in compilation; all other files
         * must be imported from this file.
         */
        less: {
            build: {
                files: {
                    '<%= build_dir %>/assets/<%= pkg.name %>-<%= pkg.version %>.css': '<%= app_files.less %>'
                },
                options: {
                    // overrides the @theme variable in main.less
                    modifyVars: {
                        theme: theme
                    }
                }
            },
            compile: {
                files: {
                    '<%= build_dir %>/assets/<%= pkg.name %>-<%= pkg.version %>.css': '<%= app_files.less %>'
                },
                options: {
                    cleancss: true,
                    compress: true,
                    // overrides the @theme variable in main.less
                    modifyVars: {
                        theme: theme
                    }
                }
            }
        },
        browserify: {
            build: {
                files: {
                    '<%= build_dir %>/assets/<%= pkg.name %>-<%= pkg.version %>.js': '<%= app_files.appjs %>'
                }
            },
            compile: {
                files: {
                    '<%= build_dir %>/assets/<%= pkg.name %>-<%= pkg.version %>.js': '<%= app_files.appjs %>'
                }
            }
        },
        /**
         * `jshint` defines the rules of our linter as well as which files we
         * should check. This file, all javascript sources, and all our unit tests
         * are linted based on the policies listed in `options`. But we can also
         * specify exclusionary patterns by prefixing them with an exclamation
         * point (!); this is useful when code comes from a third party but is
         * nonetheless inside `src/`.
         */
        jshint: {
            src: [
                '<%= app_files.js %>',
                '!src/common/**/*.js'
            ],
            test: [
                '<%= app_files.jsunit %>'
            ],
            gruntfile: [
                'Gruntfile.js'
            ],
            options: {
                curly: true,
                immed: true,
                newcap: true,
                noarg: true,
                sub: true,
                boss: true,
                eqnull: true,
                es5: true
            },
            globals: {}
        },

        /**
         * The Karma configurations.
         */
        karma: {
            options: {
                configFile: '<%= build_dir %>/karma-unit.js'
            },
            unit: {
                port: 9019,
                background: true
            },
            continuous: {
                singleRun: true
            }
        },

        /**
         * The `index` task compiles the `index.html` file as a Grunt template. CSS
         * and JS files co-exist here but they get split apart later.
         */
        index: {

            /**
             * During development, we don't want to have wait for compilation,
             * concatenation, minification, etc. So to avoid these steps, we simply
             * add all script files directly to the `<head>` of `index.html`. The
             * `src` property contains the list of included files.
             */
            build: {
                dir: '<%= build_dir %>',
                src: [
                    '<%= vendor_files.js %>',
                    '<%= app_files.tpl %>',
                    //'<%= build_dir %>/src/**/*.js',
                    '<%= vendor_files.css %>',
                    '<%= build_dir %>/assets/<%= pkg.name %>-<%= pkg.version %>.css',
                    '<%= build_dir %>/assets/<%= pkg.name %>-<%= pkg.version %>.js'
                ]
            },

            /**
             * When it is time to have a completely compiled application, we can
             * alter the above to include only a single JavaScript and a single CSS
             * file. Now we're back!
             */
            compile: {
                dir: '<%= compile_dir %>',
                src: [
                    '<%= concat.compile_js.dest %>',
                    '<%= app_files.tpl %>',
                    '<%= vendor_files.css %>',
                    '<%= build_dir %>/assets/<%= pkg.name %>-<%= pkg.version %>.css'
                ]
            }
        },

        /**
         * The `bake` task compiles the templates into `index.html`. Templates are 
         * HTML nodes within a script element, they are parsed on initial document 
         * load time and are put in the DOM right away.
         */
        bake: {
            build: {
                options: {
                    // [[escape]] to prevent overriding angular {{escape}}
                    parsePattern: /\[\[\s?([\.\-\w]*)\s?\]\]/g
                },
                files: {
                    'build/index.html': 'build/index.html'
                }
            },
            compile: {
                options: {
                    // [[escape]] to prevent overriding angular {{escape}}
                    parsePattern: /\[\[\s?([\.\-\w]*)\s?\]\]/g
                },
                files: {
                    'bin/index.html': 'bin/index.html'
                }
            }
        },

        /**
         * This task compiles the karma template so that changes to its file array
         * don't have to be managed manually.
         */
        karmaconfig: {
            unit: {
                dir: '<%= build_dir %>',
                src: [
                    '<%= vendor_files.js %>',
                    '<%= test_files.js %>',
                    '<%= build_dir %>/assets/<%= pkg.name %>-<%= pkg.version %>.js'
                ]
            }
        },

        /**
         * And for rapid development, we have a watch set up that checks to see if
         * any of the files listed below change, and then to execute the listed 
         * tasks when they do. This just saves us from having to type "grunt" into
         * the command-line every time we want to see what we're working on; we can
         * instead just leave "grunt watch" running in a background terminal. Set it
         * and forget it, as Ron Popeil used to tell us.
         *
         * But we don't need the same thing to happen for all the files. 
         */
        delta: {
            /**
             * By default, we want the Live Reload to work for all tasks; this is
             * overridden in some tasks (like this file) where browser resources are
             * unaffected. It runs by default on port 35729, which your browser
             * plugin should auto-detect.
             */
            options: {
                livereload: true
            },

            /**
             * When the Gruntfile changes, we just want to lint it. In fact, when
             * your Gruntfile changes, it will automatically be reloaded!
             */
            gruntfile: {
                files: 'Gruntfile.js',
                tasks: ['jshint:gruntfile'],
                options: {
                    livereload: false
                }
            },

            /**
             * When our JavaScript source files change, we want to run lint them and
             * run our unit tests.
             */
            jssrc: {
                files: [
                    '<%= app_files.js %>'
                ],
                tasks: ['jshint:src', 'karma:unit:run', 'copy:build_appjs']
            },

            /**
             * When assets are changed, copy them. Note that this will *not* copy new
             * files, so this is probably not very useful.
             */
            assets: {
                files: [
                    'src/assets/**/*'
                ],
                tasks: ['copy:build_app_assets', 'copy:build_vendor_assets']
            },

            /**
             * When index.html changes, we need to compile it.
             */
            html: {
                files: ['<%= app_files.html %>'],
                tasks: ['index:build']
            },

            /**
             * When our templates change, we only rewrite the template cache.
             */
            tpls: {
                files: [
                    '<%= app_files.atpl %>',
                    '<%= app_files.ctpl %>'
                ],
                tasks: ['index:build', 'bake:build']
            },

            /**
             * When the CSS files change, we need to compile and minify them.
             */
            less: {
                files: ['src/**/*.less'],
                tasks: ['less:build']
            },

            /**
             * When a JavaScript unit test file changes, we only want to lint it and
             * run the unit tests. We don't want to do any live reloading.
             */
            jsunit: {
                files: [
                    '<%= app_files.jsunit %>'
                ],
                tasks: ['jshint:test', 'karma:unit:run'],
                options: {
                    livereload: false
                }
            },
            browserify: {
                files: '<%= app_files.js %>',
                tasks: 'browserify:build'
            }
        }
    };

    grunt.initConfig(grunt.util._.extend(taskConfig, userConfig, appConfig));


    /**
     * In order to make it safe to just compile or copy *only* what was changed,
     * we need to ensure we are starting from a clean, fresh build. So we rename
     * the `watch` task to `delta` (that's why the configuration var above is
     * `delta`) and then add a new task called `watch` that does a clean build
     * before watching for changes.
     */
    grunt.renameTask('watch', 'delta');
    grunt.registerTask('watch', ['build', 'karma:unit', 'delta']);

    /**
     * The default task is to build and compile.
     */
    grunt.registerTask('default', ['build', 'compile']);

    /**
     * The `build` task gets your app ready to run for development and testing.
     */
    grunt.registerTask('build', [
        'clean',
        'ngconstant:' + theme,
        'jshint',
        'less:build', // compile application css
        'concat:build_css', // compile application and vendor css
        'copy:build_app_assets', // copy common application assets
        'copy:build_theme_assets', // copy theme based assets
        'copy:build_vendor_assets',
        'copy:build_vendorjs',
        'copy:build_vendorcss',
        'browserify:build',
        //'uglify:build',
        'index:build',
        'bake:build',
        'karmaconfig',
        'karma:continuous'
    ]);

    /**
     * The `build-js` task gets just the js ready to run for development and testing.
     */
    grunt.registerTask('build-js', [
        'ngconstant:' + theme,
        'jshint', //confirm valid js
        'copy:build_app_assets', //move over new js file 
        'browserify:build',
        'index:build', //get template changes
        'bake:build'
    ]);

    /**
     * The `compile` task gets your app ready for deployment by concatenating and
     * minifying your code.
     */
    grunt.registerTask('compile', [
        'ngconstant:' + theme,
        'less:compile',
        'copy:compile_assets', 
      //  'browserify:compile',
        'ngAnnotate',
        'concat:compile_js',
       // 'uglify:compile',
        'index:compile',
        'bake:compile'
    ]);

    /**
     * A utility function to get all app JavaScript sources.
     */
    function filterForJS(files) {
        return files.filter(function (file) {
            return file.match(/\.js$/);
        });
    }

    /**
     * A utility function to get all app CSS sources.
     */
    function filterForCSS(files) {
        return files.filter(function (file) {
            return file.match(/\.css$/);
        });
    }

    /**
     * A utility function to get all of the template files
     */
    function filterForTPL(files) {
        return files.filter(function (file) {
            return file.match(/\.tpl.html$/);
        });
    }

    /**
     * A utility function to get all the enabled states for the theme
     */
    function themeStates() {
        var states = [];
        for (var idx in appConfig.ngconstant[theme].constants.config.states) {
            if (appConfig.ngconstant[theme].constants.config.states[idx].enable) {
                states.push(appConfig.ngconstant[theme].constants.config.states[idx]);
            }
        }
        return states;
    }

    /**
     * Takes the list of all of the template files and returns
     * only global template files and the template files we
     * need for the set theme.
     *
     * @param list of template files
     */
    function filterTPLsForTheme(tplFiles) {
        var otherThemes = [];
        //var states = themeStates();
        // gets all of the themes that arent options or the current theme
        for (var obj in appConfig.ngconstant) {
            if (obj === 'options' || obj === theme) {
                continue;
            }
            otherThemes.push(obj);
        }

        // returns a filtered array containing only template files without
        // the other theme names
        return tplFiles.filter(function (file) {
            for (var i = 0; i < otherThemes.length; i++) {
                var otherTheme = otherThemes[i];
                // if the file has the theme name in it
                if (file.indexOf(otherTheme) > -1) {
                    // we want to filter it out
                    return false;
                }
            }
            // include the template only if this theme has it enabled
            //var includeFile = false;
            //for (var idx in states) {
            //    if (file.indexOf('src/app/' + states[idx].route) > -1) {
            //        includeFile = true;
            //    }
            //}
            // no other theme name in given file
            return true;
        });
    }

    /** 
     * The index.html template includes the stylesheet and javascript sources
     * based on dynamic names calculated in this Gruntfile. This task assembles
     * the list into variables for the template to use and then runs the
     * compilation.
     */
    grunt.registerMultiTask('index', 'Process index.html template', function () {
        var dirRE = new RegExp('^(' + grunt.config('build_dir') + '|' + grunt.config('compile_dir') + ')\/', 'g');
        var jsFiles = filterForJS(this.filesSrc).map(function (file) {
            return file.replace(dirRE, '');
        });
        var cssFiles = filterForCSS(this.filesSrc).map(function (file) {
            return file.replace(dirRE, '');
        });
        var tplFiles = filterForTPL(this.filesSrc).map(function (file) {
            return file.replace(dirRE, '');
        });

        tplFiles = filterTPLsForTheme(tplFiles);

        // get all the fonts listed in the app.config.js file
        var fontUrls = [];
        if (appConfig.ngconstant[theme].constants.fonts.length > 0) {
            fontUrls = appConfig.ngconstant.options.constants.global.fonts.concat(appConfig.ngconstant[theme].constants.fonts);
        }
        else {
            fontUrls = appConfig.ngconstant.options.constants.global.fonts;
        }

        /**
         * We need to know the template file paths and names,
         * because we use the name of the template file for the id
         * of the script tag, and the path to get the contents for bake.
         */
        var tpls = [];
        for (var i = 0, len = tplFiles.length; i < len; i++) {
            var tpl = {};
            var path = tpl.path = tplFiles[i];
            tpl.name = path.replace('src/app/', '');
            tpls.push(tpl);
        }

        grunt.file.copy('src/index.html', this.data.dir + '/index.html', {
            process: function (contents, path) {
                return grunt.template.process(contents, {
                    data: {
                        scripts: jsFiles,
                        styles: cssFiles,
                        fonts: fontUrls,
                        tpls: tpls,
                        version: grunt.config('pkg.version')
                    }
                });
            }
        });
    });

    /**
     * In order to avoid having to specify manually the files needed for karma to
     * run, we use grunt to manage the list for us. The `karma/*` files are
     * compiled as grunt templates for use by Karma. Yay!
     */
    grunt.registerMultiTask('karmaconfig', 'Process karma config templates', function () {
        var jsFiles = filterForJS(this.filesSrc);
        grunt.file.copy('karma/karma-unit.tpl.js', grunt.config('build_dir') + '/karma-unit.js', {
            process: function (contents, path) {
                return grunt.template.process(contents, {
                    data: {
                        scripts: jsFiles
                    }
                });
            }
        });
    });

};
