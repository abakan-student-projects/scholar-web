package view.teacher;

import action.EditorAction;
import action.LearnerAction;
import action.TeacherAction;
import utils.RemoteDataHelper;
import view.learner.LearnerRatingView;
import react.ReactComponent;
import react.ReactMacro.jsx;
import redux.react.IConnectedComponent;
import router.RouteComponentProps;
import router.RouterLocation.RouterAction;

using utils.RemoteDataHelper;

class UserRatingScreen
    extends ReactComponentOfPropsAndState<RouteComponentProps, LearnerRatingProps>
    implements IConnectedComponent {

    public function new(props:RouteComponentProps) {
        super(props);
    }

    public override function render(): ReactElement {
        return jsx('<LearnerRatingView {...state} dispatch=$dispatch/>');
    }

    function mapState(state: ApplicationState, props: RouteComponentProps): LearnerRatingProps {
        if (state.scholae.auth.loggedIn){
            TeacherViewsHelper.ensureTagsLoaded(state);
            RemoteDataHelper.ensureRemoteDataLoaded(state.teacher.allRating, TeacherAction.LoadAllRating(state.teacher.currentGroup.info.id));
        }

        return {
            tags: if (state.teacher.tags != null && state.teacher.tags.loaded) state.teacher.tags.data else [],
            allRating: if (null != state.teacher.allRating) state.teacher.allRating.data else null,
            learnerId: props.params.id
           }
    }
}
