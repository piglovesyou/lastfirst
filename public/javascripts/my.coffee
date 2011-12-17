


###
 util
###
_.mixin
  parseParamString: (str, sep='&') ->
    result = {}
    for pairStr in str.split(sep)
      pairArr = pairStr.split('=')
      result[pairArr[0]] = pairArr[1]
    result
  isValidWord: (str) ->
    if _.isString(str) and
        /^[あ-ん|ー]+$/.test(str) and /^[^を]+$/.test(str)
      return _.all str.split(''), (letter, index, array) ->
        if index is 0
          return /^[^ゃ-ょ|^っ]$/.test(letter)
        else
          if /^[ゃ-ょ]$/.test(letter)
            return /^[きしちにひみりぎじぢび]$/.test(array[index-1])
          if letter is 'っ'
            return /^[^っ]$/.test(array[index-1])
          true
    else
      false





# Needs gaguarantee
getFirstLetter_ = (str) ->
  count = 1
  len = str.length
  if len >= 2 and /^[ゃ-ょ|っ]$/.test(str[1])
    if len >= 3 and /^[っ]$/.test(str[2])
      count = 3
    else
      count = 2
  str.slice(0,count)

getLastLetter_ = (str) ->
  count = 1
  len = str.length
  lastIndex = len - 1
  if len >= 2 and /^[ゃ-ょ|っ]$/.test(str[lastIndex])
    if len >= 3 and  /^[ゃ-ょ]$/.test(str[lastIndex-1])
      count = 3
    else
      count = 2
  str = _.last(str, count)
  str = str.join('') if _.isArray(str)
  
_.mixin
  isValidLastFirst: (last, first) ->
    console.log last, first
    getLastLetter_(last) is getFirstLetter_(first)



        




###
 global accessor to the base info
###
token_ = ''
userId_ = ''
_.mixin
  setToken: (token) ->
    token_ = token
  getToken: () ->
    token_
  setUserId: (userId) ->
    userId_ = userId
  getUserId: () ->
    userId_
currentDocs_ = []
_.mixin
  getLastDoc: () ->
    currentDocs_[0] || null
  # Called from oauth window.
  parseToken: (hashStr) ->
    hashStr = hashStr.replace(/^#/,'')
    params = _.parseParamString(hashStr)
    console.log 'parseToken', params
    token = params.access_token or ''
    if (token)
      _.setToken(token)
      socket.emit 'got token',
        token: token
    else
      # show error






###
 jQuery init
###
# variables of DOM/jQuery manipulation
$list_ = null
$msgBox_ = null
# init
$(->
  $list = $list_ or ($list_ = $('#word-list'))
  $form = $('#post')
  $form.submit (e) ->
    content = $('input[name="word"]', this).val()
    id = _.getUserId()
    if id and content and _.isValidWord(content)
      lastDoc = _.getLastDoc()
      if id is lastDoc.createdBy
        _.showMessage('You can post only once a turn.')
      else if _.isValidLastFirst(lastDoc.content, content)
        socket.emit 'post word',
          content: content
          createdBy: id
          createdAt: new Date()
      else
        _.showMessage('I\'m not sure it\'s Last and First.')
    else
      _.showMessage('Do you speak japanese?')
  # for dev
  $("#login-link > a").click()
)
# DOM function
delayTimerId_ = null
_.mixin
  hideLoginLink: () ->
    $('#login-link').hide()
  showPostForm: () ->
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
socket = io.connect('http://localhost')
socket.on 'update', (docs) ->
  currentDocs_ = docs
  $list = $list_ or ($list_ = $('#word-list'))
  $list.empty()
  for doc in docs
    html = "<tr><td>#{doc.content}</td>"
    html += "<td>&lt;-your post!</td>" if doc.createdBy is _.getUserId()
    html += "</tr>"
    $list.append html

socket.on 'validated nicely!', (data) ->
  console.log 'validated good.', data
  id = data.user_id
  _.setUserId(id)
  _.setUserIdToHiddenInput(id)
  _.showMessage('logged in. thank you.')
  _.hideLoginLink()
  _.showPostForm()

socket.on 'validation fail', (data) ->
  console.log 'too bad.', data
  # show 

socket.on 'posted successfully', (post) ->
  _.showMessage('"' + post.content + '" is posted successfully!')
