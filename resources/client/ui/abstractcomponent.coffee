###
 Abstract class to manage DOM components.
 usage:
    # create instance
    component = new Component() 
    # append dom in body
    component.render()          
    # unbind all eventHandlers and remove dom
    component.dispose()         
###
class AbstractComponent

  # public
  element: null
  isInDocument: false

  getElement: () ->
    @element
  isInDocument: false
  canRender: () ->
    true
  render: () ->
    @isInDocument = true
  decorate: (elmSelector) ->
    @element = $(elmSelector)
    @isInDocument = true  if @element
  dispose: () ->
    if @isInDocument
      @element.unbind()
      @element.remove()
      for prop of @
        @[prop] = null  if _.isObject(@[prop])
