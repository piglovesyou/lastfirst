
_ = require('underscore')
require('./ext_validate')



exports.RESULT_TYPE = RESULT_TYPE =
  IS_NOT_VALID_POST: 0
  IS_INVALID_USER:   1
  IS_PENALTY_USER:   2
  POST_LOCKED:       3
  IS_INVALID_WORD:   4
  IS_NOT_LASTFIRST:  5
  WORD_ENDS_N:       6
  IS_VALID:          7



exports.postedWord = (user, users, post, lastDoc, postLocked) ->
  if not _.isObject(post)         or
      _.keys(post).length isnt 2  or
      not post.content            or
      _.isEmpty(post.content)     or
      not post.createdBy          or
      _.isEmpty(post.createdBy)
    RESULT_TYPE.IS_NOT_VALID_POST
  else if not user.isValid
    RESULT_TYPE.IS_INVALID_USER
  else if users.isPenaltyUser(user.id)
    RESULT_TYPE.IS_PENALTY_USER
  else if postLocked
    RESULT_TYPE.POST_LOCKED
  else if not _.isValidWord(post.content)
    RESULT_TYPE.IS_INVALID_WORD
  else if not _.isValidLastFirst(lastDoc.content, post.content)
    RESULT_TYPE.IS_NOT_LASTFIRST
  else if _.isEndsN(post.content)
    RESULT_TYPE.WORD_ENDS_N
  else
    RESULT_TYPE.IS_VALID


