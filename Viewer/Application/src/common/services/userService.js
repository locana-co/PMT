/***************************************************************
 * User Service
 * Service to support authentication for PMT users.
* *************************************************************/

angular.module('PMTViewer').service('userService', function ($q, $http, $rootScope, $state, $stateParams, config, pmt, stateService) {
    // the user service model
    var userService = {
        user: {}, // authenticated user
        authenticated: false
    };
    // internal user service attributes
    var service = {
        users: null, // list of all users in the database
        instanceUsers: null, // list of all instance users
        activities: null, // list of activities for instance
        taxonomies: []
    };

    // getters
    userService.getAllActivities = function () { return service.activities; };
    userService.getAllTaxonomies = function () { return service.taxonomies; };
    userService.getAllUsers = function () { return service.users; };
    userService.getAllInstanceUsers = function () { return service.instanceUsers; };

    // f/t user is logged in
    userService.isLoggedIn = function () {
        if (userService.authenticated) { return true; }
        else { return false; }
    };

    // user log in function
    userService.logIn = function (username, password) {
        var deferred = $q.defer();
        var options = {
            username: username,
            password: password,
            pmtInstance: pmt.instance,
            pmtId: pmt.id[pmt.env]
        };
        // call the api to authenticate user
        $http.post(pmt.api[pmt.env] + 'pmt_user_auth', options, { cache: true }).success(function (data, status, headers, config) {
            if (typeof data.user === "undefined") {
                $rootScope.currentUser = null;
            }
            else {
                $rootScope.currentUser = data;
            }
            deferred.resolve(data);
        }).error(function (data, status, headers, c) {
            // return the message
            deferred.reject(data.message);
        });
        return deferred.promise;
    };

    // get PMT users for the current instance
    userService.getInstanceUsers = function () {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env],
            pmtInstance: pmt.instance
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to authenticate user
        $http.post(pmt.api[pmt.env] + 'pmt_users', options, header).success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var users = _.pluck(data, 'response');
            // add the edited and active parameters to our object
            _.each(users, function (u) {
                _.extend(u, { edited: false });
                _.extend(u, { active: false });
                // format access date (most recent user login timestamp without timezone)
                if (u._access_date !== null) {
                    var date = new Date(u._access_date);
                    u._access_date = date.toUTCString();
                }
            });
            users = _.sortBy(users, '_username');
            service.instanceUsers = users;
            // console.log("instance users: ", users);
            deferred.resolve(users);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_users");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // get all PMT users
    userService.getAllUsers = function () {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to authenticate user
        $http.post(pmt.api[pmt.env] + 'pmt_users', options, header).success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var users = _.pluck(data, 'response');
            // add the edited and active parameters to our object
            _.each(users, function (u) {
                _.extend(u, { edited: false });
                _.extend(u, { active: false });
                // format access date (most recent user login timestamp without timezone)
                if (u._access_date !== null) {
                    var date = new Date(u._access_date);
                    u._access_date = date.toUTCString();
                }
            });
            service.users = users;
            deferred.resolve(users);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_users");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // find common PMT users
    userService.findUsers = function (first_name, last_name, email) {
        var deferred = $q.defer();
        var options = {
            first_name: first_name,
            last_name: last_name,
            email: email,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to authenticate user
        $http.post(pmt.api[pmt.env] + 'pmt_find_users', options, header).success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var users = _.pluck(data, 'response');
            deferred.resolve(users);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_users");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // get all PMT roles
    userService.getRoles = function () {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to authenticate user
        $http.post(pmt.api[pmt.env] + 'pmt_roles', options, header, { cache: true }).success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var roles = _.pluck(data, 'response');
            // filter for only active roles
            _.filter(roles, function (r) { return r._active == true; });
            deferred.resolve(roles);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_roles");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // get all user orgs common for the instance
    userService.getCommonOrgs = function () {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env],
            pmtInstance: pmt.instance
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to authenticate user
        $http.post(pmt.api[pmt.env] + 'pmt_user_orgs', options, header, { cache: true }).success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var orgs = _.pluck(data, 'response');
            deferred.resolve(orgs);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_user_orgs");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // get all orgs
    userService.getOrgs = function () {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // use existing data if saved in scope
        if (pmt.orgs) {
            deferred.resolve(pmt.orgs);
            return deferred.promise;
        } else {
            // call the api to authenticate user
            $http.post(pmt.api[pmt.env] + 'pmt_orgs', options, header, { cache: true }).success(function (data, status, headers, config) {
                // remove unneccessary response object from api
                var orgs = _.pluck(data, 'response');
                // save data in scope
                pmt.orgs = orgs;
                deferred.resolve(orgs);
            }).error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_orgs");
                deferred.reject(status);
            });
            return deferred.promise;
        }
    };

    // gets and returns activity details
    userService.getActivities = function (data_group_ids) {
        var deferred = $q.defer();

        var options = {
            data_group_ids: data_group_ids.join(","),
            classification_ids: null,
            imp_org_ids: null,
            fund_org_ids: null,
            org_ids: null,
            start_date: null,
            end_date: null,
            unassigned_taxonomy_ids: null,
            activity_ids: null,
            boundary_filter: null,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the pmt data
        $http.post(pmt.api[pmt.env] + 'pmt_activities', options, header).success(function (data, status, headers, config) {
            var activities = [];
            // loop through data and remove the response object
            _.each(data, function (a) {
                activities.push(a.response);
            });
            service.activities = _.sortBy(activities, 't');;
            deferred.resolve(service.activities);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_activity");
            $rootScope.$broadcast('act-list-updated');
            deferred.reject(status);
        });

        return deferred.promise;
    };

    // edit user
    userService.editUser = function (user, deactivate) {
        var deferred = $q.defer();
        var options = {
            pmtInstance: pmt.instance,
            request_user_id: $rootScope.currentUser.user.id,
            target_user: user,
            delete_record: deactivate,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to authenticate user
        $http.patch(pmt.api[pmt.env] + 'pmt_user', options, header, { cache: false }).success(function (data, status, headers, config) {
            deferred.resolve(data);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: (patch) pmt_user");
            deferred.reject(data.message);
        });
        return deferred.promise;
    };

    // create user
    userService.createUser = function (user) {
        var deferred = $q.defer();
        var options = {
            pmtInstance: pmt.instance,
            request_user_id: $rootScope.currentUser.user.id,
            target_user: user,
            url: config.url, // application instance url
            pmtId: pmt.id[pmt.env],
            email: config.email.newUser
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to authenticate user
        $http.post(pmt.api[pmt.env] + 'pmt_user', options, header, { cache: true }).success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            deferred.resolve(data);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: (post) pmt_user");
            deferred.reject(data.message);
        });
        return deferred.promise;
    };

    // reset password and send new account credentials to user
    userService.resetUserPassword = function (user) {
        var deferred = $q.defer();
        var options = {
            pmtInstance: pmt.instance,
            request_user_id: $rootScope.currentUser.user.id,
            target_user: user,
            url: config.url, // application instance url
            pmtId: pmt.id[pmt.env],
            email: config.email.newPassword
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to authenticate user
        $http.post(pmt.api[pmt.env] + 'pmt_reset_password', options, header, { cache: false }).success(function (data, status, headers, config) {
            // remove unnecessary response object from api
            deferred.resolve(data);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: (post) pmt_reset_password");
            deferred.reject(data.message);
        });
        return deferred.promise;
    };

    // edit user authorized activities
    userService.editUserActivities = function (user, activity_ids, classification_ids, deactivate) {
        var deferred = $q.defer();
        var options = {
            pmtInstance: pmt.instance, // current instance
            request_user_id: $rootScope.currentUser.user.id, // user authorized to grant access to users
            target_user_id: user.id, // user id to grant access to
            activity_ids: activity_ids, // integer array of activity_ids to authorize/unauthorize
            classification_ids: classification_ids, // integer array of classification_ids to authorize/unauthorize
            delete_record: deactivate, // grant or remove access to activities (via id or classification)
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to authenticate user
        $http.post(pmt.api[pmt.env] + 'pmt_user_activities', options, header, { cache: false }).success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            deferred.resolve(data);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: (post) pmt_user_activities");
            deferred.reject(data.message);
        });
        return deferred.promise;
    };

    // validate username availability
    userService.validateUsername = function (username) {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env],
            username: username
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to authenticate user
        $http.post(pmt.api[pmt.env] + 'pmt_validate_username', options, header).success(function (data, status, headers, config) {
            deferred.resolve(data);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_validate_username");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // gets and returns list of classifications for a taxonomy
    userService.getTaxonomy = function (taxonomy, authorizations) {
        var deferred = $q.defer();
        var options = {
            taxonomy_id: taxonomy.taxonomy_id, // taxonomy id
            instance_id: taxonomy.inuse ? pmt.instance : null, // return in-use classifications for data groups owned by the instance
            locations_only: false, // return in-use classifications for activities with locations only
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the classifications for a given taxonomy
        $http.post(pmt.api[pmt.env] + 'pmt_classifications', options, header, { cache: true })
            .success(function (data, status, headers, config) {
                taxonomy.classifications = [];
                // add the active parameter to our object (for checkboxes)
                _.each(data, function (o) {
                    var classification = o.response;
                    _.extend(classification, { active: false });
                    // if the user is authorized for the classification, set the classification to active
                    if (authorizations && authorizations.classification_ids) {
                        if (authorizations.classification_ids.indexOf(classification.id) > -1) {
                            classification.active = true;
                        }
                    }
                    taxonomy.classifications.push(classification);
                });
                var existingTaxonomy = _.find(service.taxonomies, function (t) { return t.taxonomy_id === taxonomy.taxonomy_id; });
                if (existingTaxonomy) {
                    existingTaxonomy.classifications = taxonomy.classifications;
                }
                else {
                    service.taxonomies.push(taxonomy);
                }
                deferred.resolve(service.taxonomies);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_classifications");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // refresh all materialized views in the database
    userService.refreshViews = function () {
        var deferred = $q.defer();
        var options = {
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to refresh all the materialized views in the database
        $http.post(pmt.api[pmt.env] + 'pmt_refresh_views', options, header)
            .success(function (data, status, headers, config) {
                deferred.resolve(data);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_refresh_views");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    return userService;

});