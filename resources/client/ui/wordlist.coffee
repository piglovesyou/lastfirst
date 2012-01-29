###
 Singleton class for words.
###
class WordList extends AbstractComponent
  onEnterLastWordTimer: null
  onLeaveBlankTimer: null
  wordInstances_: []
  lastWord_: null

  constructor: ->
    @blankElmInner = $('<div class="inner"><div class="image"></div><div class="label"></div></div>')
    @blankElm = $('<div class="word word-blank" style="display:none"></div>').append @blankElmInner

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


  setAsLastWord: (@lastWord_) ->
    @lastWord_.element.addClass("last-post")
    @lastWord_.elementInner.bind 'click', @onEnterLastWord

  onEnterLastWord: =>
    window.clearTimeout @onEnterLastWordTimer
    @onEnterLastWordTimer = _.delay =>
      @element.prepend @blankElm
      @blankElm.fadeIn()
      @blankElmInner
        .bind('mouseenter', @onMouseEnterBlankElm)
        .bind('mouseleave', @onMouseleaveBlankElm)
    , 400

  onMouseEnterBlankElm: => window.clearTimeout @onLeaveBlankTimer
  onMouseleaveBlankElm: =>
    console.log 'leave'
    window.clearTimeout @onLeaveBlankTimer
    @onLeaveBlankTimer = _.delay =>
      @blankElmInner.unbind('mouseleave')
      @blankElm.hide().remove()
    , 1800

_.addSingletonGetter(WordList)






