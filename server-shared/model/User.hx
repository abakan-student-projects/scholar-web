package model;


import codeforces.RunnerAction;
import messages.ProfileMessage;
import Std;
import messages.AttemptMessage;
import haxe.ds.ArraySort;
import DateTools;
import Array;
import messages.TagMessage;
import messages.RatingMessage;
import messages.UserMessage;
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
    public var activationDate: SDateTime;
    public var emailActivationCode: SString<128>;
    public var emailActivated: SBool;
    public var lastResultsUpdateDate: SDateTime;
    public var rating: Float;

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

    public function toUserMessage(): UserMessage {
        return
        {
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            roles: roles,
            codeforcesHandle: codeforcesHandle
        }
    }

    public function toSessionMessage(sessionId: String): SessionMessage {
        return
            {
                userId: id,
                email: email,
                firstName: firstName,
                lastName: lastName,
                roles: roles,
                sessionId: sessionId
            };
    }

    public function toProfileMessage(): ProfileMessage {
        return
            {
                userId: id,
                email: email,
                firstName: firstName,
                lastName: lastName,
                codeforcesHandle: codeforcesHandle,
                emailActivated: emailActivated
            };
    }

    public function toRatingMessage(userId: Float, ?startDate: Date, ?finishDate: Date): RatingMessage {
        var learner = manager.select($id == userId);
        return
            {
                rating: if (startDate != null && finishDate != null) 0 else getLearnerRating(userId),
                ratingCategory: if (startDate != null && finishDate != null) [] else getRatingCategory(userId),
                learner: learner.toLearnerMessage(),
                ratingDate: if (startDate != null && finishDate != null) calculateLearnerRatingsForUsers(userId, startDate, finishDate) else [],
                solvedTasks: if (startDate != null && finishDate != null) getSolvedTasks(userId, startDate, finishDate) else 0,
                ratingByPeriod: if (startDate != null && finishDate != null) getRatingByPeriod(userId, startDate,finishDate) else 0
            };
    }

    public static function getSolvedTasks(userId: Float, startDate: Date, finishDate: Date): Float {
        var attempts = [for (a in Attempt.manager.search(($userId == userId) && ($solved == true) && ($datetime >= startDate) && ($datetime <= finishDate))) a];
        var solvedTasks = 0;
        if (attempts != null) {
            for (a in attempts) {
                if (a.task != null) {
                    solvedTasks ++;
                }
            }
        }
        return solvedTasks;
    }

    public static function getRatingByPeriod(userId: Float, startDate: Date, finishDate: Date): Float {
        var allRatingsForUser: Array<RatingDate> = calculateLearnerRatingsForUsers(userId, startDate, finishDate);
        var startRating: RatingDate = null;
        var finishRating: RatingDate = null;
        var result:Float  = 0;
        if (allRatingsForUser.length > 2) {
            startRating = allRatingsForUser.shift();
            finishRating = allRatingsForUser.pop();
            result = finishRating.rating - startRating.rating;
        }
        return result;
    }

    public static function calculateLearnerRatingsForUsers(userId: Float, startDate: Date, finishDate: Date) : Array<RatingDate> {
        var attempts = [for (a in Attempt.manager.search(($userId == userId) && ($solved == true))) a].filter(function(a) { return a.task != null; });
        ArraySort.sort(attempts, function(x:Attempt, y: Attempt) { var x2 = ((x.datetime.getFullYear() - 2010 - 1) * 12 + x.datetime.getMonth()) * 31 + x.datetime.getDate();
                                                                    var y2 = ((y.datetime.getFullYear() - 2010 - 1) * 12 + y.datetime.getMonth()) * 31 + y.datetime.getDate();
                                                                    return if (x2 > y2) 1 else -1;});

        var ratingData: Array<RatingDate> = [];
        var rating = 0;
        var prevData: Attempt = null;
        var prevRating: Float = 0;
        var i = 1;
        var length = attempts.length;
        for (a in attempts) {
            if (a.task != null) {
                if(i == 1) {
                    prevData = a;
                    prevRating = getRatingByTask(a.task.id, userId);
                    if (i == length) {
                        ratingData.push({id: prevData.id, rating: prevRating, date: prevData.datetime});
                    }
                } else {
                    if (prevData.datetime.getDate() == a.datetime.getDate() && prevData.datetime.getMonth() == a.datetime.getMonth() && prevData.datetime.getFullYear() == a.datetime.getFullYear()) {
                        if (i == length) {
                            ratingData.push({id: a.user.id, rating: prevRating + getRatingByTask(a.task.id, userId), date: a.datetime});
                        } else {
                            prevData = a;
                            prevRating += getRatingByTask(a.task.id, userId);
                        }
                    } else {
                        if (i == length) {
                            ratingData.push({id: a.user.id, rating: prevRating, date: prevData.datetime});
                            ratingData.push({id: a.user.id, rating: getRatingByTask(a.task.id, userId) + prevRating, date: a.datetime});
                        } else {
                            ratingData.push({id: a.user.id, rating: prevRating, date: prevData.datetime});
                            prevData = a;
                            prevRating += getRatingByTask(a.task.id, userId);
                        }
                    }
                }
            }
            i++;
        }
        var result: Array<RatingDate> = [];
        var prevResult: RatingDate = null;
        var startD = ((startDate.getFullYear() - 2010 - 1) * 12 + startDate.getMonth()) * 31 + startDate.getDate() + 1;
        var endDate = ((finishDate.getFullYear() - 2010 - 1) * 12 + finishDate.getMonth()) * 31 + finishDate.getDate();
        var prevDay = null;
        i = 1;
        if (ratingData.length == 0) {
            result.push({id: userId, date: startDate, rating:0});
        } else {
            for (r in ratingData) {
                var day = ((r.date.getFullYear() - 2010 - 1) * 12 + r.date.getMonth()) * 31 + r.date.getDate();
                if (i == 1) {
                    prevResult = r;
                    if (i == ratingData.length) {
                        result.push({id: userId, date: startDate, rating:0});
                        result.push({id: r.id, date: r.date, rating: r.rating});
                    }
                } else {
                    var prevDay = ((prevResult.date.getFullYear() - 2010 - 1) * 12 + prevResult.date.getMonth()) * 31 + prevResult.date.getDate();

                    if (result.length == 0 && day != startD) {
                        if (prevDay == startD) {
                            result.push(prevResult);
                            if (i == ratingData.length && day <= endDate) {
                                result.push(r);
                            }
                        } else if (prevDay > startD){
                            result.push({id: prevResult.id, date: startDate, rating: 0});
                            result.push(prevResult);
                            if (i == ratingData.length && day <= endDate) {
                                result.push(r);
                            }
                        } else if (prevDay < startD && day > startD) {
                            result.push({id: prevResult.id, date: startDate, rating: prevResult.rating});
                            if (i == ratingData.length && day <= endDate) {
                                result.push(r);
                            }
                        } else if (i == ratingData.length && day < endDate) {
                            result.push({id: r.id, date: startDate, rating: r.rating});
                        }
                        prevResult = r;
                    } else {
                        if (prevDay >= startD && prevDay <= endDate) {
                            result.push(prevResult);
                            prevResult = r;
                            if (i == ratingData.length && day >= startD && day <= endDate) {
                                result.push(r);
                            }
                        } else if (day >=startD && day <= endDate)
                        {
                            result.push(r);
                            prevResult = r;

                        } else break;
                    }
                }
                i++;
            }
        }
        if (result.length != 0) {
            var lastElement = result.pop();
            var day = ((lastElement.date.getFullYear() - 2010 - 1) * 12 + lastElement.date.getMonth()) * 31 + lastElement.date.getDate();
            if (day == endDate) {
                result.push(lastElement);
            } else if (day < endDate) {
                result.push(lastElement);
                result.push({id: lastElement.id, date: finishDate, rating: lastElement.rating});
            }
        } else {
            result.push({id:userId, date: startDate, rating:0});
            result.push({id: userId, date: finishDate, rating:0});
        }
        return result;
    }

    public static function getRatingByTask(taskId: Float, userId: Float) {
        var rating: Float = 0;
        var res: Array<RatingCategory> = [];
        var attempts = Attempt.manager.search(($userId == userId) && ($solved == true));
        var tagIds = CodeforcesTag.manager.all();
        var taskIds = [for (a in attempts) if (a.task != null) a.task.id];
        var taskTagIds = CodeforcesTaskTag.manager.search($taskId in taskIds);
        var ratingLearnerCategoryTask: Float = 0;
        var ratingByTask: Float = 0;
        for (t in tagIds) {
            for (taskTag in taskTagIds) {
                if (taskTag.tag.id == t.id && taskId == taskTag.task.id) {
                    ratingLearnerCategoryTask += Math.pow(2, taskTag.task.level-1) * (taskTag.tag.importance/tagIds.length);
                }
            }
            if (ratingLearnerCategoryTask != 0) {
                ratingLearnerCategoryTask = Math.log(ratingLearnerCategoryTask+1);
                ratingByTask += Math.round(ratingLearnerCategoryTask*100)/100;
            }
            ratingLearnerCategoryTask = 0;
        }
        return ratingByTask;
    }

   public static function calculateLearnerRating(userId: Float) {
       var rating: Float = 0;
       var ratingCategories = calculateRatingCategory(userId);
       for (r in ratingCategories) {
           if (r.rating != 0) {
               rating += r.rating;
           }
       }
       var user: User = User.manager.get(userId);
       user.rating = rating;
       user.update();
   }

    public static function getLearnerRating(userId: Float): Float {
        var user: User = User.manager.get(userId);
        return if(user.rating != null) user.rating else 0;
    }

    public static function calculateRatingCategory(userId: Float): Array<RatingCategory> {
        var rating: Float = 0;
        var res: Array<RatingCategory> = [];
        var attempts = Attempt.manager.search(($userId == userId) && ($solved == true));
        var tagIds: List<CodeforcesTag> = CodeforcesTag.manager.all();
        var taskIds = [];
        for (a in attempts) {
            if (a.task != null){
                taskIds.push(a.task.id);
            }
        }
        var taskTagIds = CodeforcesTaskTag.manager.search($taskId in taskIds);
        var ratingLearnerCategoryTask: Float = 0;
        for (t in tagIds) {
            for (taskTag in taskTagIds) {
                if (taskTag.tag.id == t.id) {
                    ratingLearnerCategoryTask += Math.pow(2, taskTag.task.level-1) * (taskTag.tag.importance/tagIds.length);
                }
            }
            if (ratingLearnerCategoryTask != 0) {
                ratingLearnerCategoryTask = Math.log(ratingLearnerCategoryTask+1);
                var rating = Math.round(ratingLearnerCategoryTask*100)/100;
                var categoryRating: CategoryRating = CategoryRating.manager.search($userId == userId && $categoryId == t.id).first();
                if (categoryRating != null) {
                    if (categoryRating.rating != rating) {
                        categoryRating.rating = rating;
                        categoryRating.update();
                    }
                } else {
                    categoryRating = new CategoryRating();
                    var user:User = User.manager.get(userId);
                    categoryRating.user = user;
                    categoryRating.tag = t;
                    categoryRating.rating = rating;
                    categoryRating.insert();
                }
                res.push({id: t.id, rating: rating});
                ratingLearnerCategoryTask = 0;
            } else {
                var categoryRating: CategoryRating = CategoryRating.manager.search($userId == userId && $categoryId == t.id).first();
                if (categoryRating == null) {
                    categoryRating = new CategoryRating();
                    var user:User = User.manager.get(userId);
                    categoryRating.user = user;
                    categoryRating.tag = t;
                    categoryRating.rating = 0;
                    categoryRating.insert();
                }
                res.push({id:t.id, rating: 0});
            }
        }
        return res;
    }

    public static function getRatingCategory(userId: Float): Array<RatingCategory> {
        var ratings: List<CategoryRating> = CategoryRating.manager.search($userId == userId);
        if(ratings.length == 0) {
            var categories = CodeforcesTag.manager.all();
            return Lambda.array(
                Lambda.map(categories, function(category: CodeforcesTag){
                    var rating: RatingCategory = {id: category.id, rating: 0};
                    return rating;
                })
            );
        } else {
            return Lambda.array(
                Lambda.map(ratings, function(categoryRating: CategoryRating){
                    var rating: RatingCategory = {id: categoryRating.tag.id, rating: categoryRating.rating}
                    return rating;
                })
            );
        }
    }
}
