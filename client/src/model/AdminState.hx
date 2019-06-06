package model;

import messages.TaskMessage;
import messages.UserMessage;
import utils.RemoteData;

typedef AdminState = {
    users: RemoteData<Array<UserMessage>>,
    tasks: RemoteData<Array<TaskMessage>>
}