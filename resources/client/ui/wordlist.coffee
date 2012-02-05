###
 Singleton class for words.
###
class WordList extends AbstractComponent

  # public
  blankWord: null
  constructor: ->
    @blankWord = BlankWord.getInstance()
    @blankWord.render()

  empty: () ->
    for word in @wordInstances_
      word.dispose()
    @wordInstances_ = []
    @element.empty()

  renderWords: () ->
    @element.empty()
    for word in @wordInstances_
      word.render()

  push: (word) ->
    @wordInstances_.push(word)
    @element.append(word.getElement())
  shift: (word) ->
    @wordInstances_.shift(word)
  pop: () ->
    word = @wordInstances_.pop()
    word.dispose()
  get: (id) ->
    return _.find @wordInstances_, (word) ->
      return word.id == id
  getLastWord: () ->
    @wordInstances_[0]

  # used by Word instance.
  # @param {Word} @lastWord_
  setAsLastWord: (@lastWord_) ->
    @lastWord_.element.addClass("last-post")
    @lastWord_.elementInner.bind 'click', @onClickLastWord_



  # private
  wordInstances_: []
  lastWord_: null

  onClickLastWord_: =>
    @blankWord.element
      .prependTo(@element)
      .fadeIn()
    @blankWord.attachEvents()
    Time.getInstance().hide()
    false

_.addSingletonGetter(WordList)






