_ = require("underscore")

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

