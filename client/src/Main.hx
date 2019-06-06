package;

import view.editor.AdminAdaptiveScreen;
import view.UserAchievementScreen;
import notification.NotificationMessage;
import services.NotificationServiceClient;
import view.UserProfileScreen;
import view.teacher.GraphicsRatingScreen;
import view.teacher.ClassLearnersRatingScreen;
import view.teacher.UserRatingScreen;
import view.learner.LearnerRatingScreen;
import view.editor.AdminUsersScreen;
import view.StudentProjectScreen;
import view.EmailActivationScreen;
import view.editor.EditorTasksScreen;
import view.editor.EditorTagsScreen;
import haxe.macro.Compiler;
import js.moment.Moment;
import view.BaseScreen;
import view.IndexView;
import view.teacher.TeacherTrainingScreen;
import view.teacher.TeacherNewAssignmentScreen;
import view.learner.SignUpToGroupScreen;
import view.RenewPasswordResponseView;
import view.ForgetLoginScreen;
import view.teacher.TeacherGroupScreen;
import view.teacher.TeacherDashboardScreen;
import view.RegistrationScreen;
import services.AuthServiceClient;
import services.Session;
import view.LoginScreen;
import view.LearnerDashboardScreen;
import action.ScholaeAction;
import js.html.Element;
import view.LoginView;
import js.html.DivElement;
import redux.Store;
import router.ReactRouter;
import router.RouteComponentProps;
import js.Browser;
import react.ReactDOM;
import react.ReactMacro.jsx;
import redux.Store;
import redux.react.Provider;
import router.Link;
import router.ReactRouter;
import router.RouteComponentProps;


@:jsRequire("moment/locale/ru.js")
class Main {

    /**
		Entry point:
		- setup redux store
		- setup react rendering
		- send a few test messages
	**/

    public static var store: Store<ApplicationState>;

    public static function main() {
        Moment.locale("ru");
        store = ApplicationStore.create();
        render(Browser.document.getElementById('app'), store);
    }

    static function render(root: Element, store:Store<ApplicationState>)
    {
        var history = ReactRouter.browserHistory;

        var app = ReactDOM.render(jsx('
            <Provider store=$store>
				<Router history=$history>
					<Route path="/" component=$BaseScreen onEnter=$restoreSession>
					    <IndexRoute component=$IndexView onEnter=$requireAuth/>
					    <Route path="login" component=$LoginScreen />
					    <Route path="registration" component=$RegistrationScreen />
					    <Route path="activation/:code" component=$EmailActivationScreen />
					    <Route path="teacher/group/:id" component=$TeacherGroupScreen onEnter=$requireAuth />
					    <Route path="teacher/group/:id/user/:userId" component=$UserRatingScreen />
					    <Route path="teacher/group/:id/learners" component=$ClassLearnersRatingScreen />
					    <Route path="teacher/group/:id/new-assignment" component=$TeacherNewAssignmentScreen onEnter=$requireAuth />
					    <Route path="teacher/group/:groupId/training/:trainingId" component=$TeacherTrainingScreen onEnter=$requireAuth />
					    <Route path="teacher" component=$TeacherDashboardScreen onEnter=$requireAuth />
                        <Route path="teacher/group/:id/graphics" component=$GraphicsRatingScreen />
					    <Route path="forget-password" component=$ForgetLoginScreen />
					    <Route path="learner" onEnter=$requireAuth >
					        <IndexRoute component=$LearnerDashboardScreen />
					        <Route path="rating" component=$LearnerRatingScreen />
                        </Route>
					    <Route path="learner/signup" component=$SignUpToGroupScreen onEnter=$requireAuth />
					    <Route path="learner/group/:id" component=$ForgetLoginScreen onEnter=$requireAuth />
					    <Route path="editor" onEnter=$requireAuth>
    					    <IndexRoute component=$EditorTagsScreen/>
    					    <Route path="tags" component=$EditorTagsScreen />
    					    <Route path="problems" component=$EditorTasksScreen />
					    </Route>
					    <Route path="administrator" component=$AdminUsersScreen onEnter=$requireAuth />
					    <Route path="administrator/adaptive-demo" component=$AdminAdaptiveScreen />
					    <Route path="renew-password-response" component=$RenewPasswordResponseView/>
					    <Route path="student-project" component=$StudentProjectScreen />
					    <Route path="profile" component=$UserProfileScreen />
					    <Route path="achievements" component=$UserAchievementScreen onEnter=$requireAuth/>
					</Route>
				</Router>
			</Provider>
		'), root);
    }

    static function restoreSession(nextState: Dynamic, replace: String->Void, completed:Void->Void) {
        if (store.getState().scholae == null || !store.getState().scholae.auth.loggedIn) {
            if (Session.isUserLoggedIn()) {
                AuthServiceClient.instance.checkSession(Session.sessionId)
                .then(
                    function(sessionMessage) {
                        store.dispatch(Authenticated(sessionMessage));
                        NotificationServiceClient.instance.start();
                    },
                    function(e) {
                        // do nothing
                    });
            }
        }
        completed();
    }

    static function requireAuth(nextState: Dynamic, replace: String->Void, completed:Void->Void) {
        if (store.getState().scholae == null || !store.getState().scholae.auth.loggedIn) {
            if (Session.isUserLoggedIn()) {
                AuthServiceClient.instance.checkSession(Session.sessionId)
                    .then(
                        function(sessionMessage) {
                            store.dispatch(Authenticated(sessionMessage));
                        },
                        function(e) {
                            Session.logout();
                            replace("/login");
                        });
            } else {
                replace("/login");
            }
        }
        completed();
    }

}