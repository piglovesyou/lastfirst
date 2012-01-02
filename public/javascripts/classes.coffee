
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
 Singleton class for words.
###
class WordList
  wordInstances_: []
  element: null
  getElement: () ->
    @element

  constructor: (containerSelector) ->
    @element = $(containerSelector)
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
    


###
 Class for a word.
###
class Word
  element: null
  getElement: () ->
    @element
  canRender: false

  constructor: (data, @lastPost) ->
    @id = data._id
    @content = data.content
    @createdBy = data.createdBy
    @createdAt = data.createdAt
    @liked = data.liked
    @canRender = !!(@id and @content and @createdBy and @createdAt and @liked)
    if @canRender
      className = 'word'
      @element = $("<div class='#{className}'></div>")
  render: () ->
    if @canRender
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

      if @lastPost
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
  dispose: () ->
    @element.unbind()
    @element.remove()
    for prop of @
      @[prop] = null





###
 Singleton class for showing messages.
###
class MessageComponent
  element: null
  messageElm_: null
  importantMessageElm_: null

  constructor: (containerSelector) ->
    importantMessageTimer = null
    messageTimer = null

    @element = $(containerSelector)

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

  show: (str) ->
    @messageElm_.trigger('show', str)
  showImportant: (str) ->
    @importantMessageElm_.trigger('show', str)
      
    
    
###
 Singleton class for time.
###
class TimeComponent
  element: null
  shortTickElm: null
  longTickElm: null
  titleElm: null
  height: 0
  hideTimer: null

  constructor: () ->
    @render()

  render: () ->
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
      pos.left += elm.width()
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






exports.WordList = WordList
exports.Word = Word
exports.MessageComponent = MessageComponent
exports.TimeComponent = TimeComponent

