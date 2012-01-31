
###
 First time when `execute' run, create google.search.ImageSearch instance.
 Just Ignore when `execute' method run AND google.search not yet loaded.
###


class ImageSearcher
  # public
  constructor: ->
    # If true, we're lucky. It's OK even if false.
    if @hasScriptLoaded_() 
      @createImageSearchInstance_()
  execute: (searchString) ->
    if @canExecute_()
      imageSearch.execute(searchString)
  get: -> @googleImageSearch_
  setCallback: (fn) ->
    # I can use this only one time
    if @googleImageSearch_ and not @hasCallback_
      @hasCallback_ = true
      @googleImageSearch_.setSearchCompleteCallback(@, fn, [@])


  # private
  googleImageSearch_: null
  hasCallback_: null
  onSearchCompleteCallback_: null

  hasScriptLoaded_: ->
    window.google and
    window.google.search and
    window.google.search.ImageSearch
  canExecute_: ->
    if not @hasScriptLoaded_() or not @hasCallback_
      # Ignore. Can't search yet.
    else if not @googleImageSearch_
      @createImageSearchInstance_()
    @googleImageSearch_ and @hasCallback_
  createImageSearchInstance_: ->
    @googleImageSearch_ = new google.search.ImageSearch()




_.addSingletonGetter(ImageSearcher)

imageSearcher = ImageSearcher.getInstance()


