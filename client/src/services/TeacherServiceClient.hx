package services;

import messages.TrainingMessage;
import messages.AssignmentMessage;
import messages.TagMessage;
import messages.LearnerMessage;
import messages.GroupMessage;
import js.Promise;
import messages.SessionMessage;

class TeacherServiceClient extends BaseServiceClient {

    private static var _instance: TeacherServiceClient;
    public static var instance(get, null): TeacherServiceClient;
    private static function get_instance(): TeacherServiceClient {
        if (null == _instance) _instance = new TeacherServiceClient();
        return _instance;
    }

    public function new() {
        super();
    }

    public function getAllGroups(): Promise<Array<GroupMessage>> {
        return request(function(success, fail) {
            context.TeacherService.getAllGroups.call([], function(e) {
                processResponse(e, success, fail);
            });
        });
    }

    public function getAllTags(): Promise<Array<TagMessage>> {
        return basicRequest(context.TeacherService.getAllTags, []);
    }

    public function getAllLearnersByGroup(groupId: Float): Promise<Array<LearnerMessage>> {
        return request(function(success, fail) {
            context.TeacherService.getAllLearnersByGroup.call([groupId], function(e) {
                processResponse(e, success, fail);
            });
        });
    }

    public function addGroup(name: String, signUpKey: String): Promise<GroupMessage> {
        return request(function(success, fail) {
            context.TeacherService.addGroup.call([name, signUpKey], function(e) {
                processResponse(e, success, fail);
            });
        });
    }

    public function createAssignment(group: GroupMessage, assignment: AssignmentMessage): Promise<AssignmentMessage> {
        return request(function(success, fail) {
            context.TeacherService.createAssignment.call([group, assignment], function(e) {
                processResponse(e, success, fail);
            });
        });
    }

    public function getAssignmentsByGroup(groupId: Float): Promise<Array<AssignmentMessage>> {
        return request(function(success, fail) {
            context.TeacherService.getAssignmentsByGroup.call([groupId], function(e) {
                processResponse(e, success, fail);
            });
        });
    }

    public function createTrainingsByMetaTrainings(groupId: Float): Promise<Array<AssignmentMessage>> {
        return request(function(success, fail) {
            context.TeacherService.createTrainingsByMetaTrainings.call([groupId], function(e) {
                processResponse(e, success, fail);
            });
        });
    }

    public function getTrainingsByGroup(groupId: Float): Promise<Array<TrainingMessage>> {
        return request(function(success, fail) {
            context.TeacherService.getTrainingsByGroup.call([groupId], function(e) {
                processResponse(e, success, fail);
            });
        });
    }

    public function refreshResultsForGroup(groupId: Float): Promise<Array<TrainingMessage>> {
        return request(function(success, fail) {
            context.TeacherService.refreshResultsForGroup.call([groupId], function(e) {
                processResponse(e, success, fail);
            });
        });
    }
}