
class BlankWord extends AbstractComponent

  # public
  render: ->
    return  if @isInDocument
    super()

    @textElm_ = $("""
      <input name="content" type="text">
      """)
    @formElm_ = $(_.trimHTML("""
      <form id="post" action="javascript:void(0)" method="POST">
        <input style="display:none" type="submit" />
      </form>
      """)).prepend(@textElm_)

    @innerElm_ = $(_.trimHTML("""
      <div class="inner">
        <div class="image"></div>
        <div class="label">
          <div id="post-form"></div>
          <div class="please-login yeah">(Please login.)</div> 
        </div>
      </div>
      """))
    @innerElm_.find('#post-form').append(@formElm_)
    @element = $("""
      <div class="word word-blank" style="display:none"></div>
    """).append @innerElm_
    
  attachEvents: ->
    @textElm_.bind('focus', @onFocus_).focus()
    @innerElm_
      .bind('mouseenter', @onMouseEnterBlankElm_)
      .bind('mouseleave', @onMouseleaveBlankElm_)
    # @formElm_
    # @innerElm_
  detatchEvents: ->
    @textElm_.unbind()
    @innerElm_.unbind()
    # @formElm_
    # @innerElm_


  # private
  innerElm_: null
  formElm_: null
  textElm_: null
  onEnterLastWordTimer_: null
  onLeaveBlankTimer_: null


  onMouseEnterBlankElm_: => window.clearTimeout @onLeaveBlankTimer_
  onMouseleaveBlankElm_: =>
    window.clearTimeout @onLeaveBlankTimer_
    @onLeaveBlankTimer_ = _.delay =>
      @detatchEvents()
      @element.hide().remove()
    , 3000
  onFocus_: => console.log 'focused..'



_.addSingletonGetter(BlankWord)
