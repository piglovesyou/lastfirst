###
 Singleton class for time.
###
class Time extends AbstractComponent

  # public
  render: () ->
    super()
    @element = $("""
      <div class="time" style="display:none"><div class="time-arrow"></div><div class="time-bg"><div class="time-round clearfix"><div class="time-label"><div class="time-label-twelve">12</div><div class="time-label-three">3</div><div class="time-label-six">6</div><div class="time-label-nine">9</div></div><div class="time-tick"><div class="time-tick-short"></div><div class="time-tick-long"></div></div><div class="time-tick-center"></div></div><div class="time-title"><div class="time-title-content"></div></div></div></div>
    """)
    $('body').append(@element)
    @element.css
      'margin-top': @element.height()/-2

    @shortTickElm_ = $('.time-tick-short', @element)
    @longTickElm_ = $('.time-tick-long', @element)
    @titleElm_ = $('.time-title-content', @element)

  attachElement: (elm, time) ->
    elm = $(elm)
    date = new Date(time)
    hourDeg = @getHourDeg_(date)
    minuteDeg = @getMinuteDeg_(date)
    pos = {}

    $(elm)
      .bind 'mouseover', () =>
        @hoverTimer_ = _.delay =>
          @clearTimers_()
          span = $('.label span:last-child', elm)
          pos = span.offset()
          pos.top += span.height() / 2
          pos.left += span.width()

          window.clearTimeout(@hideTimer_)
          @setRotate_ @shortTickElm_, hourDeg
          @setRotate_ @longTickElm_, minuteDeg
          @titleElm_.html(@createTitleHTML_(date))
          @element.css
            top: pos.top
            left: pos.left
          .fadeIn()
        , 400
      .bind 'mouseout', @hideAfterDelay

  hideAfterDelay: =>
    @clearTimers_()
    @hideTimer_ = _.delay @hide, 3000
  hide: =>
    @element.fadeOut()


  # private
  shortTickElm_: null
  longTickElm_: null
  titleElm_: null
  hideTimer_: null
  hoverTimer_: null

  createTitleHTML_: (date) ->
    digits =
      _.padString(date.getHours(), 2) + ':' +
      _.padString(date.getMinutes(), 2)
    niceDate = _.niceDate(date)
    """
    <span class="time-title-digits">#{digits}</span><br />
    <span class="time-title-nice">#{niceDate}</span>
    """
  clearTimers_: ->
    window.clearTimeout(@hoverTimer_)
    window.clearTimeout(@hideTimer_)

  setRotate_: (elm, deg) ->
    elm.css(_.getCssPrefix() + 'transform',  "rotate(#{deg}deg)")

  getHourDeg_: (date) ->
    Math.floor(360 / 12 * date.getHours())

  getMinuteDeg_: (date) ->
    Math.floor(360 / 60 * date.getMinutes())


_.addSingletonGetter(Time)

