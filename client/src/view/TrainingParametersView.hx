package view;

import messages.TagMessage;
import js.Browser;
import js.html.InputElement;
import react.ReactComponent;
import react.ReactMacro.jsx;
import view.CheckboxesView;
import utils.Select;

typedef TrainingParametersProps = {
    tags: Array<TagMessage>,
    onTagsChanged: Array<Float> -> Void,
    onChanged: Int -> Int -> Int -> Void,
}

typedef TrainingParametersRefs = {
    minLevel: InputElement,
    maxLevel: InputElement,
    tasksCount: InputElement,
    tagsSelect: Dynamic
}

typedef TrainingParametersState = {
    minLevel: Int,
    maxLevel: Int,
    tasksCount: Int
}

class TrainingParametersView extends ReactComponentOfPropsAndRefs<TrainingParametersProps, TrainingParametersRefs> {

    public function new()
    {
        super();
    }

    function getTagsForSelect() {
        var tags = Lambda.array(Lambda.map(props.tags, function(t) { return { value: t.id, label: if (null != t.russianName) t.russianName else t.name }; }));
        tags.sort(function(x, y) { return if (x.label < y.label) -1 else 1; });
        return tags;
    }

    override function render() {
        var tags = getTagsForSelect();
        return
            jsx('
                <div id="params" className="uk-margin">
                <h2>Параметры тренировки</h2>
                <div className="uk-margin uk-width-1-2@s">
                    <label>Минимальный уровень: ${state.minLevel}</label>
                    <input className="uk-range uk-margin" type="range" min="1" max="5" step="1" value=${state.minLevel} onChange=$onChange ref="minLevel"/>
                </div>
                <div className="uk-margin uk-width-1-2@s">
                    <label>Максимальный уровень: ${state.maxLevel}</label>
                    <input className="uk-range uk-margin" type="range" min="1" max="5" step="1" value=${state.maxLevel} onChange=$onChange ref="maxLevel"/>
                </div>
                <div className="uk-margin uk-width-1-2@s">
                    <label>Количество задач: ${state.tasksCount}</label>
                    <input className="uk-range uk-margin" type="range" min="1" max="20" step="1" value=${state.tasksCount} onChange=$onChange ref="tasksCount"/>
                </div>
                <div className="uk-margin">
                    <h3>Категории задач</h3>
                    <div className="uk-margin">
                        <button className="uk-button uk-button-default uk-button-small  uk-margin-small-right" onClick=$selectAllTags>Выбрать все</button>
                        <button className="uk-button uk-button-default uk-button-small" onClick=$deselectAllTags>Исключить все</button>
                    </div>
                    <Select
                        isMulti=${true}
                        isLoading=${tags == null || tags.length <= 0}
                        options=$tags
                        onChange=$onSelectedTagsChanged
                        placeholder="Выберите категории..."
                        ref="tagsSelect"/>
                </div>
                </div>
            ');
    }

    override function componentWillMount() {
        setState({
            minLevel: 1,
            maxLevel: 5,
            tasksCount: 5
        }, onInputsChanged);
    }

    function onChange(e) {
        var minLevel = Math.min(Std.parseInt(refs.minLevel.value), state.maxLevel);
        var maxLevel = Math.max(Std.parseInt(refs.maxLevel.value), state.minLevel);
        setState({
            minLevel: minLevel,
            maxLevel: maxLevel,
            tasksCount: Std.parseInt(refs.tasksCount.value)
        }, onInputsChanged);
    }

    function onInputsChanged() {
        props.onChanged(state.minLevel, state.maxLevel, state.tasksCount);
    }

    function onSelectedTagsChanged(tags) {

        props.onTagsChanged(if (tags != null) Lambda.array(Lambda.map(tags, function(t) { return Std.parseFloat(t.value); })) else []);
        trace(tags);
    }

    function selectAllTags() {
        trace(refs.tagsSelect);
        refs.tagsSelect.setState(
            react.ReactUtil.copy(refs.tagsSelect.state, { value: getTagsForSelect() }),
            function() { onSelectedTagsChanged(refs.tagsSelect.state.value); });
    }

    function deselectAllTags() {
        refs.tagsSelect.setState(
            react.ReactUtil.copy(refs.tagsSelect.state, { value: null }),
            function() { onSelectedTagsChanged(refs.tagsSelect.state.value); });
    }}
