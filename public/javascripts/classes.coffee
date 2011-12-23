


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
  #wordIds_: []
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
    #@wordIds_.push(word.id)
    @wordInstances_.push(word)
  shift: (word) ->
    #@wordIds_.shift(word.id)
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
  $element_ = null
  $timeElm_ = null
  canRender_ = false

  constructor: (data) ->
    @content_ = data.content
    @createdBy_ = data.createdBy
    @createdAt_ = data.createdAt

    @canRender_ = !!(@content_ and @createdBy_ and @createdAt_)
  render: ($parent) ->
    if @canRender_
      content = $("<span class='content'>#{@content_}</span>")
      @$timeElm_ = $("<span class='time'>#{@createdAt_}</span>")
      className = 'word'
      div = $("<div class='#{className}'></div>").append(content).append(@$timeElm_)
      $parent.append(div)
  dispose: () ->
    @$element_.remove()
    for prop of @
      @[prop] = null

      
    
    


exports.WordList = WordList
exports.Word = Word

