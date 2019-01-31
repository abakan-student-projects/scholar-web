package ;

import messages.MessagesHelper;
import model.Training;
import messages.ResponseStatus;
import haxe.EnumTools.EnumValueTools;
import model.Job;
import jobs.JobMessage;
import model.Attempt;
import model.GroupLearner;
import haxe.Unserializer;
import jobs.ScholaeJob;
import org.amqp.fast.FastImport.Delivery;
import org.amqp.fast.FastImport.Channel;
import org.amqp.ConnectionParameters;
import org.amqp.fast.neko.AmqpConnection;

class Worker {

    private var mq: AmqpConnection;
    private var channel: Channel;

    public function new() {
        trace("Started");
        mq = new AmqpConnection(getConnectionParams());
        //trace("Connection is up " + mq);
        channel = mq.channel();
        //trace("Channel:" + channel);
        //channel.bind("jobs_common", "jobs", null);
        channel.consume("jobs_common", onConsume, false);
        trace("On consume is setup");
    }

    public static function getConnectionParams(): ConnectionParameters {
        var params:ConnectionParameters = new ConnectionParameters();
        params.username = "scholae";
        params.password = "scholae";
        params.vhostpath = "scholae";
        params.serverhost = "127.0.0.1";
        return params;
    }

    public function run() {
        trace("The loop is running...");
        while(true) {
            mq.deliver(false);
            Sys.sleep(0.0001);
        }
    }

    public function onConsume(delivery: Delivery) {

        var cnx = sys.db.Mysql.connect({
            host : "127.0.0.1",
            port : null,
            user : "scholae",
            pass : "scholae",
            database : "scholae",
            socket : null,
        });
        cnx.request("SET NAMES 'utf8';");

        sys.db.Manager.cnx = cnx;
        sys.db.Manager.initialize();

        var c = delivery.body.readAll().toString();

        trace(c);

        var msg: JobMessage = Unserializer.run(c);

        if (msg != null) {
            trace(EnumValueTools.getName(msg.job));
            switch(msg.job) {
                case RefreshResultsForGroup(groupId):
                    for (gl in GroupLearner.manager.search($groupId == groupId)) {
                        Sys.sleep(0.4);
                        Attempt.updateAttemptsForUser(gl.learner);
                    }
                    var job: Job = Job.manager.get(msg.id);
                    if (null != job) {
                        job.response = MessagesHelper.successResponse(
                            Lambda.array(
                                Lambda.map(
                                    Training.getTrainingsByGroup(groupId),
                                    function(t) { return t.toMessage(); })));
                        job.modificationDateTime = Date.now();
                        job.update();
                    }

                case RefreshResultsForUser(user):
                    Attempt.updateAttemptsForUser(user);
                    var job: Job = Job.manager.get(msg.id);
                    if (null != job) {
                        job.response = MessagesHelper.successResponse(
                            Lambda.array(
                                Lambda.map(
                                    Training.manager.search($userId == user.id && $deleted != true),
                                    function(t) { return t.toMessage(true); })));
                        job.modificationDateTime = Date.now();
                        job.update();
                    };
            }
        }

        sys.db.Manager.cleanup();
        cnx.close();

        Sys.stdout().flush();
        Sys.stderr().flush();

        channel.ack(delivery);
    }
}
