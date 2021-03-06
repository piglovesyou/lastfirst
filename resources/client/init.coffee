


###
 Global accessor to the base info
###
currentDocs_ = []
userId_ = ''
socket = null
message = null  # @type {Message}
_.mixin
  setToken: (token, expires) ->
    _.setCookies
      token: token
      expires: expires
  getToken: () ->
    cookies = _.getCookies()
    cookies.token
  setUserId: (userId) ->
    userId_ = userId
  getUserId: () ->
    userId_
  # Called from oauth window.
  parseToken: (hashStr) ->
    hashStr = hashStr.replace(/^#/,'')
    params = _.parseParamString(hashStr)
    token = params.access_token or ''
    expires = params.expires_in
    if token and expires
      expires = new Date(_.now() + expires * 1000).toString()
      _.setToken(token, expires)
      socket.emit 'got token', token: token
    else
      # show error
  getSocket: () ->
    socket

















###
 Initialize a page.
###

# Variables.



# variables of DOM/jQuery manipulation
# $msgBox_ = null
# postLocked_ = false
# _.mixin
  # isLocked: () ->
  #   postLocked_
  # disableForm: (lock, withoutIndicator) ->
  #   postLocked_ = lock
  #   $inputs = $('#post-form input')
  #   if lock
  #     $inputs.attr(disabled: 'disabled')
  #   else
  #     $inputs.removeAttr('disabled')
  #   # unless withoutIndicator
  #   #   _.showIndicator(lock)
# DOM functions.
# _.mixin
  # hideWaitSecMessage: () ->
  #   $('#wait-sec-message').hide()
  # showIndicator: (show) ->
  #   $indicator = $('#post-form #indicator')
  #   if $indicator
  #     if show
  #       $indicator.addClass('loading')
  #     else
  #       $indicator.removeClass('loading')
_.mixin
  showLoginLink: () ->
    # _.hideWaitSecMessage()
    $('#login-link').show()
  hideLoginLink: () ->
    $('#login-link').hide()
  # showPostForm: () ->
  #  _.hideWaitSecMessage()
  #  $('#post-form').show()
  # setUserIdToHiddenInput: () ->
  #   $('#user-id-input').val(_.getUserId())
  # showMessage: (str) ->
  #   window.clearTimeout(delayTimerId_) if delayTimerId_
  #   $msgBox = $msgBox_ || ($msgBox_ = $('#msg-box').click (e) ->
  #     $(this).fadeOut()
  #   )
  #   $msgBox.text(str).fadeIn()
  #   delayTimerId_ = _.delay () ->
  #     $msgBox.fadeOut()
  #   ,8888

      


###
 Sockets init
###

socketInit = () ->
  socket = io.connect(location.protocol + '//' + location.host)
  socket.on 'update', (docs) ->
    words.empty()
    for doc in docs
      word = new Word(doc, _i is 0)
      word.render()
      word.attachTime(time)
      words.push(word)


  socket.on 'need login', () ->
    message.show('Expired. Need another login.')
    _.showLoginLink()

  socket.on 'validated nicely!', (data) ->
    id = data.userId
    _.setUserId(id)
    # _.setUserIdToHiddenInput(id)
    message.show('Click the last word to post. ↓')
    _.hideLoginLink()
    $('#logout-link').show()
    # _.showPostForm()
    $('body').addClass('logged-in').removeClass('not-logged-in')
    socket.emit 'pull update'

  socket.on 'error message', (data) ->
    message.show(data.message)
    # _.disableForm(false)

  socket.on 'posted successfully', (post) ->
    message.show('"' + post.content + '" posted!')
    # _.disableForm(false)

  socket.on 'got penalty', (data) ->
    message.show(data.message)
    # _.disableForm(true)
    # _.showIndicator(false)

  socket.on 'release penalty', (data) ->
    message.show(data.message)
    # _.disableForm(false)

  socket.on 'update like', (data) ->
    word = words.get(data._id)
    if word
      word.renderLike data.liked
      word.render()
      if word.createdBy is _.getUserId()
        message.showImportant('Somebody liked your post, "' + word.content + '"')
    




# DOM init.
message == null
words = null  # @type {WordList}
time = null
$(->

  # create instances
  message = Message.getInstance()
  message.decorate('.message')
  words = WordList.getInstance()
  words.decorate('.word-list')
  time = Time.getInstance()
  time.render()

  socketInit()

  token = _.getToken()
  if token
    # verify the token
    socket.emit 'got token',
      token: token
  else if window.noAuthForDev
  else
    # first login.
    _.showLoginLink()

  # _.disableForm(false)
  words.element.on 'submit', '#post', (e) ->
    # return false if _.isLocked()
    # _.disableForm(true)
    id = _.getUserId()
    content = $('input[name="content"]', @).val()

    if _.isEmpty(id) or _.isEmpty(content)
      # _.disableForm(false)
    else if _.isValidWord(content)
      lastDoc = words.getLastWord()
      if id is lastDoc.createdBy
        message.show('It\'s not your turn.')
        # _.disableForm(false)
      else if _.isValidLastFirst(lastDoc.content, content)
        socket.emit 'post word',
          content: content
          createdBy: id
      else
        message.show('I\'m not sure it\'s being Last and First.')
        # _.disableForm(false)
    else
      message.show('Please enter a word in HIRAGANA.')
      # _.disableForm(false)
    false
  # for dev
  # $("#login-link > a").click()

)








