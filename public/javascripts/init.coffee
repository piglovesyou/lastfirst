




###
 Global accessor to the base info
###
currentDocs_ = []
userId_ = ''
socket = null
words = null  # @type {WordList}
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
      socket.emit 'got token',
        token: token
    else
      # show error
  getSocket: () ->
    socket

















###
 Initialize a page.
###

# Variables.



# DOM init.
$(->

  # create instances
  message = new Message('#msg-box')
  words = new WordList('#word-list')


  socketInit()

  token = _.getToken()
  if token
    # verify the token
    socket.emit 'got token',
      token: token
  else
    # first login.
    _.showLoginLink()

  $form = $('#post')
  $form.submit (e) ->
    return if _.isLocked()
    _.disableForm(true)
    id = _.getUserId()
    content = $('input[name="content"]',$form).val()
    return if _.isEmpty(content)

    if id and content and _.isValidWord(content)
      lastDoc = words.getLastWord()
      if id is lastDoc.createdBy
        message.show('It\'s not your turn.')
        _.disableForm(false)
      else if _.isValidLastFirst(lastDoc.content, content)
        socket.emit 'post word',
          content: content
          createdBy: id
      else
        message.show('I\'m not sure it\'s being Last and First.')
        _.disableForm(false)
    else
      message.show('Please enter a word in HIRAGANA.')
      _.disableForm(false)
  # for dev
  # $("#login-link > a").click()

)








# variables of DOM/jQuery manipulation
$msgBox_ = null
postLocked_ = false
$indicator_ = null
$inputs_ = null
_.mixin
  isLocked: () ->
    postLocked_
  disableForm: (lock, withoutIndicator) ->
    postLocked_ = lock
    $inputs = $inputs_ ||
        ($inputs_ = $('#post-form input'))
    if lock
      $inputs.attr(disabled: 'disabled')
    else
      $inputs.removeAttr('disabled')
    unless withoutIndicator
      _.showIndicator(lock)
# DOM functions.
delayTimerId_ = null
_.mixin
  hideWaitSecMessage: () ->
    $('#wait-sec-message').hide()
  showIndicator: (show) ->
    $indicator = $indicator_ ||
        ($indicator_ = $('#post-form #indicator'))
    if $indicator
      if show
        $indicator.addClass('loading')
      else
        $indicator.removeClass('loading')
_.mixin
  showLoginLink: () ->
    _.hideWaitSecMessage()
    $('#login-link').show()
  hideLoginLink: () ->
    $('#login-link').hide()
  showPostForm: () ->
    _.hideWaitSecMessage()
    $('#post-form').show()
  setUserIdToHiddenInput: () ->
    $('#user-id-input').val(_.getUserId())
  showMessage: (str) ->
    window.clearTimeout(delayTimerId_) if delayTimerId_
    $msgBox = $msgBox_ || ($msgBox_ = $('#msg-box').click (e) ->
      $(this).fadeOut()
    )
    $msgBox.text(str).fadeIn()
    delayTimerId_ = _.delay () ->
      $msgBox.fadeOut()
    ,8888

      


###
 Sockets init
###

socketInit = () ->
  socket = io.connect(location.protocol + '//' + location.host)
  socket.on 'update', (docs) ->
    words.empty()
    for doc in docs
      word = new Word(doc, _i < 2)
      word.render()
      words.push(word)

  socket.on 'need login', () ->
    message.show('Expired. Need another login.')
    #message.show('Expired. Need another login.')
    _.showLoginLink()

  socket.on 'validated nicely!', (data) ->
    id = data.userId
    _.setUserId(id)
    _.setUserIdToHiddenInput(id)
    message.show('Authorized fine.')
    _.hideLoginLink()
    _.showPostForm()

  socket.on 'error message', (data) ->
    message.show(data.message)
    _.disableForm(false)

  socket.on 'posted successfully', (post) ->
    message.show('"' + post.content + '" posted!')
    _.disableForm(false)

  socket.on 'got penalty', (data) ->
    message.show(data.message)
    _.disableForm(true)
    _.showIndicator(false)

  socket.on 'release penalty', (data) ->
    message.show(data.message)
    _.disableForm(false)

  socket.on 'update like', (data) ->
    word = words.get(data._id)
    if word
      word.liked = data.liked
      word.render()
      if word.createdBy is _.getUserId()
        message.showImportant('Somebody liked your post, "' + word.content + '"')
    

