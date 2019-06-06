package view.editor;

import action.EditorAction;
import view.editor.AdminAdaptiveView.AdminAdaptiveProps;
import action.AdminAction;
import utils.RemoteDataHelper;
import react.ReactComponent;
import react.ReactMacro.jsx;
import redux.react.IConnectedComponent;
import router.RouteComponentProps;

using utils.RemoteDataHelper;

class AdminAdaptiveScreen
    extends ReactComponentOfPropsAndState<RouteComponentProps, AdminAdaptiveProps>
    implements IConnectedComponent {

    public function new(props:RouteComponentProps) {
        super(props);
    }

    public override function render(): ReactElement {
        return jsx('<AdminAdaptiveView {...state} dispatch=$dispatch/>');
    }

    function mapState(state: ApplicationState, props: RouteComponentProps): AdminAdaptiveProps {
        RemoteDataHelper.ensureRemoteDataLoaded(state.editor.tags, EditorAction.LoadTags);
        return {
                tasks: if (state.admin.tasks != null) state.admin.tasks.data else [],
                tags: if (state.editor.tags != null && state.editor.tags.loaded) state.editor.tags.data else []
            }
        }
    }

