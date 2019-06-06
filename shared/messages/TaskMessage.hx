package messages;

typedef RatingByTag = {
    tagId: Float,
    name:String,
    rating: Float
}

typedef TaskMessage = {
    id: Float,
    name: String,
    level: Int,
    tagIds: Array<Float>,
    isGymTask: Bool,
    codeforcesContestId: Int,
    codeforcesIndex: String,
    isSolved: Bool,
    ?rating: Float,
    ?ratingByTag: Array<RatingByTag>
}
