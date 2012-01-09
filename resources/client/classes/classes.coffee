
###
 Classes used in LastFirstApp
 http://lastfirst.stakam.net/

 Depands on:
   socket.io.js
   underscore.js
   jquery-1.7.js
###

exports = window





###
 Abstract class to manage DOM components.
 usage:
    # create instance
    component = new Component() 
    # append dom in body
    component.render()          
    # unbind all eventHandlers and remove dom
    component.dispose()         
###
class AbstractComponent
  element: null
  getElement: () ->
    @element
  isInDocument: false
  canRender: () ->
    true
  render: () ->
    @isInDocument = true
  decorate: (elmSelector) ->
    @isInDocument = true
    @element = $(elmSelector)
  dispose: () ->
    if @isInDocument
      @element.unbind()
      @element.remove()
      for prop of @
        @[prop] = null  if _.isObject(@[prop])







###
 Singleton class for words.
###
class WordList extends AbstractComponent
  wordInstances_: []

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
_.addSingletonGetter(WordList)
    










###
 Class for a word.
###
class Word extends AbstractComponent
  constructor: (data, @isLastPost) ->
    @id = data._id
    @content = data.content
    @createdBy = data.createdBy
    @createdAt = data.createdAt
    @liked = data.liked
    if @canRender()
      @element = $('<div class="word"></div>')
  canRender: () ->
    !!(@id and @content and @createdBy and @createdAt and @liked)
  render: () ->
    if @canRender()
      super()
      @element.empty()
      text = ''
      userId = _.getUserId()

      text = @content
      text += '*' if _.isEndsN(@content)
      content = $("<span class='content' title='#{@createdAt}'>#{text}</span>")

      text = ''
      text += '6' for i in @liked
      likedElm = $("<span class='liked i'>#{text}</span>")
      
      @element
        .append(content)
        .append(likedElm)

      if userId and userId isnt @createdBy and not _.include(@liked, userId)
        likeButtonElm = $("<span class='like i' title='like it'>6</span>")
          .bind 'click', @sendLike
        @element.append(likeButtonElm)

      if @isLastPost
        lastPostElm = $('<span class="last-post">&lt-last post</span>')
        @element.append(lastPostElm)

      if userId is @createdBy
        yourPostElm = $('<span class="your-post">&lt-your post!</span>')
        @element.append(yourPostElm)

  attachTime: (@time) ->
    @time.attachElement(@element, @createdAt)

  sendLike: (e) =>
    socket = _.getSocket()
    if socket
      socket.emit 'like',
        wordId: @id
        userId: _.getUserId()
_.addSingletonGetter(Word)




###
 Singleton class for showing messages.
###
class Message extends AbstractComponent
  messageElm_: null
  importantMessageElm_: null

  render: () ->  # @override
    super()
    importantMessageTimer = null
    messageTimer = null

    @element = $('<div id="msg-box" title="close this message"></div>')

    # important message
    onDocMouseMove = (e) ->
      $that = e.data.$that
      $(window.document).unbind 'mousemove', onDocMouseMove
      importantMessageTimer = _.delay () ->
        $that.trigger('hide')
      , 7 * 1000
    @importantMessageElm_ = $('<div class="msg important"></div>')
      .hide()
      .bind 'hide', (e) ->
        window.clearTimeout(importantMessageTimer)
        $(window.document).unbind 'mousemove', onDocMouseMove
        $(this).fadeOut()
      .bind 'show', (e, msg) ->
        window.clearTimeout(importantMessageTimer)
        $that = $(this).text(msg)
        $that.fadeIn()
        $(window.document).bind 'mousemove', {$that: $that}, onDocMouseMove
      .bind 'click', (e) ->
        $(this).trigger('hide')

    # regular message
    @messageElm_ = $('<div class="msg"></div>')
      .hide()
      .bind 'hide', (e) ->
        window.clearTimeout(messageTimer)
        $(this).fadeOut()
      .bind 'show', (e, msg) ->
        window.clearTimeout(messageTimer)
        $that = $(this).text(msg)
        $that.fadeIn()
        messageTimer = _.delay () ->
          $that.trigger('hide')
        , 7 * 1000
      .bind 'click', (e) ->
        $(this).trigger('hide')

    @element
      .append(@importantMessageElm_)
      .append(@messageElm_)
      .appendTo('body')

  show: (str) ->
    @messageElm_.trigger('show', str)
  showImportant: (str) ->
    @importantMessageElm_.trigger('show', str)
  dispose: () ->  # @override
    @importantMessageElm_.unbind()
    @messageElm_.unbind()
    super()
_.addSingletonGetter(Message)
      
    
    
###
 Singleton class for time.
###
class Time extends AbstractComponent
  shortTickElm: null
  longTickElm: null
  titleElm: null
  height: 0
  hideTimer: null

  render: () ->
    super()
    @element = $("""
      <div class="time" style="display:none"><div class="time-arrow"></div><div class="time-bg"><div class="time-round clearfix"><div class="time-label"><div class="time-label-twelve">12</div><div class="time-label-three">3</div><div class="time-label-six">6</div><div class="time-label-nine">9</div></div><div class="time-tick"><div class="time-tick-short"></div><div class="time-tick-long"></div></div><div class="time-tick-center"></div></div><div class="time-title"><div class="time-title-content"></div></div></div></div>
    """)
    $('body').append(@element)
    @element.css
      'margin-top': @element.height()/-2

    @shortTickElm = $('.time-tick-short', @element)
    @longTickElm = $('.time-tick-long', @element)
    @titleElm = $('.time-title-content', @element)

  attachElement: (elm, time) ->
    elm = $(elm)
    date = new Date(time)
    hourDeg = @getHourDeg_(date)
    minuteDeg = @getMinuteDeg_(date)
    pos = null
    _.defer () ->
      pos = elm.offset()
      pos.left += elm.width()/2
      pos.top += elm.height()/2

    $(elm)
      .bind 'mouseover', () =>
        window.clearTimeout(@hideTimer)
        @setRotate_ @shortTickElm, hourDeg
        @setRotate_ @longTickElm, minuteDeg
        @titleElm.html(@createTitleHTML(date))
        @element.css
          top: pos.top
          left: pos.left
        .fadeIn()
      .bind 'mouseout', () =>
        @hideTimer = _.delay () =>
          @element.fadeOut()
        , 3000

  createTitleHTML: (date) ->
    digits =
      _.padString(date.getHours(), 2) + ':' +
      _.padString(date.getMinutes(), 2)
    niceDate = _.niceDate(date)
    """
    <span class="time-title-digits">#{digits}</span><br />
    <span class="time-title-nice">#{niceDate}</span>
    """

  setRotate_: (elm, deg) ->
    elm.css(_.getCssPrefix() + 'transform',  "rotate(#{deg}deg)")

  getHourDeg_: (date) ->
    Math.floor(360 / 12 * date.getHours())

  getMinuteDeg_: (date) ->
    Math.floor(360 / 60 * date.getMinutes())
_.addSingletonGetter(Time)




exports.WordList = WordList
exports.Word = Word
exports.Message = Message
exports.Time = Time

