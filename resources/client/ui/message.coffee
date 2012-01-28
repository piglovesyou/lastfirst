###
 ingleton class for showing messages.
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
    size = 
      width: $(elm).width()
      height: $(elm).height()
    pos = {}

    $(elm)
      .bind 'mouseover', () =>
        pos = elm.offset()
        pos.left += size.width / 2

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



