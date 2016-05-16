angular.module('lTrans', ['ng-translation'])
  .controller('mainController', function($scope, ngTranslation) {

    $scope.languages = ['en', 'fr', 'pl', 'cf', 'es'];

    $scope.update = function (language) {
        if (language == 'en')
            $scope.langText = 'Language: English';
        if (language == 'fr')
            $scope.langText = 'Language: French';
        if (language == 'pl')
            $scope.langText = 'Language: Polish';
        if (language == 'cf')
            $scope.langText = 'Language: Canadian French';
        if (language == 'es')
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
        pl: '3.pl',
        cf: '4.cf',
        es: '5.es'
      })
      .fallbackLanguage('en')
  }])
  .run(function($location, ngTranslation) {
    ngTranslation.use(
      $location.search().lang
    );
  });