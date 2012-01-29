###
 Singleton class for words.
###
class WordList extends AbstractComponent
  onEnterLastWordTimer: null
  onLeaveBlankTimer: null
  wordInstances_: []
  lastWord_: null

  constructor: ->
    inner = """
    <div class="inner">
      <div class="image"></div>
      <div class="label">
        <div id="post-form">
        	<form id="post" action="javascript:void(0)" method="POST">
        		<input name="content" type="text">
            <input style="display:none" type="submit" />
        	</form>
        </div>
        <div class="please-login yeah">(Please login.)</div> 
      </div>
    </div>
    """.replace(/(<\/.+?>)[\s\S]*?(<)/g, "$1$2")
    console.log inner
    @blankElmInner = $(inner)
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


  # used by Word instance.
  # @param {Word} @lastWord_
  setAsLastWord: (@lastWord_) ->
    @lastWord_.element.addClass("last-post")
    @lastWord_.elementInner.bind 'click', @onClickLastWord

  onClickLastWord: =>
    window.clearTimeout @onEnterLastWordTimer
    @onEnterLastWordTimer = _.delay =>
      @element.prepend @blankElm
      @blankElm.fadeIn()
      @blankElmInner
        .bind('mouseenter', @onMouseEnterBlankElm)
        .bind('mouseleave', @onMouseleaveBlankElm)
        .find('input[type="text"]').val('').focus()
      Time.getInstance().hide()
    , 400

  onMouseEnterBlankElm: => window.clearTimeout @onLeaveBlankTimer
  onMouseleaveBlankElm: =>
    console.log 'leave'
    window.clearTimeout @onLeaveBlankTimer
    @onLeaveBlankTimer = _.delay =>
      @blankElmInner.unbind('mouseleave')
      @blankElm.hide().remove()
    , 3000

_.addSingletonGetter(WordList)






