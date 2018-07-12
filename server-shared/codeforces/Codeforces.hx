package codeforces;

import haxe.Json;
import haxe.Http;
import htmlparser.HtmlDocument;

class Codeforces {

    static var baseUrl = "http://codeforces.com/";
    static var baseApiUrl = baseUrl + "api/";
    static var postfix = "locale=ru";

    private static function request(url: String): Dynamic {
        var response: Response = Json.parse(Http.requestUrl(url + postfix ));
        if (response.status == "OK") {
            return response.result;
        } else {
            throw "HTTP request failed";
        }
    }

    public static function getAllProblemsResponse(): ProblemsResponse {
        return request(baseApiUrl + "problemset.problems?");
    }

    public static function getGymContests(): Array<Contest> {
        return request(baseApiUrl + "contest.list?gym=true&");
    }

    public static function getAllContests(): Array<Contest> {
        var res:Array<Contest> = request(baseApiUrl + "contest.list?");
        return res.concat(getGymContests());
    }

    public static function getGymProblemsByContest(contest: Contest): ProblemsResponse {
        var problems: Array<Problem> = [];
        var problemStatistics: Array<ProblemStatistics> = [];

        var eregTr: EReg = new EReg("<tr[^>]*>","igm");
        var eregComment: EReg = new EReg("<!--[^>]*-->","igm");
        var eregSolvedCount: EReg = new EReg("x([0123456789]+)","igm");

        var data = eregTr.replace(
                                Http.requestUrl(baseUrl + "gym/" + Std.string(contest.id) +  "/?" + postfix),
                                "</tr><tr>");
        var contestHtml: HtmlDocument =  new HtmlDocument(data, true);
        var rows = contestHtml.find("table.problems>tr");

        for (i in 1...rows.length) {
            var p: Problem =
                {
                    contestId: contest.id,
                    index: StringTools.trim(rows[i].find(">td.id>a")[0].innerHTML),
                    name: StringTools.trim(eregComment.replace(rows[i].find(">td>div>div>a")[0].innerHTML, "")),
                    type: "PROGRAMMING",
                    tags: []
                }
            problems.push(p);


            var links = rows[i].find(">td>a");
            var solvedCount = 0;
            if (links.length > 1) {
                eregSolvedCount.match(links[1].innerHTML);
                solvedCount = Std.parseInt(StringTools.trim(eregSolvedCount.matched(1)));
            }
            problemStatistics.push({
                contestId: contest.id,
                index: p.index,
                solvedCount: solvedCount
            });
        }

        return { problems: problems, problemStatistics: problemStatistics};
    }
}
