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
    @imageSearcher_ = new ImageSearcher()
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
      <div class='image loading'></div>
      """)
    @imageSearcher_.setCallback (searcher) ->
      if searcher and
         searcher.results and
         not _.isEmpty searcher.results and
         searcher.results[0] and
         searcher.results[0].url
        $("<img/>").load =>
          image
            .css('background-image': "url(#{searcher.results[0].url})")
            .removeClass('loading')
        .error =>
          image.text('no image').removeClass('loading')
        .attr('src': searcher.results[0].url)
      else
        image.text('no image')
    @imageSearcher_.execute @content

    label = $("<div class='label'></div>")

    title = @content
    title += '*' if _.isEndsN(@content)
    titleElm = $("<span class='titleElm' title='#{@createdAt}'>#{title}</span>")

    label.append(titleElm)

    # TODO: currently `like' not updating
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

