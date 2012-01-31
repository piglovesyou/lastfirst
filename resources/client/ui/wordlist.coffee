###
 Singleton class for words.
###
class WordList extends AbstractComponent

  # public
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
    @lastWord_.elementInner.bind 'click', @onClickLastWord_


  # private
  onEnterLastWordTimer_: null
  onLeaveBlankTimer_: null
  wordInstances_: []
  lastWord_: null

  onClickLastWord_: =>
    window.clearTimeout @onEnterLastWordTimer_
    @onEnterLastWordTimer_ = _.delay =>
      @element.prepend @blankElm
      @blankElm.fadeIn()
      @blankElmInner
        .bind('mouseenter', @onMouseEnterBlankElm_)
        .bind('mouseleave', @onMouseleaveBlankElm_)
        .find('input[type="text"]').val('').focus()
      Time.getInstance().hide()
    , 400

  onMouseEnterBlankElm_: => window.clearTimeout @onLeaveBlankTimer_
  onMouseleaveBlankElm_: =>
    window.clearTimeout @onLeaveBlankTimer_
    @onLeaveBlankTimer_ = _.delay =>
      @blankElmInner.unbind('mouseleave')
      @blankElm.hide().remove()
    , 3000

_.addSingletonGetter(WordList)






