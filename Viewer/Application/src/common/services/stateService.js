/***************************************************************
 * State Service
 * Service is responsible for creating the state model, which 
 * houses all the parameters (used in the url) in each of the 
 * states application's states within a single session.
* *************************************************************/

angular.module('PMTViewer').service('stateService', function ($state, $rootScope, $stateParams, $location, config) {

    // the application's state model
    var appState = {
        /***************************************************************
         * each application state's parameters (i.e. lat, lng)
         * and their previous state parameters (i.e. last_lat, last_lng)
         * - only include parameters that will be broadcast on change
         * - all parameters must include a corresponding 'last_' parameter
         * - state object must be the same as the state's name (PMTViewer.config)
         * *************************************************************/
        states: {
            login: {},
            home: {},
            locations: {
                lat: "",
                last_lat: "",
                lng: "",
                last_lng: "",
                zoom: "",
                last_zoom: "",
                area: "",
                last_area: "",
                selection: "",
                last_selection: "",
                basemap: "",
                last_basemap: "",
                layers: "",
                last_layers: ""
            },
            activities: {
                lat: "",
                last_lat: "",
                lng: "",
                last_lng: "",
                zoom: "",
                last_zoom: "",
                basemap: "",
                last_basemap: "",
                layers: "",
                last_layers: "",
                activity_id: "",
                last_activity_id: ""
            },
            map: {
                lat: "",
                last_lat: "",
                lng: "",
                last_lng: "",
                zoom: "",
                last_zoom: "",
                basemap: "",
                last_basemap: "",
                layers: "",
                last_layers: ""
            },
            partnerlink: {},
            editor: {
                lat: "",
                last_lat: "",
                lng: "",
                last_lng: "",
                zoom: "",
                last_zoom: "",
                basemap: "",
                last_basemap: "",
                layers: "",
                last_layers: "",
                editor_activity_id: "",
                last_editor_activity_id: "",
                editor_parent_id: "",
                last_editor_parent_id: "",
                editor_parent_title: "",
                last_editor_parent_title: ""
            },
            agra: {},
            tax: {
                tax_id: "",
                last_tax_id: ""
            },
            orgs: {},
            admin: {},
            video: {},
            grant: {}
        },
        /***************************************************************
         * default application state's parameters (i.e. lat, lng)          
         * - loaded in init() from the config
         * *************************************************************/
        defaults: {
            login: {},
            home: {},
            locations: {},
            activities: {},
            map: {},
            partnerlink: {},
            editor: {},
            agra: {},
            tax: {},
            orgs: {},
            admin: {},
            video: {},
            grant: {}
        },
        last_state: 'login'
    };

    inti();

    // get a state model
    appState.getState = function () {
        return appState.states[$state.current.name];
    };
    // update the state model
    appState.updateState = function () {
        // get the state model
        var state = appState.states[$state.current.name];
        // get the defaults model
        var defaults = appState.defaults[$state.current.name];
        // get all the parameters (names)
        var params = Object.keys(state);
        // filter out just the state parameters (names)
        var stateParams = _.filter(params, function (param) { if (param.indexOf('last_') == -1) return param; });
        // filter out just the last state parameters (names)
        var lastParams = _.filter(params, function (param) { if (param.indexOf('last_') !== -1) return param; });
        // order both param lists ensuring alignment of related params
        // (i.e. zoom and last_zoom will be at the same index
        _.sortBy(stateParams, function (param) { return param });
        _.sortBy(lastParams, function (param) { return param });

        // add the current path to local storage
        localStorage.setItem('defaultRoute', $location.path());

        // assign stateParams with the current values
        for (var i = 0; i < stateParams.length; i++) {
            state[stateParams[i]] = $stateParams[stateParams[i]];
        }

        // evaluate each parameter for change and 
        // execute the appropriate response
        for (var x = 0; x < stateParams.length; x++) {
            if (state[stateParams[x]] !== state[lastParams[x]]) {
                // broadcast the state has changed
                var broadcastName = stateParams[x] + '-update';
                $rootScope.$broadcast(broadcastName, state[stateParams[x]]);
                // console.log('The state param "' +
                //         stateParams[x] + '" has been updated: ' + 
                //         state[stateParams[x]]);
                // update the last parameter value
                state[lastParams[x]] = state[stateParams[x]];
            }
        }

         // broadcast the url has been updated
         $rootScope.$broadcast('route-update');

    }
    // validate param is in URL
    appState.isParam = function (paramName) {
        var bool = $stateParams[paramName];
        if (bool) {
            return true;
        }
        return false;
    };
    // validate param is NOT in URL
    appState.isNotParam = function (paramName) {
        var bool = $stateParams[paramName];
        if (bool) {
            return false;
        }
        return true;
    };
    // toggle a panel parameter (open/closed)
    // panel parameters: filter-panel,detail-panel, target-analysis-panel
    appState.toggleParam = function (paramName) {
        var bool = $stateParams[paramName];
        if (!bool) {
            // logic that makes only 1 panel open at a time from the right panel
            //check if selected parameter is in the right panel
            var rightPanels = ['detail-panel', 'target-analysis-panel', 'travel-panel', 'activity-search-results'];
            if (_.contains(rightPanels, paramName)) {
                //make all right panels closed
                _.each(rightPanels, function (param) {
                    $stateParams[param] = null;
                });
            }
            $stateParams[paramName] = 'open';
        } else {
            delete $stateParams[paramName];
        }
        var state = $state.current.name || 'home';
        appState.setState(state, $stateParams, false);
    };
    // open a panel parameter
    // panel parameters: filter-panel,detail-panel, target-analysis-panel
    appState.openParam = function (paramName) {
        var bool = $stateParams[paramName];
        if (!bool) {
            // mutex logic that makes only 1 panel open at a time
            for (var param in $stateParams) {
                if ($stateParams[param] === 'open') {
                    $stateParams[param] = null;
                }
            }
            $stateParams[paramName] = 'open';
            var state = $state.current.name || 'home';
            appState.setState(state, $stateParams, false);
        }
    };
    // close a panel parameter
    // panel parameters: filter-panel,detail-panel, target-analysis-panel
    appState.closeParam = function (paramName) {
        var bool = $stateParams[paramName];
        if (bool) {
            delete $stateParams[paramName];
            var state = $state.current.name || 'home';
            appState.setState(state, $stateParams, false);
        }
    };
    // validate if passed state is current state (i.e. home)
    appState.isState = function (stateName) {
        return $state.$current.name === stateName;
    };
    // validate whether a specific state is active (i.e. home)
    appState.isNotState = function (stateName) {
        return $state.$current.name !== stateName;
    };
    // set a parameter with a passed value
    appState.setParamWithVal = function (paramName, val) {
        $stateParams[paramName] = val;
        var state = $state.current.name || 'home';
        appState.setState(state, $stateParams, false);
    };
    // validate if parameter has changed
    appState.paramChanged = function (paramName) {
        // get the state model
        var state = appState.states[$state.current.name];
        // determine if the parameter value has changed
        if (state[paramName] !== state['last_' + paramName]) {
            return true;
        }
        else {
            return false;
        }
    };
    // set state
    appState.setState = function (state, params, reload) {
        if (reload) {
            $state.go(state, params);
        }
        else {
            $state.go(state, params, {
                // prevent the events onStart and onSuccess from firing
                notify: false,
                // prevent reload of the current state
                reload: false,
                // replace the last record when changing the params so you don't hit the back button and get old params
                location: 'replace',
                // inherit the current params on the url
                inherit: true
            });
            // update the state b/c we are restricting the state update
            // AppCtrl is responsible for calling the state
            // update in normal operation of the ui-router
            appState.updateState();
        }
    }
    // intialization function
    function inti() {
        //var states = _.pluck(config.states, 'stateParamDefaults');
        for (var state in appState.states) {
            var stateConfig = _.find(config.states, function (states) { return states.route == state; });
            if (stateConfig) {
                appState.defaults[state] = stateConfig.stateParamDefaults || null;
                if (stateConfig.stateParamDefaults) {
                    for (var param in stateConfig.stateParamDefaults) {
                        if (typeof appState.states[state][param] != "undefined") {
                            appState.states[state][param] = stateConfig.stateParamDefaults[param];
                        }
                    }
                }
            }
        }
    }

    return appState;
});