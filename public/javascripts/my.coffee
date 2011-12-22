###
 LastFirstApp

 Depands on:
   socket.io.js
   underscore.js
   jquery-1.7.js
###


###
 Utils.
###
# common in server and client

getFirstLetter_ = (str) ->
  count = 1
  len = str.length
  if len >= 2 and /^[ゃ-ょ|ー]$/.test(str[1])
    if len >= 3 and /^[ー]$/.test(str[2])
      count = 3
    else
      count = 2
  result = []
  _(count).times (i) ->
    result.push str.slice(0,i+1)
  result

getLastLetter_ = (str) ->
  count = 1
  len = str.length
  lastIndex = len - 1
  if len >= 2 and /^[ゃ-ょ|ー]$/.test(str[lastIndex])
    if len >= 3 and  /^[ー]$/.test(str[lastIndex-1])
      count = 3
    else
      count = 2
  str = _.last(str, count)
  str = str.join('') if _.isArray(str)

_.mixin
  isValidWord: (str) ->
    if _.isString(str) and /^[あ-ん|ー]+$/.test(str) and
        /^[^を]+$/.test(str) and !/っ$/.test(str)
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
  isEndsN: (str) ->
    return /ん$/.test(str)
  isValidLastFirst: (last, first) ->
    _.include getFirstLetter_(first), getLastLetter_(last)

# Client extentions
_.mixin
  parseParamString: (str, sep='&') ->
    result = {}
    for pairStr in str.split(sep)
      pairArr = pairStr.split('=')
      result[pairArr[0]] = pairArr[1]
    result
  stringifyParam: (paramObj, sep='&') ->
    result = ''
    keys = _.keys(paramObj)
    lastIndex = keys.length - 1
    for key in keys
      result += key + '=' + paramObj[key]
      result += sep unless _i is lastIndex
    result
  now: () ->
    Date.now() || +new Date()
  getCookies: () ->
    _.parseParamString(document.cookie, '; ')
  setCookies: (keyValuePairs) ->
    for key of keyValuePairs
      document.cookie = key + '=' + keyValuePairs[key]

  # @param {Date|Number|String} date
  # @param {?String=} lang default is "ja"
  niceDate: ((date, lang) ->
    SECOND = 1000
    MINUTE = 60  * SECOND
    HOUR =   60  * MINUTE
    DAY =   24  * HOUR
    WEEK =   7   * DAY
    MONTH =  31  * DAY
    YEAR =   365 * DAY

    langs =
      en:
        AGO:    ' ago'
        AFTER:  ' after'
        SECOND: ' second'
        MINUTE: ' minute'
        HOUR:   ' hour'
        DAY:    ' day'
        WEEK:   ' week'
        MONTH:  ' month'
        YEAR:   ' year'
        PLURAL: 's'
      ja:
        AGO:    '前'
        AFTER:  '後'
        SECOND: '秒'
        MINUTE: '分'
        HOUR:   '時間'
        DAY:   '日'
        WEEK:   '週'
        MONTH:  '月'
        YEAR:   '年'

    dateFormat =
      en:
        HOUR_MINUTE: "%_:%_"
        MONTH_DATE: "%_.%_"
        YEAR_MONTH_DATE: "%_.%_.%_"
      ja:
        HOUR_MINUTE: "%_:%_"
        MONTH_DATE: ["%_", langs.ja.MONTH, "%_", langs.ja.DAY].join('')
        YEAR_MONTH_DATE: ["%_", langs.ja.YEAR, "%_", langs.ja.MONTH,
                           "%_", langs.ja.DAY].join('')

    pluralize = (num, str, lang) ->
      num = Math.floor(num)
      if lang.PLURAL and num > 1
        num + str + lang.PLURAL
      else
        num + str

    formatize = (format, values...) ->
      for value in values
        format = format.replace("%_", value)
      format

    return (date, lang_) ->
      date = new Date(date) if _.isString(date) or _.isNumber(date)
      if _.isDate(date)
        now = new Date().getTime()
        lang_ = if _.isString(lang_) and langs[lang_] then lang_ else "ja"
        lang = langs[lang_]
        fmt = dateFormat[lang_]
        dist = now - date.getTime()
        agoOrLater = if dist > 0 then lang.AGO else lang.AFTER
        dist = Math.abs(dist)

        if      dist < MINUTE
          "#{pluralize(dist/SECOND, lang.SECOND, lang)}#{agoOrLater}"
        else if dist < HOUR
          "#{pluralize(dist/MINUTE, lang.MINUTE, lang)}#{agoOrLater}"
        else if dist < DAY
          "#{pluralize(dist/HOUR, lang.HOUR, lang)}#{agoOrLater}"
        else if dist < DAY * 3
          "#{pluralize(dist/DAY, lang.DAY, lang)}#{agoOrLater}"
        else if dist < YEAR
          "#{formatize(fmt.MONTH_DATE, date.getMonth()+1, date.getDate())}"
        else
          "#{formatize(fmt.YEAR_MONTH_DATE, date.getFullYear(), date.getMonth()+1, date.getDate())}"
  )()


        




###
 global accessor to the base info
###
currentDocs_ = []
userId_ = ''
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
  getLastDoc: () ->
    currentDocs_[0] || null
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






###
 jQuery init
###
# init
$(->
  token = _.getToken()
  if token
    # verify the token
    socket.emit 'got token',
      token: token
  else
    # first login.
    _.showLoginLink()
  $list = $list_ or ($list_ = $('#word-list'))
  $form = $('#post')
  $form.submit (e) ->
    return if _.isLocked()
    _.disableForm(true)
    id = _.getUserId()
    content = $('input[name="content"]',$form).val()
    return if _.isEmpty(content)

    if id and content and _.isValidWord(content)
      lastDoc = _.getLastDoc()
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
# variables of DOM/jQuery manipulation
$list_ = null
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
renderWords = (docs) ->
  currentDocs_ = docs
  $list = $list_ or ($list_ = $('#word-list'))
  $list.empty()
  for doc in docs
    postfix = ''
    niceDate = _.niceDate(doc.createdAt)
    if _.isEndsN(doc.content)
      postfix = '<span class="warn">*</span>'
    html = "<tr>"
    html += "<td>#{doc.content}#{postfix} </td>"
    html += "<td>&lt;-last post </td>" if _i is 0
    html += "<td>&lt;-your post! </td>" if doc.createdBy is _.getUserId()
    html += "<td>#{niceDate}</td>" if _i < 2
    html += "</tr>"
    $list.append html

socket = io.connect(location.protocol + '//' + location.host)
socket.on 'update', (docs) ->
  renderWords(docs)

socket.on 'need login', () ->
  _.showMessage('Expired. Need another login.')
  _.showLoginLink()

socket.on 'validated nicely!', (data) ->
  id = data.userId
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

