
cn = console.log

###
 Initialize a page.
###

# Variables.

# @type {WordList}
words = null


# DOM init.
$(->
  token = _.getToken()
  if token
    # verify the token
    socket.emit 'got token',
      token: token
  else
    # first login.
    _.showLoginLink()

  # create container
  words = new WordList('#word-list')
  #$list = $list_ or ($list_ = $())
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
        _.showMessage('It\'s not your turn.')
        _.disableForm(false)
      else if _.isValidLastFirst(lastDoc.content, content)
        socket.emit 'post word',
          content: content
          createdBy: id
      else
        _.showMessage('I\'m not sure it\'s being Last and First.')
        _.disableForm(false)
    else
      _.showMessage('Please enter a word in HIRAGANA.')
      _.disableForm(false)
  # for dev
  # $("#login-link > a").click()
)



renderWords = (docs) ->
  #$list = $list_ or ($list_ = $('#word-list'))
  #$list.empty()
  words.empty()
  for doc in docs
    word = new Word(doc)
    words.push(word)
  words.renderWords()






# variables of DOM/jQuery manipulation
#$list_ = null
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

socket = io.connect(location.protocol + '//' + location.host)
socket.on 'update', (docs) ->
  renderWords(docs)

socket.on 'need login', () ->
  _.showMessage('Expired. Need another login.')
  _.showLoginLink()

socket.on 'validated nicely!', (data) ->
  id = data.userId
  console.log id
  _.setUserId(id)
  _.setUserIdToHiddenInput(id)
  _.showMessage('Authorized fine.')
  _.hideLoginLink()
  _.showPostForm()

socket.on 'error message', (data) ->
  _.showMessage(data.message)
  _.disableForm(false)

socket.on 'posted successfully', (post) ->
  _.showMessage('"' + post.content + '" posted!')
  _.disableForm(false)

socket.on 'got penalty', (data) ->
  _.showMessage(data.message)
  _.disableForm(true)
  _.showIndicator(false)

socket.on 'release penalty', (data) ->
  _.showMessage(data.message)
  _.disableForm(false)

