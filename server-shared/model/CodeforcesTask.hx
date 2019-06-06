package model;

import utils.StringUtils;
import messages.TaskMessage;
import sys.db.Types;
import sys.db.Manager;

@:table("CodeforcesTasks")
class CodeforcesTask extends sys.db.Object {
    public var id: SBigId;
    public var name: SString<512>;
    public var level: SInt;
    public var solvedCount: Int;
    public var contestId: Int;
    public var contestIndex: SString<128>;
    public var type: SString<128>;
    public var active: Bool;
    public var rating: SInt;

    public function new() {
        super();
    }

    public static var manager = new Manager<CodeforcesTask>(CodeforcesTask);

    public static function getOrCreateByCodeforcesProblem(p: codeforces.Problem): CodeforcesTask {
        var task: CodeforcesTask = manager.select({ contestId: p.contestId, contestIndex: p.index });
        var isNew = false;

        if (null == task) {
            task = new CodeforcesTask();
            task.contestId = p.contestId;
            task.contestIndex = p.index;
            task.active = true;
            task.name = p.name;
            task.level = 0;
            task.solvedCount = 0;
            task.rating = p.rating;
            task.insert();
        } else if(task.rating != p.rating){
            task.rating = p.rating;
            task.update();
        }

        task.name = p.name;
        return task;
    }

    public static function doTasksExistForContest(contestId: Int): Bool {
        return manager.count($contestId == contestId && $active == true) > 0;
    }

    public function isGymTask(): Bool {
        return contestId >= 100000;
    }

    public function isSolved(user: User): Bool {
        return if (user != null) Attempt.manager.count($taskId == id && $solved == true && $userId == user.id) > 0 else false;
    }

    public function toMessage(?user: User): TaskMessage {
        return {
            id: id,
            name: StringUtils.unescapeHtmlSpecialCharacters(name),
            level: level,
            tagIds: Lambda.array(Lambda.map(CodeforcesTaskTag.manager.search($taskId == id), function(t) { return t.tag.id; })),
            isGymTask: isGymTask(),
            codeforcesContestId: contestId,
            codeforcesIndex: contestIndex,
            isSolved: isSolved(user),
            rating: getRatingByTaskTest(this.id),
            ratingByTag: getRatingTag(this.id)
        };
    }

    public function getRatingByTaskTest(taskId: Float) {
        var rating: Float = 0;
        var tagIds = CodeforcesTag.manager.all();
        var taskTags = CodeforcesTaskTag.manager.search($taskId == taskId);
        var ratingLearnerCategoryTask: Float = 0;
        var ratingByTask: Float = 0;
        for (t in taskTags) {
            ratingLearnerCategoryTask = Math.pow(2, t.task.level-1) * (t.tag.importance/tagIds.length);
            if (ratingLearnerCategoryTask != 0) {
                ratingLearnerCategoryTask = Math.log(ratingLearnerCategoryTask+1);
                ratingByTask += Math.round(ratingLearnerCategoryTask*100)/100;
            }
        }
        return ratingByTask;
    }

    public function getRatingTag(taskId: Float){
        var ratingBytag: Array<RatingByTag> = [];
        var taskTag = CodeforcesTaskTag.manager.search($taskId == taskId);
        var allTags = CodeforcesTag.manager.all();
        var rating: Float = 0;
        for (t in taskTag) {
            if (t.task != null && t.tag != null) {
                rating = Math.pow(2, t.task.level-1)*(t.tag.importance/allTags.length);
                ratingBytag.push({tagId: t.tag.id,name: if (t.tag.russianName != null) t.tag.russianName else t.tag.name, rating: Math.round(rating*100)/100});
            }
        }
        return ratingBytag;
    }
}
