package ;

import Array;
import haxe.ds.StringMap;
import utils.IterableUtils;
import messages.RatingMessage.RatingCategory;
import haxe.ds.ArraySort;
import haxe.ds.StringMap;
import model.CodeforcesTag;
import model.CodeforcesTaskTag;
import model.CodeforcesTask;


typedef CategoryLevel = {
    category: CodeforcesTag,
    level: Int,
    countSolved: Int
}

typedef TaskRating = {
    task: CodeforcesTask,
    rating: Float
}

class AdaptiveLearning {
    public function new() {
    }

    public static function executeFilter(tasks: Array<CodeforcesTask>, taskTags: StringMap<Array<CodeforcesTaskTag>>, categoryLevels: StringMap<CategoryLevel>): Array<CodeforcesTask> {
        var result: Array<CodeforcesTask> = [];
        var tagLevel: CategoryLevel = null;
        var taskTag: Array<CodeforcesTaskTag> = null;
        var i = 0;
        for (t in tasks) {
            taskTag = taskTags.get(Std.string(t.id));
            if (taskTag != null) {
                for (tag in taskTag) {
                    if (tag.tag != null) {
                        tagLevel = categoryLevels.get(Std.string(tag.tag.id));
                        if (canUserSolveTagAndLevel(t.level, tagLevel)) {
                            result.push(t);
                        }
                    }
                }
            }
        }
        return result;
    }

    public static function canUserSolveTagAndLevel(level: Int, categoryLevel: CategoryLevel): Bool {
        var i = level - categoryLevel.level;
        var state: Bool = false;
        if (i == 1) {
            if ((categoryLevel.level==1 && categoryLevel.countSolved>=3) ||
            (categoryLevel.level==2 && categoryLevel.countSolved>=10) ||
            (categoryLevel.level==3 && categoryLevel.countSolved>=20) ||
            (categoryLevel.level==4 && categoryLevel.countSolved>=50)){
                state = true;
            } else {
                state = false;
            }
        } else if (i == 0) {
            state = true;
        }
        return state;
    }

    public static function calcLearnerLevel(?solvedTaskTag: StringMap<Array<CodeforcesTaskTag>>, tags: Array<CodeforcesTag>): StringMap<CategoryLevel> {
        var resultArray: Array<CategoryLevel> = [];
        var res = new StringMap<CategoryLevel>();
        var solvedTagTasks: Array<CodeforcesTaskTag> = null;
        for (t in tags) {
            if (solvedTaskTag != null) {
                solvedTagTasks = solvedTaskTag.get(Std.string(t.id));
                if (solvedTagTasks != null) {
                    for (s in solvedTagTasks) {
                        if (s.task != null) {
                            if (res.exists(Std.string(t.id))) {
                                res.set(Std.string(t.id),{category: t, level: s.task.level, countSolved: res.get(Std.string(t.id)).countSolved + 1});
                            } else {
                                res.set(Std.string(t.id),{category: t, level: s.task.level, countSolved: 1});
                            }
                        }
                    }
                }
            }
        }

        for (t in tags) {
            if (res.exists(Std.string(t.id))) {
                var calcLevel: CategoryLevel = res.get(Std.string(t.id));
                switch(calcLevel.level) {
                    case 2: if (calcLevel.countSolved >=50) {
                        resultArray.push({category: t, level: 3, countSolved: 0});
                            } else {
                        resultArray.push({category: t, level: 2, countSolved: calcLevel.countSolved});
                            }
                    case 3: if (calcLevel.countSolved >=100) {
                        resultArray.push({category: t, level: 4, countSolved: 0});
                    } else {
                        resultArray.push({category: t, level: 3, countSolved: calcLevel.countSolved});
                    }
                    case 4: if (calcLevel.countSolved >=250) {
                        resultArray.push({category: t, level: 5, countSolved: 0});
                    } else {
                        resultArray.push({category: t, level: 4, countSolved: calcLevel.countSolved});
                    }
                    case 5: resultArray.push({category: t, level: 5, countSolved: calcLevel.countSolved});
                    default : if (calcLevel.countSolved >=15 && calcLevel.level == 1) {
                        resultArray.push({category: t, level: 2, countSolved: 0});
                    } else {
                        resultArray.push({category: t, level: 1, countSolved: calcLevel.countSolved});
                    }
                }
            } else {
                resultArray.push({category:t, level: 1, countSolved: 0});
            }
        }
        var result = IterableUtils.createStringMap(resultArray, function(r){return Std.string(r.category.id);});
        return result;
    }

    public static function canUserLevelUpTag(tags: Array<CodeforcesTag>, learnerLevel: StringMap<CategoryLevel>){
        var calcLevel: CategoryLevel = null;
        for (t in tags) {
            calcLevel = learnerLevel.get(Std.string(t.id));
            switch(calcLevel.level) {
                case 2: if (calcLevel.countSolved >=50) {
                    learnerLevel.set(Std.string(t.id),{category: t, level: 3, countSolved: 0});
                }
                case 3: if (calcLevel.countSolved >=100) {
                    learnerLevel.set(Std.string(t.id),{category: t, level: 4, countSolved: 0});
                }
                case 4: if (calcLevel.countSolved >=250) {
                    learnerLevel.set(Std.string(t.id),{category: t, level: 5, countSolved: 0});
                }
                case 5: learnerLevel.set(Std.string(t.id),{category: t, level: 5, countSolved: calcLevel.countSolved});
                default : if (calcLevel.countSolved >=15 && calcLevel.level == 1) {
                    learnerLevel.set(Std.string(t.id),{category: t, level: 2, countSolved: 0});
                }
            }
        }
        return learnerLevel;
    }

    public static function selectTasks(tasks: Array<CodeforcesTask>, possibleTaskTag: StringMap<Array<CodeforcesTaskTag>>, currentRating: StringMap<RatingCategory>, tasksCount: Float): StringMap<CodeforcesTask> {
        var i = 0;
        var task: CodeforcesTask = null;
        var finishedTasks = new StringMap<CodeforcesTask>();
        while (i < tasksCount) {
            task = nextTask(tasks, currentRating, possibleTaskTag);
            currentRating = emulateSolution(currentRating, task, possibleTaskTag);
            if (!finishedTasks.exists(Std.string(task.id))) {
                i++;
            }
            finishedTasks.set(Std.string(task.id), task);
            tasks.remove(task);
        }
        return finishedTasks;
    }

    public static function nextTask(tasks: Array<CodeforcesTask>, currentRating: StringMap<RatingCategory>, possibleTaskTag: StringMap<Array<CodeforcesTaskTag>>): CodeforcesTask {
        var ratingTasks: Array<TaskRating> = [];
        var rating: Float = 0;
        var taskTag: Array<CodeforcesTaskTag> = [];
        var realRating: RatingCategory = null;
        for (t in tasks) {
            taskTag = possibleTaskTag.get(Std.string(t.id));
            for (tag in taskTag) {
                if (tag.tag != null){
                    realRating = currentRating.get(Std.string(tag.tag.id));
                    rating += Math.log(Math.pow(2,t.level-1)*(tag.tag.importance/43) + realRating.rating + 1);
                }
            }
            ratingTasks.push({task:t, rating: Math.round(rating*100)/100});
            rating = 0;
        }
        ArraySort.sort(ratingTasks, function(x: TaskRating, y: TaskRating){return if (x.rating < y.rating) 1 else -1;});
        var result: TaskRating = ratingTasks[0];
        return result.task;
    }

    public static function emulateSolution(currentRating: StringMap<RatingCategory>, task: CodeforcesTask, taskTag: StringMap<Array<CodeforcesTaskTag>>): StringMap<RatingCategory> {
        var result: Array<RatingCategory> = [];
        var taskTags: Array<CodeforcesTaskTag> = taskTag.get(Std.string(task.id));
        var rating: Float = 0;
        for (t in taskTags) {
            var curRating: RatingCategory = currentRating.get(Std.string(t.tag.id));
            rating = Math.pow(2,task.level - 1)*(t.tag.importance/43) + curRating.rating;
            currentRating.set(Std.string(curRating.id), {id: curRating.id, rating: rating, name: null});
        }
        return currentRating;
    }

    public static function selectTasksForChart(tasks: Array<CodeforcesTask>, currentRating: StringMap<RatingCategory>, tasksCount: Int, tags: Array<CodeforcesTag>, taskTagsMap: StringMap<Array<CodeforcesTaskTag>>) {
        var learnerLevel = calcLearnerLevel(tags);
        var filteredTasks = executeFilter(tasks, taskTagsMap, learnerLevel);
        var finishedTasks = [];
        var task: CodeforcesTask = null;
        var i = 0;
        var solvedTaskTag = new StringMap<Array<CodeforcesTaskTag>>();
        var taskTagMap: Array<CodeforcesTaskTag> = [];
        while (i < tasksCount) {
            task = nextTask(filteredTasks, currentRating, taskTagsMap);
            currentRating = emulateSolution(currentRating, task, taskTagsMap);
            finishedTasks.push(task);
            var solvedTags: Array<CodeforcesTaskTag> = taskTagsMap.get(Std.string(task.id));
            tasks.remove(task);
            learnerLevel = calcLearnerLevelChart(learnerLevel, solvedTags, tags);
            filteredTasks = executeFilter(tasks, taskTagsMap, learnerLevel);
            trace(i);
            i++;
        }
        return finishedTasks;
    }

    public static function calcLearnerLevelChart(currentLevel: StringMap<CategoryLevel>, solvedTaskTag: Array<CodeforcesTaskTag>, tags: Array<CodeforcesTag>): StringMap<CategoryLevel> {
        for (s in solvedTaskTag) {
            currentLevel.set(Std.string(s.tag.id),{category: s.tag, level: currentLevel.get(Std.string(s.tag.id)).level, countSolved: currentLevel.get(Std.string(s.tag.id)).countSolved + 1});
        }
        currentLevel = canUserLevelUpTag(tags, currentLevel);
        return currentLevel;
    }
}
