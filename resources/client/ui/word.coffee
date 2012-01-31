###
 Class for a word.
###
class Word extends AbstractComponent

  # public
  constructor: (data, @isLastPost) ->
    @id = data._id
    @content = data.content
    @createdBy = data.createdBy
    @createdAt = data.createdAt
    @liked = data.liked
    @words_ = null  # @type {WordList}
    @wasAttachedAsLastWord = false
    if @canRender()
      @element = $('<div class="word"></div>')

  canRender: () ->
    !!(not @isInDocument and @id and @content and @createdBy and @createdAt and @liked)

  render: () ->
    return  if not @canRender()

    super()
    @element.empty()
    text = ''
    userId = _.getUserId()

    image = $("""
      <div class='image'>
      <img src="/images/spacer.gif" width="188" height="188" />
      </div>
      """)
    label = $("<div class='label'></div>")

    title = @content
    title += '*' if _.isEndsN(@content)
    titleElm = $("<span class='titleElm' title='#{@createdAt}'>#{title}</span>")

    label.append(titleElm)

    if not _.isEmpty(@liked)
      likeText = ''
      likeText += '6' for i in @liked
      likedElm = $("<span class='liked i'>#{likeText}</span>")
      label.append(likedElm)

    if userId and userId isnt @createdBy and not _.include(@liked, userId)
      likeButtonElm = $("<span class='like i' title='like it'>6</span>")
        .bind 'click', @sendLike
      label.append(likeButtonElm)

    @elementInner = $("<div class='inner'></div>")
      .append(image).append(label)
    @element.append @elementInner

    if @isLastPost
      WordList.getInstance().setAsLastWord(@)
      # @asLastWord()
    else
      @element.removeClass("last-post")

    if userId is @createdBy
      @element.addClass("your-post")
    else
      @element.removeClass("your-post")


  notAsLastWord: =>
    @element.removeClass("last-post")
    if @wasAttachedAsLastWord
      @elementInner.unbind('mouseenter')
      @elementInner.unbind('mouseleave')
      @wasAttachedAsLastWord = false

  attachTime: (@time) ->
    @time.attachElement(@element, @createdAt)

  sendLike: (e) =>
    socket = _.getSocket()
    if socket
      socket.emit 'like',
        wordId: @id
        userId: _.getUserId()

  # private
  
_.addSingletonGetter(Word)

