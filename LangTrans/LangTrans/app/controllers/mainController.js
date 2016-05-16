angular.module('lTrans', ['ng-translation'])
  .controller('mainController', function($scope, ngTranslation) {

    $scope.languages = ['en', 'fr', 'po', 'cf', 'sp'];

    $scope.update = function (language) {
        if (language == 'en')
            $scope.langText = 'Language: English';
        if (language == 'fr')
            $scope.langText = 'Language: French';
        if (language == 'po')
            $scope.langText = 'Language: Polish';
        if (language == 'cf')
            $scope.langText = 'Language: Canadian French';
        if (language == 'sp')
            $scope.langText = 'Language: Spanish';
      ngTranslation.use(language);
    };
  })
  //.value({
  //  value1: { foo: 'bar' },
  //  value2: { foo: 'baz' }
  //})
  .config(['ngTranslationProvider', function(ngTranslationProvider) {
    ngTranslationProvider
      .setDirectory('languages/')
      .setFilesSuffix('.json')
      .langsFiles({
        en: '1.en',
        fr: '2.fr',
        po: '3.po',
        cf: '4.cf',
        sp: '5.sp'
      })
      .fallbackLanguage('en')
  }])
  .run(function($location, ngTranslation) {
    ngTranslation.use(
      $location.search().lang
    );
  });