
$(document).ready(function () {
    // get current url
    var url = window.location.href;
    
    // data
    var methods = [
        ['GET', 'activity', '/activity/id', 'Get details for an activity by id.', '<b>id</b> (integer) - the id of the activity.</br>'],
        ['POST', 'locations for boundaries', '/pmt_locations_for_boundaries', 'Get counts for locations and activities for a requested boundary by feature.', 
            '<b>boundary_id</b> (integer) - the id of the boundary layer</br>' +
            ' <b>data_group_ids</b> (string) - comma delimited list of data group ids</br>'],
        ['POST', 'activity_ids by boundary', '/pmt_activity_ids_by_boundary', 'Get array of activity ids for a requested boundary feature.', 
            '<b>boundary_id</b> (integer) - the id of the boundary layer</br>' +
            '<b>feature_id</b> (integer) - the id of the boundary feature</br>' +
            '<b>data_group_ids</b> (string) - comma delimited list of data group ids</br>']
    ];
    
    
    var tableContent = '';
    // for each item in our method, add a table row and cells to the content string
    $.each(methods, function (idx, method) {
        
        var params = method[4] != null ? method[4] : '';
        tableContent += '<tr>';
        tableContent += '<td>' + method[0] + ' ' + method[1] + '</td>';
        if (method[0] == 'GET')
            tableContent += '<td><a href="' + url + method[2] + '" target="_blank">' + url + method[2] + '<a/></td>';
        else
            tableContent += '<td>' + url + method[2] + '</td>';
        tableContent += '<td>' + method[3] + '</td>';
        tableContent += '<td>' + params + '</td>';
        tableContent += '</tr>';
    });
    
    // inject table part constructed above into the table in #apiMethod
    // section of jade view (./view/homepage.jade)
    $('#apiMethods table tbody').html(tableContent);
});
