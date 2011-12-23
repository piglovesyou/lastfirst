
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
  element_: null
  getElement: () ->
    @element_

  constructor: (containerSelector) ->
    @element_ = $(containerSelector)
  empty: () ->
    for word in @wordInstances_
      word.dispose()
    @wordInstances_ = []
    @element_.empty()

  renderWords: () ->
    @element_.empty()
    for word in @wordInstances_
      word.render(@element_)

  push: (word) ->
    @wordInstances_.push(word)
  shift: (word) ->
    @wordInstances_.shift(word)
  pop: () ->
    word = @wordInstances_.pop()
    word.dispose()
  get: (id) ->
    for word in @wordInstances_
      return word  if word.id == id
    null
  getLastWord: () ->
    @wordInstances_[0]
    


###
 Class for a word.
###
class Word
  element_ = null
  timeElm_ = null
  canRender_ = false

  constructor: (data) ->
    @content = data.content
    @createdBy = data.createdBy
    @createdAt = data.createdAt

    @canRender_ = !!(@content and @createdBy and @createdAt)
  render: ($parent) ->
    if @canRender_
      content = $("<span class='content'>#{@content}</span>")
      @timeElm_ = $("<span class='time'>#{@createdAt}</span>")
      className = 'word'
      @element_ = $("<div class='#{className}'></div>").append(content).append(@$timeElm_)
      $parent.append(@element_)
  dispose: () ->
    @element_.remove()
    for prop of @
      @[prop] = null





###
 Singleton class for showing messages.
###
class Message
  element_: null
  messageElm_: null
  importantMessageElm_: null

  constructor: (containerSelector) ->
    importantMessageTimer = null
    messageTimer = null

    @element_ = $(containerSelector)

    # important message
    onDocMouseMove = (e) ->
      $that = e.data.$that
      $(window.document).unbind 'mousemove', onDocMouseMove
      importantMessageTimer = _.delay () ->
        $that.trigger('hide')
      , 3 * 1000
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
        , 3 * 1000
      .bind 'click', (e) ->
        $(this).trigger('hide')

    @element_
      .append(@importantMessageElm_)
      .append(@messageElm_)
  show: (str) ->
    @messageElm_.trigger('show', str)
  showImportant: (str) ->
    @importantMessageElm_.trigger('show', str)
      
    
    


exports.WordList = WordList
exports.Word = Word
exports.Message = Message

