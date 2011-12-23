
###
 Utils in LastFirstApp
 http://lastfirst.stakam.net/

 Depands on:
   socket.io.js
   underscore.js
   jquery-1.7.js
###

window.cn = (arg) ->
  console.log.apply(@, arg)


###
 Utils common in server and client.
###
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


###
 Client side utils.
###
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


        







