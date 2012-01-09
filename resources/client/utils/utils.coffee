
###
 Utils in LastFirstApp
 http://lastfirst.stakam.net/

 Depands on:
   socket.io.js
   underscore.js
   jquery-1.7.js
###




###
 Utils common in server and client.
###
getFirstLetter_ = (str) ->
  count = 1
  len = str.length
  if len >= 2 and /^[ゃゅょ|ー]$/.test(str[1])
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
  if len >= 2 and /^[ゃゅょ|ー]$/.test(str[lastIndex])
    if len >= 3 and  /^[ゃゅょ]$/.test(str[lastIndex-1])
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
          return /^[^ゃゅょ|^っ|^ー]$/.test(letter)
        else
          if /^[ゃゅょ]$/.test(letter)
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


###
 Client side utils.
###
_.mixin
  addSingletonGetter: (ctor) ->  # Code by google closure lib.
    ctor.getInstance = () ->
      ctor.instance_ || (ctor.instance_ = new ctor())
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
  padString: (str, howmany, padStr="0") ->
    str = str.toString()  if not _.isString(str)
    diff = howmany - str.length
    pad = ''
    if diff >= 1
      _(diff).times () ->
        pad += padStr
      str = pad + str
    str


BrowserType =
  WEBKIT: 0
  GECKO: 1
  MSIE: 2
  OPERA: 3
  OTHER: 4
_.mixin
  getBrowserVendor: () ->
    userAgent = navigator.userAgent.toLowerCase()
    if userAgent.indexOf('webkit') >= 0
      BrowserType.WEBKIT
    else if userAgent.indexOf('gecko') >= 0
      BrowserType.GECKO
    else if userAgent.indexOf('msie') >= 0
      BrowserType.MSIE
    else if userAgent.indexOf('opera') >= 0
      BrowserType.OPERA
    else
      BrowserType.OTHER
CSS_PREFIX = null
_.mixin
  getCssPrefix: () ->
    if not _.isNull(CSS_PREFIX)
      CSS_PREFIX
    else
      switch _.getBrowserVendor()
        when BrowserType.WEBKIT
          CSS_PREFIX = '-webkit-'
        when BrowserType.GECKO
          CSS_PREFIX = '-moz-'
        when BrowserType.MSIE
          CSS_PREFIX = '-ms-'
        when BrowserType.OPERA
          CSS_PREFIX = '-o-'
        when BrowserType.OTHER
          CSS_PREFIX = ''


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


        







