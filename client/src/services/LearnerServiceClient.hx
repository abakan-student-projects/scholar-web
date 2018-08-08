package services;

import js.Promise;
import messages.GroupMessage;
import messages.LearnerMessage;

class LearnerServiceClient extends BaseServiceClient {

    private static var _instance: LearnerServiceClient;
    public static var instance(get, null): LearnerServiceClient;
    private static function get_instance(): LearnerServiceClient {
        if (null == _instance) _instance = new LearnerServiceClient();
        return _instance;
    }

    public function new() {
        super();
    }

    public function signUp(key: String): Promise<GroupMessage> {
        return request(function(success, fail) {
            context.LearnerService.signUp.call([key], function(e) {
                processResponse(e, success, fail);
            });
        });
    }

}