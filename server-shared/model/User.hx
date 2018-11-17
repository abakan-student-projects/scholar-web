package model;

import messages.SessionMessage;
import messages.LearnerMessage;
import haxe.crypto.Md5;
import sys.db.Manager;
import sys.db.Types;


@:table("users")
class User extends sys.db.Object {
    public var id: SBigId;
    public var email: SString<512>;
    public var firstName: SString<128>;
    public var lastName: SString<128>;
    public var passwordHash: SString<128>;
    public var roles: SFlags<Role>;
    public var codeforcesHandle: SString<512>;
    public var lastCodeforcesSubmissionId: Float;
    public var registrationDate: SDateTime;
    public var emailActivationCode: SString<128>;
    public var emailActivated: SBool;

    public function new() {
        super();
        roles.set(Role.Learner);
    }

    public static var manager = new Manager<User>(User);

    public static function getUserByEmailAndPassword(email: String, password: String) {
        var users = manager.search( {
            email: email,
            passwordHash: Md5.encode(password)
        });
        return if (users.length > 0) users.first() else null;
    }

    public function toLearnerMessage(): LearnerMessage {
        return
            {
                id: id,
                email: email,
                firstName: firstName,
                lastName: lastName
            };
    }

    public function toSessionMessage(sessionId: String, firstAuthMessage: String = null): SessionMessage {
        return
            {
                userId: id,
                email: email,
                firstName: firstName,
                lastName: lastName,
                roles: roles,
                sessionId: sessionId,
                firstAuthMes: firstAuthMessage
            };
    }

   public function calculateLearnerRating(user:User): Float {
       var rating:Int = 0;
       var results:List<Attempt>;
       results = Attempt.manager.search(($userId ==user.id) && ($solved==true));
       for (item in results) {
           rating += item.task.level;
       }
       return rating;
   }
}
