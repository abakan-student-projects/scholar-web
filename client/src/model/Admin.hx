package model;

import services.AdminServiceClient;
import action.AdminAction;
import haxe.ds.ArraySort;
import messages.UserMessage;
import utils.RemoteDataHelper;
import utils.UIkit;
import react.ReactUtil;
import react.ReactUtil.copy;
import redux.IMiddleware;
import redux.IReducer;
import redux.StoreMethods;
import utils.IterableUtils;

class Admin
    implements IReducer<AdminAction, AdminState>
    implements IMiddleware<AdminAction, ApplicationState> {

    public var initState: AdminState = {
        users: RemoteDataHelper.createEmpty(),
        tasks: RemoteDataHelper.createEmpty()
    };

    public var store: StoreMethods<ApplicationState>;

    public function new() {}

    public function reduce(state: AdminState, action: AdminAction): AdminState {
        trace(action);
        return switch(action) {
            case Clear: initState;

            case LoadUsers: copy(state, { users: RemoteDataHelper.createLoading() });
            case LoadUsersFinished(users): copy(state, { users: RemoteDataHelper.createLoaded(users) });

            case UpdateRoleUsers(user): state;
            case UpdateRoleUsersFinished(user):
                if (state.users.loaded){
                    var filtered = state.users.data.filter(function(r) { return r.id == user.id; });
                    if (filtered.length > 0) {
                        ReactUtil.assign(filtered[0], [user]);
                    }
                }
                copy(state, { });

            case TestAdaptiveDemo(tasksCount): copy(state, {tasks: RemoteDataHelper.createLoading() });
            case TestAdaptiveDemoFinished(tasks): copy(state, { tasks: RemoteDataHelper.createLoaded(tasks) });
        }
    }

    public function middleware(action: AdminAction, next:Void -> Dynamic) {
        trace(action);
        return switch(action) {
            case LoadUsers:
                AdminServiceClient.instance.getAllUsers()
                .then(function(users) {
                    ArraySort.sort(users, function(x: UserMessage, y: UserMessage) { return if (x.firstName > y.firstName) 1 else -1; });
                    store.dispatch(LoadUsersFinished(users));
                });
                next();

            case UpdateRoleUsers(user):
                AdminServiceClient.instance.UpdateRoleUsers(user)
                .then(function(user) {
                store.dispatch(UpdateRoleUsersFinished(user));
                });
                next();
            case UpdateRoleUsersFinished(user):
                UIkit.notification({ message: "Роль изменена", timeout: 3000 });
                next();

            case TestAdaptiveDemo(tasksCount) :
                    AdminServiceClient.instance.testAdaptiveDemo(tasksCount)
                        .then(function(tasks) {
                        store.dispatch(TestAdaptiveDemoFinished(tasks));
                    });
                next();

            default: next();
        }
    }
}
