###
 ingleton class for showing messages.
###
class Message extends AbstractComponent

  # private
  createMsg_: (className, str) ->
    $("<span class=\'#{className}\' style='display:none'></span>")
      .text(str)
      .prependTo(@element)
      .fadeIn()

  # public
  decorate: (elmSelector) ->  # @override
    super(elmSelector)
  
  show: (str) ->
    msgElm = @createMsg_('msg-general', str)
    _.delay ->
      msgElm.fadeOut()
    , 7 * 1000
  showImportant: (str) ->
    msgElm = @createMsg_('msg-important', str)
    _.delay ->
      msgElm.fadeOut()
    , 25 * 1000



#     importantMessageTimer = null
#     messageTimer = null
# 
#     @element = $('<div id="msg-box" title="close this message"></div>')
# 
#     # important message
#     onDocMouseMove = (e) ->
#       $that = e.data.$that
#       $(window.document).unbind 'mousemove', onDocMouseMove
#       importantMessageTimer = _.delay () ->
#         $that.trigger('hide')
#       , 7 * 1000
#     @importantMessageElm_ = $('<div class="msg important"></div>')
#       .hide()
#       .bind 'hide', (e) ->
#         window.clearTimeout(importantMessageTimer)
#         $(window.document).unbind 'mousemove', onDocMouseMove
#         $(this).fadeOut()
#       .bind 'show', (e, msg) ->
#         window.clearTimeout(importantMessageTimer)
#         $that = $(this).text(msg)
#         $that.fadeIn()
#         $(window.document).bind 'mousemove', {$that: $that}, onDocMouseMove
#       .bind 'click', (e) ->
#         $(this).trigger('hide')
# 
#     # regular message
#     @messageElm_ = $('<div class="msg"></div>')
#       .hide()
#       .bind 'hide', (e) ->
#         window.clearTimeout(messageTimer)
#         $(this).fadeOut()
#       .bind 'show', (e, msg) ->
#         window.clearTimeout(messageTimer)
#         $that = $(this).text(msg)
#         $that.fadeIn()
#         messageTimer = _.delay () ->
#           $that.trigger('hide')
#         , 7 * 1000
#       .bind 'click', (e) ->
#         $(this).trigger('hide')
# 
#     @element
#       .append(@importantMessageElm_)
#       .append(@messageElm_)
#       .appendTo('body')
# 
#   show: (str) ->
#     @messageElm_.trigger('show', str)
#   showImportant: (str) ->
#     @importantMessageElm_.trigger('show', str)
#   dispose: () ->  # @override
#     @importantMessageElm_.unbind()
#     @messageElm_.unbind()
#     super()

_.addSingletonGetter(Message)

      
