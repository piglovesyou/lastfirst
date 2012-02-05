###
 Class for form area of wordList.
###
class BlankWord extends AbstractComponent

  # public
  constructor: ->
    super()
    @imageSearcher_ = new ImageSearcher()
    @onKeyup_ = _.debounce @onKeyup_, 800
  render: ->
    return  if @isInDocument
    super()

    @textElm_ = $("""
      <input name="content" type="text" maxlength="7">
      """)
    @formElm_ = $(_.trimHTML("""
      <form id="post" action="javascript:void(0)" method="POST">
        <input style="display:none" type="submit" />
      </form>
      """)).prepend(@textElm_)
    @imageElm_ = $("""
        <div class="image"></div>
        """)
    @innerElm_ = $(_.trimHTML("""
      <div class="inner">
        <div class="label">
          <div id="post-form"></div>
          <div class="please-login yeah">(Please login.)</div> 
        </div>
        <div class="blank-word-google-branding">
          <span>powered by </span>
          <img src="https://www.google.com/uds/css/small-logo.png"/>
        </div>
      </div>
      """))
    @innerElm_.prepend(@imageElm_).find('#post-form').append(@formElm_)
    @element = $("""
      <div class="word word-blank" style="display:none"></div>
    """).append(@innerElm_)
    
  attachEvents: ->
    @textElm_.bind('keyup text', @onKeyup_).val('').focus()
    @innerElm_
      .bind('mouseenter', @onMouseEnterBlankElm_)
      .bind('mouseleave', @onMouseleaveBlankElm_)
    ImageSearcher.getInstance().setCallback @onSearchComplete_
    @imageElm_.removeAttr('style').empty()
  detatchEvents: ->
    @textElm_.unbind()
    @innerElm_.unbind()


  # private
  imageSearcher_: null
  innerElm_: null
  formElm_: null
  textElm_: null
  hideTimer_: null


  onKeyup_: =>
    str = @textElm_.val()
    if _.isValidWord(str)
      @sendSearchRequest(str)  

  sendSearchRequest: (str) =>
    @imageElm_.removeAttr('style').addClass('loading')
    str = _.escapeHTML(str)
    ImageSearcher.getInstance().execute(str)

  onSearchComplete_: (searcher) =>
    if searcher and
       searcher.results and
       not _.isEmpty searcher.results and
       searcher.results[0] and
       searcher.results[0].url
      $("<img/>").load =>
        imageInnerElm = $("""
        <span class="image-inner" style="background-image:url(#{searcher.results[0].url})"></span>
        """)
        @imageElm_.removeClass('loading').empty().append(imageInnerElm)
      .error =>
        @imageElm_.text('no image').removeClass('loading')
      .attr('src': searcher.results[0].url)
    else
      image.text('no image')


  onMouseEnterBlankElm_: => window.clearTimeout @hideTimer_

  onMouseleaveBlankElm_: =>
    window.clearTimeout @hideTimer_
    @hideTimer_ = _.delay =>
      @detatchEvents()
      @element.hide().remove()
    , 3000



_.addSingletonGetter(BlankWord)
