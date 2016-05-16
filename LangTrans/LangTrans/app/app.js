var app = angular.module('lTrans', []);


app.run(function ($rootScope) {
    $rootScope.apiEndPoint = 'http://localhost:53017/breeze/shopdata/';
    $rootScope.authEndPoint = 'http://localhost:53017/api/';
});