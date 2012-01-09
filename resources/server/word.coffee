
_ = require("underscore")
Words = null

###
 Class for word.
 @extends Word_
###

class Word
  content: null
  model_: null
  createdBy: null
  createdAt: null
  lastLetter: null
  isSaved: false

  constructor: (post) ->
    if _.keys(post).length is 2 and
        post.content and post.createdBy
      @model_ = new Words()
      @model_.createdAt = new Date()
      @model_ = _.extend(@model_, post)
      @lastLetter = _.last(post)
  save: (fn) ->
    if @model_
      @model_.save () ->
        @isSaved = true
        fn()

exports.set = (Words_) ->
  Words = Words_
  if Words
    Word
  else
    null

