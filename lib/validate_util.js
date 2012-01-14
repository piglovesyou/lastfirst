(function() {
  var RESULT, _;

  _ = require('underscore');

  require('./ext_validate');

  exports.RESULT = RESULT = {
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
      return RESULT.IS_NOT_VALID_POST;
    } else if (!user.isValid()) {
      return RESULT.IS_INVALID_USER;
    } else if (users.isPenaltyUser(user.id)) {
      return RESULT.IS_PENALTY_USER;
    } else if (postLocked) {
      return RESULT.POST_LOCKED;
    } else if (!_.isValidWord(post.content)) {
      return RESULT.IS_INVALID_WORD;
    } else if (!_.isValidLastFirst(lastDoc.content, post.content)) {
      return RESULT.IS_NOT_LASTFIRST;
    } else if (_.isEndsN(post.content)) {
      return RESULT.WORD_ENDS_N;
    } else {
      return RESULT.IS_VALID;
    }
  };

}).call(this);
