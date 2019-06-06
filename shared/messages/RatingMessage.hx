package messages;

typedef RatingCategory = {
    id: Float,
    rating: Float,
    ?name: String
}

typedef RatingDate = {
    id: Float,
    rating: Float,
    date: Date
}

typedef RatingMessage = {
    rating: Float,
    ?ratingCategory: Array<RatingCategory>,
    ?learner: LearnerMessage,
    ?ratingDate: Array<RatingDate>,
    ?solvedTasks: Float,
    ?ratingByPeriod: Float
}