package service;

import Lambda;
import utils.IterableUtils;
import Lambda;
import Array;
import messages.UserMessage;
import haxe.EnumTools;
import model.User;
import haxe.EnumTools;
import messages.LinkTypes;
import haxe.EnumTools.EnumValueTools;
import model.LinksForTags;
import messages.LinksForTagsMessage;
import model.CodeforcesTaskTag;
import model.CodeforcesTag;
import messages.TagMessage;
import model.CodeforcesTask;
import messages.ResponseMessage;
import model.Assignment;
import model.Attempt;
import model.Group;
import model.GroupLearner;
import model.ModelUtils;
import model.Role;
import model.Training;

using Lambda;

class EditorService {

    public function new() {}

    private function authorize(next: Void -> ResponseMessage): ResponseMessage {
        return ServiceHelper.authorize(Role.Editor, next);
    }

    public function getTags(): ResponseMessage {
        return authorize(function() {
            return ServiceHelper.successResponse(Lambda.array(CodeforcesTask.manager.all()));
        });
    }

    public function insertTag(tagMessage: TagMessage): ResponseMessage {
        return authorize(function() {
            if (CodeforcesTag.manager.count($name == tagMessage.name) > 0) {
                return ServiceHelper.failResponse("Тег " + tagMessage.name + " уже существует.");
            }
            var tag = new CodeforcesTag();
            tag.name = tagMessage.name;
            tag.russianName = tagMessage.russianName;
            tag.insert();

            return ServiceHelper.successResponse(tag.toMessage());
        });
    }

    public function updateTag(tagMessage: TagMessage): ResponseMessage {
        return authorize(function() {
            var tag: CodeforcesTag = CodeforcesTag.manager.get(tagMessage.id);
            if (tag != null) {
                tag.name = tagMessage.name;
                tag.russianName = tagMessage.russianName;
                tag.update();
                return ServiceHelper.successResponse(tag.toMessage());
            } else {
                return ServiceHelper.failResponse("Тег id=" + tagMessage.id + " не существует.");
            }
        });
    }

    public function insertLink(linkMessage: LinksForTagsMessage): ResponseMessage {
        return authorize(function() {
            var tag: CodeforcesTag = CodeforcesTag.manager.select($id==linkMessage.tag);
            var link = new LinksForTags();
            link.URL = linkMessage.url;
            link.optional = linkMessage.optional;
            link.type = EnumTools.createByIndex(LinkTypes, linkMessage.type);
            link.tag = tag;
            link.insert();
            return ServiceHelper.successResponse(link.toMessage());
        });
    }

    public function updateLink(linkMessage: LinksForTagsMessage): ResponseMessage {
        return authorize(function() {
            var link: LinksForTags = LinksForTags.manager.select($id==linkMessage.id);
            if (link != null) {
                link.type = EnumTools.createByIndex(LinkTypes, linkMessage.type);
                link.optional = linkMessage.optional;
                link.URL = linkMessage.url;
                link.update();
                return ServiceHelper.successResponse(link.toMessage());
            } else {
                return ServiceHelper.failResponse("Ссылка id = " + linkMessage.id + "не существует." );
            }
        });
    }

    public function deleteLink(linkMessage: LinksForTagsMessage): ResponseMessage {
        return authorize(function() {
            LinksForTags.manager.delete($id==linkMessage.id);
            return ServiceHelper.successResponse(linkMessage.id);
        });
    }

    public function getTasks(filter: String, offset: Int, limit: Int): ResponseMessage {
        return authorize(function() {
            var tasksCount = CodeforcesTask.manager.count($name.like("%"+filter+"%"));
            var tasks = CodeforcesTask.manager.search($name.like("%"+filter+"%"), {orderBy: name, limit: [offset, limit]});
            var messages =
                tasks
                    .map(function(t) { return t.toMessage(); })
                    .array();
            return ServiceHelper.successResponse({
                data: messages,
                offset: offset,
                totalLength: tasksCount
            });
        });
    }

    public function getAllUsers(): ResponseMessage {
        return ServiceHelper.successResponse(
            Lambda.array(
                Lambda.map(
                    User.manager.all(),
                    function(u) { return u.toUserMessage(); })));
    }

    public function updateRole(userMessage: UserMessage): ResponseMessage {
        return authorize(function() {
            var user: User = User.manager.select($id==userMessage.id);
            if (user != null){
                user.roles = userMessage.roles;
                user.update();
                return ServiceHelper.successResponse(user.toUserMessage());
            } else {
                return ServiceHelper.failResponse("Такого пользователя не существует");
            }
        });
    }

    public function updateTaskTags(taskId: Float, tagIds: Array<Float>): ResponseMessage {
        return authorize(function() {
            var task: CodeforcesTask = CodeforcesTask.manager.get(taskId);
            if (task != null) {
                CodeforcesTaskTag.manager.delete($taskId == task.id);
                for (tagId in tagIds) {
                    var tag = CodeforcesTag.manager.get(tagId);
                    if (null != tag) {
                        var relation = new CodeforcesTaskTag();
                        relation.task = task;
                        relation.tag = tag;
                        relation.insert();
                    }
                }
                return ServiceHelper.successResponse(task.toMessage());
            } else {
                return ServiceHelper.failResponse("Задача id=" + taskId + " не существует.");
            }
        });
    }

    public function testAdaptiveDemo(tasksCount: Int): ResponseMessage {
        return authorize(function() {
            var currentRating = TeacherService.getRatingCategory(0);
            var curRating = IterableUtils.createStringMap(currentRating, function(c){return Std.string(c.id);});
            var tags = [for (t in CodeforcesTag.manager.all()) t];
            var tasks = [for (t in CodeforcesTask.manager.all()) t];
            var taskTags = [for (t in CodeforcesTaskTag.manager.all()) t];
            var tasksTagsMap = IterableUtils.createStringMapOfArrays(taskTags, function(t){return if (t.task != null) Std.string(t.task.id) else null;});
            var tasks = AdaptiveLearning.selectTasksForChart(tasks, curRating, tasksCount, tags, tasksTagsMap);
            return ServiceHelper.successResponse(
                Lambda.array(Lambda.map(
                    tasks, function(t) {return t.toMessage();})));
        });
    }
}
