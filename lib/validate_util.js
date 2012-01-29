var RESULT_TYPE, _;

_ = require('underscore');

require('./ext_validate');

exports.RESULT_TYPE = RESULT_TYPE = {
  IS_NOT_VALID_POST: 0,
  IS_INVALID_USER: 1,
  IS_PENALTY_USER: 2,
  POST_LOCKED: 3,
  IS_INVALID_WORD: 4,
  IS_NOT_LASTFIRST: 5,
  WORD_ENDS_N: 6,
  IS_VALID: 7
};

exports.postedWord = function(user, users, post, lastDoc, postLocked) {
  if (!_.isObject(post) || _.keys(post).length !== 2 || !post.content || _.isEmpty(post.content) || !post.createdBy || _.isEmpty(post.createdBy)) {
    return RESULT_TYPE.IS_NOT_VALID_POST;
  } else if (!user.isValid()) {
    return RESULT_TYPE.IS_INVALID_USER;
  } else if (users.isPenaltyUser(user.id)) {
    return RESULT_TYPE.IS_PENALTY_USER;
  } else if (postLocked) {
    return RESULT_TYPE.POST_LOCKED;
  } else if (!_.isValidWord(post.content)) {
    return RESULT_TYPE.IS_INVALID_WORD;
  } else if (!_.isValidLastFirst(lastDoc.content, post.content)) {
    return RESULT_TYPE.IS_NOT_LASTFIRST;
  } else if (_.isEndsN(post.content)) {
    return RESULT_TYPE.WORD_ENDS_N;
  } else {
    return RESULT_TYPE.IS_VALID;
  }
};
