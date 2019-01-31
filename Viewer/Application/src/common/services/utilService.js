/***************************************************************
 * Utility Service
 * Service to support common functions.
* *************************************************************/

angular.module('PMTViewer').service('utilService', function ($q, $http, $rootScope, pmt, Upload) {

    var utilService = {};

    // converts a date string into a pretty string
    utilService.formatLongDate = function (date_string) {
        try {
            if (date_string != null) {
                var date = new Date(date_string);
                return date.toString();
            }
            else {
                return null;
            }
        }
        catch (ex) {
            // there was an error report it to the error handler
            utilService.logError("There was an error reported by the utilService by formatLongDate(" + date_string + ")", ex);
            return null;
        }
    };

    // converts a date string into a pretty string MM/DD/YYYY
    utilService.formatShortDate = function (date_string) {
        try {
            if (date_string != null) {
                return moment(date_string, "YYYY-MM-DD HH:mm").format("MM/DD/YYYY");
            }
            else {
                return null;
            }
        }
        catch (ex) {
            // there was an error report it to the error handler
            utilService.logError("There was an error reported by the utilService by formatShortDate(" + date_string + ")", ex);
            return null;
        }
    };

    // converts a string to a date
    utilService.parseDateString = function (date_string) {
        try {
            var ymd = date_string.split('-');
            var x = ymd[1] + ymd[2].substring(0, 2) + ymd[0];
            return new Date(ymd[0], ymd[1] - 1, ymd[2].substring(0, 2));
        }
        catch (ex) {
            // there was an error report it to the error handler
            utilService.logError("There was an error reported by the utilService by parseDateString(" + date_string + ")", ex);
            return null;
        }
    };

    // returns the number of days between to dates
    utilService.dateDifference = function (date1, date2) {
        try {
            return Math.round((date1 - date2) / (1000 * 60 * 60 * 24));
        }
        catch (ex) {
            // there was an error report it to the error handler
            utilService.logError("There was an error reported by the utilService by dateDifference(" + date1 + ", " + date2 + ")", ex);
            return null;
        }
    };

    // returns date after adding requested number of days
    utilService.dateAddDays = function (date, days) {
        try {
            var newDate = new Date(date.valueOf());
            newDate.setDate(newDate.getDate() + days);
            return newDate;
        }
        catch (ex) {
            // there was an error report it to the error handler
            utilService.logError("There was an error reported by the utilService by dateDifference(" + date1 + ", " + date2 + ")", ex);
            return null;
        }
    };

    // converts a boolean into yes/no
    utilService.formatBoolean = function (bool) {
        try {
            if (bool) {
                return "Yes";
            }
            else {
                return "No";
            }
        }
        catch (ex) {
            // there was an error report it to the error handler
            utilService.logError("There was an error reported by the utilService by formatBoolean(" + bool + ")", ex);
            return null;
        }
    }

    // formats an numeric value to a money string ($xx,xxx.xx)
    utilService.formatMoney = function (money) {
        try {
            if (money) {
                return "$ " + money.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
            }
            else {
                return "$ 0";
            }
        }
        catch (ex) {
            // there was an error report it to the error handler
            utilService.logError("There was an error reported by the utilService by formatMoney(" + money + ")", ex);
            return null;
        }
    };

    // converts a string to title case (capitalizes the first letter in each word)
    utilService.toTitleCase = function (str) {
        return str.replace(/\w\S*/g, function (txt) { return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase(); });
    }

    // dynamically sort array of objects by parameter
    utilService.dynamicSort = function (property) {
        var sortOrder = 1;
        if (property[0] === "-") {
            sortOrder = -1;
            property = property.substr(1);
        }
        return function (a, b) {
            var result = (a[property] < b[property]) ? -1 : (a[property] > b[property]) ? 1 : 0;
            return result * sortOrder;
        };
    }

    // validate a date
    utilService.validDate = function (date_string) {
        var date = moment(date_string);
        return date.isValid();
    }


    
     // parse csv to json
     utilService.parseCSVtoJSON = function (file) {
        var deferred = $q.defer();
        // collect the list of promises
        // prepare the options for the api call
        
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        //use upload library to send file data to server
        Upload.upload({
                url: pmt.api[pmt.env] + 'csv_to_json',
                data: {file: file},
                headers: {'Authorization': 'Bearer ' + $rootScope.currentUser.token }, 
            }).then(function (resp) {
                //return json object (an array) from the csv data 
                deferred.resolve(resp.data);
            }, function (err) {
            deferred.reject(err);
            }, function (evt) {
                var progressPercentage = parseInt(100 * (Number(evt.loaded) / Number(evt.total)), 10);
                deferred.notify(progressPercentage);
            });



        return deferred.promise;
    };

    return utilService;

});