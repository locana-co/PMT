module.exports = angular.module('PMTViewer').controller('FileSelectorCtrl', function ($scope, $rootScope, $mdDialog, pmt, utilService) {

    // initialze module
    var unbinder = $scope.$watch('fileSettings.file', function () {
        //clear displayed info
        $scope.fileSettings.invalidRecords = [];
        $scope.duplicateRecords = [];
        $scope.fileSettings.newRecords = [];
        $scope.fileSettings.allRecords = [];
        $scope.fileSettings.undeleteRecords = [];
        $scope.fileSettings.importSuccess = null;
        $scope.fileSettings.importError = null;

        if ($scope.fileSettings.file != null) {
            $scope.fileSettings.loadingFiles = true;
            parse($scope.fileSettings.file);
        }
    });

    // on click function for close buttons
    $scope.cancel = function () {
        $mdDialog.cancel();
        unbinder();
    };

    $scope.import = function () {
        if ($scope.fileSettings.doReplace) {
            //perform update on each admin level (1-3)
            for (var x = 1; x < 4; x++) {
                replaceAll(x);
            }
        } else {
            //add new records to activity
            var finalRecords = _($scope.fileSettings.newRecords).filter(function (loc) { return _($scope.fileSettings.undeleteRecords).pluck("feature_id").indexOf(loc.feature_id) < 0; });
            _(finalRecords).each(function (loc) {
                $scope.edited_activity.locations["admin" + loc._admin_level].push(loc);
            });

            //previously marked for deletion but now unmarked
            _($scope.fileSettings.undeleteRecords).each(function (rec) {
                rec.delete = false;
            });

        }

        $mdDialog.hide(true);
        unbinder(); //remove listener
    };

    function replaceAll(x) {
        //figure out which records are being added for this level
        var admins = _.chain($scope.fileSettings.allRecords).filter(function (loc) { return loc._admin_level === x; }).pluck("feature_id").value();
        //set all existing to delete
        _($scope.edited_activity.locations["admin" + x]).each(function (existing) {
            if (admins.indexOf(existing.feature_id) > -1) {
                existing.delete = false;
            } else {
                existing.delete = true;
            }
        });
        //set the admins that should stay (they already have id's and don't need to be re-added)
        var adminStaying = _($scope.edited_activity.locations["admin" + x]).filter(function (loc) { return loc.delete || admins.indexOf(loc.feature_id) > -1; });
        //list of existing that do not need to be retained. 
        var adminGoing = _.chain($scope.edited_activity.locations["admin" + x]).filter(function (loc) { return !loc.delete && admins.indexOf(loc.feature_id) === -1; }).pluck("feature_id").value();
        //only keep records that are truly new, others were just changes to delete false
        var finalRecords = _($scope.fileSettings.allRecords).filter(function (loc) { return loc._admin_level === x && (adminGoing.indexOf(loc.feature_id) > -1 || _(adminStaying).findIndex({feature_id: loc.feature_id}) === -1); });
        $scope.edited_activity.locations["admin" + x] = _(finalRecords).union(adminStaying);
    }

    function parse(file) {
        if (file) {

            var scope = $scope;
            utilService.parseCSVtoJSON(file).then(function (locations) {

                //parse data and see what will be added and what was incorrect in file

                var newLocations = _.chain(locations).map(function (loc, n) {
                    if (n > 0) {
                        var l = {
                            _admin0: scope.settings.location.national._admin0, //**Shawna, is this correct? Or sshould I check if the project is national first?**/
                            _admin1: loc[0],
                            _admin2: loc[1],
                            _admin3: loc[2],
                            _admin_level: loc[2] !== "" ? 3 : loc[1] !== "" ? 2 : 1,
                            boundary_id: loc[2] !== "" ? scope.settings.location.boundaries.admin3 : loc[1] !== "" ? scope.settings.location.boundaries.admin2 : scope.settings.location.boundaries.admin1,
                            delete: false,
                            highlight: false,
                            id: null
                        };

                        switch (l._admin_level) {
                            case 1:
                                l.feature_id = _.chain(scope.locations.boundaries).where({ n: l._admin1 }).pluck("id").first().value();
                                break;
                            case 2:
                                var admin2 = _(scope.locations.boundaries).find({ n: l._admin1 });
                                if (admin2 && admin2.b) { l.feature_id = _.chain(admin2.b).where({ n: l._admin2 }).pluck("id").first().value(); }
                                else { l.feature_id = undefined; }
                                break;
                            case 3:
                                var admin_2 = _(scope.locations.boundaries).find({ n: l._admin1 });
                                if (admin_2 && admin_2.b) {
                                    var admin3 = _(admin_2.b).find({ n: l._admin2 });
                                    if (admin3 && admin3.b) { l.feature_id = _.chain(admin3.b).where({ n: l._admin3 }).pluck("id").first().value(); }
                                    else { l.feature_id = undefined; }
                                } else { l.feature_id = undefined; }
                                break;
                        }

                        return l;

                    }
                }).compact().value();

                //find all records that were unable to be located 
                scope.fileSettings.invalidRecords = _(newLocations).where({ feature_id: undefined });
                //remove invalid records from our array
                scope.fileSettings.allRecords = newLocations = _(newLocations).filter(function (loc) { return loc.feature_id; });

                //see if the checkbox was checked that will ignore what the user already has on the page, since it will be replacing them. 
                if (!scope.fileSettings.doReplace) {
                    //find all records that are already existed
                    scope.fileSettings.duplicateRecords = _(newLocations).filter(function (loc) {
                        var existing = _(scope.edited_activity.locations["admin" + loc._admin_level]).find({ feature_id: loc.feature_id });
                        if (existing) {
                            //check if record exists, but is marked for deletion and save for later
                            if (existing.delete) {
                                scope.fileSettings.undeleteRecords.push(existing);
                                return false;
                            }
                            return true;
                        } else { return false; }

                    });
                    //remove duplicate records from our array
                    var dupes = _(scope.fileSettings.duplicateRecords).pluck("feature_id");
                    scope.fileSettings.newRecords = _(newLocations).filter(function (loc) { return dupes.indexOf(loc.feature_id) < 0; });
                }

                scope.fileSettings.importSuccess = true;
                //hide loader
                scope.fileSettings.loadingFiles = false;
            }, function (err) {
                scope.fileSettings.importError = err.data.error ? err.data.error : err.data.message;
                scope.fileSettings.loadingFiles = false;
                // }).notify(function(evt){
                //     $scope.file.progress = evt;
                //     $scope.progressStyle = { width: evt + "%" };

            });



        }

    }

});