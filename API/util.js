module.exports = Util = {};

Util.permissionObjToBoolString = function (obj) {
    var boolString = '';
    boolString += obj._security ? '1' : '0';
    boolString += obj._super ? '1' : '0';
    boolString += obj._delete ? '1' : '0';
    boolString += obj._update ? '1' : '0';
    boolString += obj._create ? '1' : '0';
    boolString += obj._read ? '1' : '0';
    return boolString;
};

Util.boolStringToPermissionObj = function (boolString) {
    return {
        _security: boolString[0] === '1',
        _super: boolString[1] === '1',
        _delete: boolString[2] === '1',
        _update: boolString[3] === '1',
        _create: boolString[4] === '1',
        _read: boolString[5] === '1'
    };
};