package service;

import model.Role;
import model.Session;
import model.User;
class Authorization {

    private static var _instance: Authorization;
    public static var instance(get, null): Authorization;
    private static function get_instance(): Authorization {
        if (null == _instance) _instance = new Authorization();
        return _instance;
    }

    public var currentUser(default, null): User;

    private function new() {
        var session: Session = Session.findSession(php.Web.getParams().get("sid"));
        currentUser = if (null != session) session.user else null;
    }

    public function authorize(role: Role): Bool {
        trace(currentUser);
        trace(currentUser.roles.toInt());
        trace(role);
        return if (currentUser != null) currentUser.roles.has(role) else false;
    }
}
