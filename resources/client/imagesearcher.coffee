
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
      @googleImageSearch_.execute(searchString)
  setCallback: (fn) ->
    # I can use this only one time
    if not @googleImageSearch_ and @hasScriptLoaded_()
      @createImageSearchInstance_()  
    if @googleImageSearch_ and not @hasCallback_
      @hasCallback_ = true
      @googleImageSearch_.setSearchCompleteCallback(@googleImageSearch_, fn, [@googleImageSearch_])
  # setImageElm: (@targetImageElm_) ->
    


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
    @googleImageSearch_.setRestriction(
      google.search.Search.RESTRICT_SAFESEARCH,
      google.search.Search.SAFESEARCH_OFF)
    @googleImageSearch_.setRestriction(
      google.search.ImageSearch.RESTRICT_RIGHTS,
      google.search.ImageSearch.RIGHTS_REUSE)
    # @googleImageSearch_.setRestriction(
    #   google.search.ImageSearch.RESTRICT_IMAGESIZE,
    #   google.search.ImageSearch.IMAGESIZE_SMALL)
    # @googleImageSearch_.setRestriction(
    #   google.search.ImageSearch.RESTRICT_COLORFILTER,
    #   google.search.ImageSearch.COLOR_WHITE)




_.addSingletonGetter(ImageSearcher)

ImageSearcher.getInstance()


