package service;

import model.CodeforcesTag;
import Lambda;
import messages.MessagesHelper;
import model.User;
import model.Group;
import model.Role;
import messages.ResponseStatus;
import messages.ResponseMessage;

class ServiceHelper {
    public static function authorize(role: Role, next: Void -> ResponseMessage): ResponseMessage {
        if (!Authorization.instance.authorize(role)) {
            return { status: ResponseStatus.Error, result: null, message: "Not authorized" };
        } else {
            return next();
        }
    }

    public static function authorizeGroup(group: Group, teacher: User, next: Void -> ResponseMessage): ResponseMessage {
        if (group.teacher.id != teacher.id) {
            return { status: ResponseStatus.Error, result: null, message: "Not authorized" };
        } else {
            return next();
        }
    }

    public static function successResponse(result: Dynamic): ResponseMessage {
        return MessagesHelper.successResponse(result);
    }

    public static function failResponse(errorMessage: String): ResponseMessage {
        return MessagesHelper.failResponse(errorMessage);
    }
}
