package services;

import messages.ArrayChunk;
import messages.TaskMessage;
import messages.UserMessage;
import js.Promise;

class AdminServiceClient extends BaseServiceClient {

    private static var _instance: AdminServiceClient;
    public static var instance(get, null): AdminServiceClient;
    private static function get_instance(): AdminServiceClient {
        if (null == _instance) _instance = new AdminServiceClient();
        return _instance;
    }

    public function new() {
        super();
    }


    public function getAllUsers(): Promise<Array<UserMessage>> {
        return request(function(success, fail) {
            context.EditorService.getAllUsers.call([], function(e) {
                processResponse(e, success, fail);
            });
        });
    }

    public function UpdateRoleUsers(user: UserMessage): Promise<UserMessage> {
        return request(function(success, fail) {
            context.EditorService.updateRole.call([user], function(e) {
                processResponse(e, success, fail);
            });
        });
    }

    public function testAdaptiveDemo(tasksCount: Int): Promise<Array<TaskMessage>> {
        return request(function(success, fail) {
            context.EditorService.testAdaptiveDemo.call([tasksCount], function(e) {
                processResponse(e, success, fail);
            });
        });
    }
}
