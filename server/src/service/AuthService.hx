package service;

import service.ServiceHelper;
import service.ServiceHelper;
import service.ServiceHelper;
import service.ServiceHelper;
import service.ServiceHelper;
import service.ServiceHelper;
import model.Role;
import model.Role.Roles;
import messages.ResponseMessage;
import messages.UserMessage;
import haxe.crypto.Md5;
import utils.StringUtils;
import messages.SessionMessage;
import model.Session;
import model.User;
import php.Lib.mail;


class AuthService {

    public function new() {}

    /**
    * return Session ID, String
    **/
    public function authenticate(email: String, password: String, firstAuth: Bool = false): ResponseMessage {
        var user = User.getUserByEmailAndPassword(email, password);
        if (null != user) {
            if (canAuth(user.registrationDate, user.emailActivated)) {
                var session = Session.getSessionByUser(user);
                if (null != session && null != Session.manager.search({ id: session.id }).first()) session.update() else session.insert();
                return if (!firstAuth) ServiceHelper.successResponse(user.toSessionMessage(session.id));
                    else ServiceHelper.successResponse(user.toSessionMessage(session.id, "Добро пожаловать! Проверьте, пожалуйста, электронную почту, чтобы активировать вашу регистрацию!"));
            } else return ServiceHelper.failResponse("You can't sign in. The email activation period has expired.");
        }
        return ServiceHelper.failResponse("Email or password is wrong.");
    }

    public function canAuth(date: Date, emailActivated: Bool): Bool {
        return
            if (emailActivated) true;
            else
                if (Date.now().getTime() <= DateTools.delta(date, (86400 * 1000) * 7).getTime()) true;
            else false;
    }

    public function checkSession(sessionId: String): ResponseMessage {
        var session: Session = Session.findSession(sessionId);
        return
            if (null != session)
                ServiceHelper.successResponse(session.user.toSessionMessage(session.id))
            else
                ServiceHelper.failResponse("Session not found.");
    }

    public function doesEmailExist(email: String): Bool {
        return User.manager.count($email == email) > 0;
    }

    public function doesCodeforcesHandleExist(codeforcesHandle: String): Bool {
        return User.manager.count($codeforcesHandle == codeforcesHandle) > 0;
    }

    public function isCodeforcesHandleValid(codeforcesHandle: String): Bool {
        //TODO: implement
        //use https://codeforces.com/api/help/methods#user.info to check if user exists
        return true;
    }

    public function renewPassword(email: String): ResponseMessage {
        var user: User = User.manager.select($email == email, true);
        var subjectForUser ='Scholae: измение пароля';
        var password = StringUtils.getRandomString(StringUtils.alphaNumeric, 8);
        var message = 'Здравствуйте,

ваш новый пароль: $password.

С уважением,
Scholae';
        var from = 'From: no-reply@scholae.lambda-calculus.ru';
        if (null != user) {
            var res = mail(user.email, subjectForUser, message, from);
            user.passwordHash = Md5.encode(password);
            user.update();
            return ServiceHelper.successResponse(res);
        }
        else return ServiceHelper.successResponse(false);
    }

    private function greetUser(user: User) {
        var subjectForUser ='Scholae: здравствуйте!';
        var message = 'Здравствуйте,
мы рады, что вы зарегистрировались в Scholae!
Перейдите по ссылке для подтверждения электронной почты - http://scholae.lambda-calculus.ru/activation/${user.emailActivationCode}
Вы можете входить в систему без подтверждения электронной почты в течении 7 дней.

Удачи в тренировках!

С уважением,
Scholae';
        var from = 'From: no-reply@scholae.lambda-calculus.ru';
        mail(user.email, subjectForUser, message, from);
    }

    public function registerAndAuthenticateUser(user: UserMessage): ResponseMessage {
        if (doesEmailExist(user.email)) {
            return ServiceHelper.failResponse("Email already exists.");
        } else if (doesCodeforcesHandleExist(user.codeforcesHandle)) {
            return ServiceHelper.failResponse("Codeforces Handle already exists.");
        } else {
            var u: User = new User();
            u.email = user.email;
            u.firstName = user.firstName;
            u.lastName = user.lastName;
            u.passwordHash = Md5.encode(user.password);
            u.registrationDate = Date.now();
            u.roles.set(Role.Learner);
            u.codeforcesHandle = user.codeforcesHandle;
            u.emailActivationCode = Md5.encode(Std.string(u.registrationDate));
            u.insert();
            greetUser(u);

            return authenticate(user.email, user.password, true);
        }
    }

    public function emailActivation(code: String): Bool {
        var user: User = User.manager.select($emailActivationCode == code, true);
        if (user != null) {
            user.emailActivationCode = null;
            user.emailActivated = true;
            user.update();

            return true;
        }

        return false;
    }
}
