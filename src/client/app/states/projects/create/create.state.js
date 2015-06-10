(function () {
  'use strict';

  angular.module('app.states')
    .run(appRun);

  /** @ngInject */
  function appRun(routerHelper, navigationHelper) {
    routerHelper.configureStates(getStates());
    navigationHelper.navItems(navItems());
    navigationHelper.sidebarItems(sidebarItems());
  }

  function getStates() {
    return {
      'projects.create': {
        url: '/',
        params: {
          projectId: null,
        },
        templateUrl: 'app/states/projects/create/create.html',
        controller: StateController,
        controllerAs: 'vm',
        title: 'Project Create'
      }
    };
  }

  function navItems() {
    return {};
  }

  function sidebarItems() {
    return {};
  }


  /** @ngInject */
  function StateController($q, logger, ProjectQuestion, $stateParams, Projects) {
    var vm = this;

    vm.projectId = $stateParams.projectId



    vm.activate = activate;

    activate();

    function activate() {
      logger.info('Activated Project Question Create View');
      resolveProjects();
      resolveProjectQuestions();
      //initProjectQuestion();
      //initOptions();
    }

    //function initOptions() {
    //  vm.projectQuestion.options.length = 0;
    //  vm.projectQuestion.options.push(angular.extend({}, ProjectQuestion.optionDefaults));
    //  vm.projectQuestion.options.push(angular.extend({}, ProjectQuestion.optionDefaults));
    //}

    // Private

    //function initProjectQuestion() {
    //  vm.projectQuestion = angular.extend(new ProjectQuestion(), ProjectQuestion.defaults);
    //}

    function resolveProjectQuestions(){
      ProjectQuestion.query().$promise.then(function(result){
        vm.projectQuestions = result;
      })
    }

    function resolveProjects() {
      if( vm.projectId){
        Projects.get({
        id: $stateParams.projectId,
        'includes[]': ['approvals', 'approvers', 'services', 'memberships', 'groups', 'project_answers']
      }).$promise.then(function (result) {
          vm.project = result;
        })}else{
        vm.project = {};
      }
    }
  }
})();
