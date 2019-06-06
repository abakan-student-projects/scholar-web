package view.editor;

import haxe.ds.StringMap;
import Lambda;
import codeforces.Codeforces;
import messages.TagMessage;
import action.AdminAction;
import messages.TaskMessage;
import js.html.InputElement;
import react.ReactComponent;
import react.ReactMacro.jsx;
import redux.react.IConnectedComponent;
import react.ReactUtil.copy;
import router.Link;
import utils.Bar;

typedef AdminAdaptiveProps = {
    tasks: Array<TaskMessage>,
    tags: Array<TagMessage>
}

typedef AdminAdaptiveRefs = {
    tasksCount: InputElement
}

typedef AdminAdaptiveState = {
    bar: Dynamic,
    i: Float,
    prevData: Array<ChartAxis>,
    timer1: Bool,
    color: String
}

typedef ChartProps = {
    labels: Array<String>,
    datasets: Array<Dynamic>
}

typedef ChartAxis = {
    x: String,
    y: Float
}

class AdminAdaptiveView extends ReactComponentOfProps<AdminAdaptiveProps> implements IConnectedComponent {

    public function new()
    {
        super();
        state = {bar: data }
    }

    var data: ChartProps;
    var j: Float;
    var colors: Array<String>;
    var timer: haxe.Timer;

    function getColors() {
        var i = 0;
        var colors = [];
        while (i < 43) {
            colors.push('rgba(255,'+Math.floor(Math.random()*255)+',132,0.4)');
            i++;
        }
        return colors;
    }

    override function render() {
        colors = getColors();
        data = {
            labels: getTags(),
            datasets: [
                {
                    label:'Категории',
                    fill: false,
                    backgroundColor: 'rgba(255,99,132,1)',
                    borderColor: 'rgba(255,99,132,1)',
                    borderCapStyle: 'butt',
                    borderDashOffset: 0.0,
                    borderJoinStyle: 'miter',
                    hoverBackgroundColor: 'rgba(255,99,132,0.4)',
                    hoverBorderColor: 'rgba(255,99,132,1)',
                    data: [],
                }
            ]
        };
        if (props.tasks != null) {
            var tasks = [];
            var color1 = {
                background: state.color
            };
            var white = {
                background: 'white'
            }
            var i = 1;
            for (t in props.tasks) {
                var problemUrl =
                    if (t.isGymTask)
                        Codeforces.getGymProblemUrl(t.codeforcesContestId, t.codeforcesIndex)
                    else
                        Codeforces.getProblemUrl(t.codeforcesContestId, t.codeforcesIndex);

                tasks.push(jsx('<tr style={${if (state.i == i++) color1 else white}}>
                                    <td>${i-1}</td>
                                    <td><Link to=$problemUrl target="_blank" className="uk-link-text">${t.name}</Link></td>
                                    <td>${t.level}</td>
                                    <td>${renderTags(t,i-1)}</td>
                                    <td>${t.rating}</td>
                                    <td><button className="uk-button uk-button-default" onClick=${renderChart.bind(i-1)}>График</button></td>
                                </tr>'));
            }
            return jsx('
                    <div id="adaptiveDemo">
                        <input className="uk-input uk-width-small uk-margin-right" type="text" placeholder="Число" ref="tasksCount"/>
                        <button className="uk-button uk-button-default" onClick=$testAdaptive>Запуск</button>
                         <button className="uk-button uk-button-default" onClick=$stopChart>Стоп</button>
                         <button className="uk-button uk-button-default" onClick=$continueChart>Продолжить</button>
                        <Bar data=${state.bar} />
                        <table className="uk-table uk-table-divider uk-table-middle uk-table-hover">
                            <thead>
                                <tr>
                                    <th>№</th>
                                    <th>Название</th>
                                    <th>Уровень</th>
                                    <th>Категории</th>
                                    <th>Рейтинг</th>
                                    <th>Изменение графика</th>
                                </tr>
                            </thead>
                            <tbody>
                            $tasks
                            </tbody>
                        </table>
                    </div>
                ');
        } else {
            return jsx('
                    <div id="adaptiveDemo">
                        <input className="uk-input uk-width-small uk-margin-right" type="text" placeholder="Число" ref="tasksCount"/>
                        <button className="uk-button uk-button-default" onClick=$testAdaptive>Запуск</button>
                        <button className="uk-button uk-button-default">Стоп</button>
                         <button className="uk-button uk-button-default">Продолжить</button>
                        <Bar data=$data />
                        <table className="uk-table uk-table-divider uk-table-middle uk-table-hover">
                            <thead>
                                <tr>
                                    <th>№</th>
                                    <th>Название</th>
                                    <th>Уровень</th>
                                    <th>Категории</th>
                                    <th>Рейтинг</th>
                                    <th>Изменение графика</th>
                                </tr>
                            </thead>
                            <tbody>
                            </tbody>
                        </table>
                    </div>
                ');
        }

    }

    function testAdaptive() {
        if (state.timer1 == false) {
            componentDidMount();
        }
        dispatch(AdminAction.TestAdaptiveDemo(refs.tasksCount.value));
        componentWillMount();
    }

    function stopChart() {
        setState({timer1:false});
        timer.stop();
    }

    function continueChart() {
        componentDidMount();
    }

    function renderChart(numberTask: Float) {
        componentWillMount();
        var oldDataSet = data.datasets[0];
        var newData = [];
        var data2 = new StringMap<Float>();
        var i = 0;
        var tasks = new StringMap<Float>();
        if (props.tasks != null) {
            for (t in props.tasks) {
                i++;
                if (i <= numberTask) {
                    for (r in t.ratingByTag) {
                        if (tasks.exists(r.name)) {
                            tasks.set(r.name,tasks.get(r.name) + r.rating);
                        } else {
                            tasks.set(r.name, r.rating);
                        }
                    }
                }
            }
        }
        for (label in data.labels) {
            if (tasks.exists(label)) {
                newData.push({x: label, y: Math.round(tasks.get(label)*100)/100});
            } else {
                newData.push({x: label, y:0});
            }
        }
        var newDataSet = {
            label:'Категории',
            fill:false,
            backgroundColor: colors,
            borderColor: 'rgba(255,99,132,1)',
            borderCapStyle: 'butt',
            borderDashOffset: 0.0,
            borderJoinStyle: 'miter',
            borderWidth: 1,
            hoverBackgroundColor: 'rgba(255,99,132,0.4)',
            hoverBorderColor: 'rgba(255,99,132,1)',
            data: newData
        };
        var newState = {
            labels: data.labels,
            datasets: [newDataSet]
        };
        setState(copy(state,{bar: newState, i: numberTask, prevData: newData, timer1: false, color:'Bisque'}));
        timer.stop();
    }

    function renderTags(task: TaskMessage, numberTask: Float) {
        var tags = [];
        var finishData = new StringMap<Float>();
        var i = 0;
        if (props.tasks != null) {
            for (t in props.tasks) {
                i++;
                if (i <= numberTask) {
                    for (r in t.ratingByTag) {
                        if (finishData.exists(Std.string(r.tagId))) {
                            finishData.set(Std.string(r.tagId),(r.rating + finishData.get(Std.string(r.tagId))) - finishData.get(Std.string(r.tagId)));
                        } else {
                            finishData.set(Std.string(r.tagId), r.rating);
                        }
                    }
                }
            }
        }
        if (task != null && props.tags != null) {
            for (tag in props.tags) {
                for (t in task.tagIds) {
                    if (t == tag.id && finishData.exists(Std.string(tag.id))) {
                        tags.push(jsx('<span key=${tag.id} className="uk-margin-small-bottom uk-margin-small-right">${if (tag.russianName != null) tag.russianName else tag.name} <div>${Math.round(finishData.get(Std.string(tag.id))*100)/100}</div></span>'));
                    }
                }
            }
        }
        return tags;
    }

    function getTags() {
        var tags = [];
        if (props.tags != null)
            for (t in props.tags)
                if (t.russianName != null)
                    tags.push(t.russianName);
                else if (t.name != null)
                    tags.push(t.name);
                else
                    tags.push("");
        return tags;
    }

    override function componentWillMount() {
        setState(copy(state,{bar: data, i: 0, prevData: [] }));
    }

    override function componentDidMount() {
        timer = new haxe.Timer(1000);
        timer.run = function() {
            var oldDataSet = data.datasets[0];
            var newData = [];
            var j = state.i;
            var data2 = new StringMap<Float>();
            var i = 0;
            var prevData: Array<ChartAxis> = state.prevData;
            if (props.tasks != null) {
                j++;
                for (t in props.tasks) {
                    i++;
                     if (i == j) {
                        for (label in data.labels) {
                            var data = new StringMap<Float>();
                            for (r in t.ratingByTag){
                                data.set(r.name, r.rating);
                            }
                            for (p in prevData) {
                                data2.set(p.x,p.y);
                            }
                            if (data.exists(label) && data2.exists(label)) {
                                newData.push({x: label, y: data.get(label) + data2.get(label)});
                            } else if (data.exists(label) && !(data2.exists(label))){
                                newData.push({x: label, y: data.get(label)});
                            } else if (data2.exists(label) && !(data.exists(label))) {
                                newData.push({x: label, y: data2.get(label)});
                            } else {
                                newData.push({x: label, y: 0});
                            }
                        }
                    } else if (j > refs.tasksCount.value) {
                         newData = state.prevData;
                     }
                }

            }
            var newDataSet = {
                label:'Категории',
                fill:false,
                backgroundColor: colors,
                borderColor: 'rgba(255,99,132,1)',
                borderCapStyle: 'butt',
                borderDashOffset: 0.0,
                borderJoinStyle: 'miter',
                borderWidth: 1,
                hoverBackgroundColor: 'rgba(255,99,132,0.4)',
                hoverBorderColor: 'rgba(255,99,132,1)',
                data: newData
            };
            var newState = {
                labels: data.labels,
                datasets: [newDataSet]
            };
            setState(copy(state,{bar: newState, i: j, prevData: newData, timer1: true, color:'Bisque'}));
        };
    }
}
