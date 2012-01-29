###
 Singleton class for time.
###
class Time extends AbstractComponent
  shortTickElm: null
  longTickElm: null
  titleElm: null
  height: 0
  hideTimer: null
  hoverTimer: null

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
    pos = {}

    $(elm)
      .bind 'mouseover', () =>
        @hoverTimer = _.delay =>
          @clearTimers()
          span = $('.label span:last-child', elm)
          pos = span.offset()
          pos.top += span.height() / 2
          pos.left += span.width()

          window.clearTimeout(@hideTimer)
          @setRotate_ @shortTickElm, hourDeg
          @setRotate_ @longTickElm, minuteDeg
          @titleElm.html(@createTitleHTML(date))
          @element.css
            top: pos.top
            left: pos.left
          .fadeIn()
        , 400
      .bind 'mouseout', () =>
        @clearTimers()
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

  clearTimers: ->
    window.clearTimeout(@hoverTimer)
    window.clearTimeout(@hideTimer)

  setRotate_: (elm, deg) ->
    elm.css(_.getCssPrefix() + 'transform',  "rotate(#{deg}deg)")

  getHourDeg_: (date) ->
    Math.floor(360 / 12 * date.getHours())

  getMinuteDeg_: (date) ->
    Math.floor(360 / 60 * date.getMinutes())

_.addSingletonGetter(Time)

