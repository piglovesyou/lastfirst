
###
 Classes used in LastFirstApp
 http://lastfirst.stakam.net/

 Depands on:
   socket.io.js
   underscore.js
   jquery-1.7.js
###

exports = window




    # postfix = ''
    # niceDate = _.niceDate(doc.createdAt)
    # if _.isEndsN(doc.content)
    #   postfix = '<span class="warn">*</span>'
    # html = "<tr>"
    # html += "<td title='#{doc.createdAt}'>#{doc.content}#{postfix} </td>"
    # html += "<td>&lt;-last post </td>" if _i is 0
    # html += "<td>&lt;-your post! </td>" if doc.createdBy is _.getUserId()
    # html += "<td>#{niceDate}</td>" if _i < 2
    # html += "</tr>"
    # $list.append html



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

  constructor: (data, @showCreatedAt) ->
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
      text = @content
      text += '*' if _.isEndsN(@content)
      content = $("<span class='content' title='#{@createdAt}'>#{text}</span>")

      text = ''
      text += '6' for i in @liked
      likedElm = $("<span class='liked i'>#{text}</span>")
      
      @element
        .append(content)
        .append(likedElm)

      userId = _.getUserId()
      if userId isnt @createdBy and not _.include(@liked, userId)
        likeButtonElm = $("<span class='like i'>6</span>")
          .bind 'click', @sendLike
        @element.append(likeButtonElm)

      if @showCreatedAt
        text = ' <-' + _.niceDate(@createdAt, 'en')
        createdAt = $("<span class='createdat'>#{text}</span>")
        @element.append(createdAt)

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
class Message
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
      
    
    


exports.WordList = WordList
exports.Word = Word
exports.Message = Message

