_ = require("underscore")

###
 Utils.
 Depends on underscore.js
###
# common in server and client

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
  isValidLastFirst: (last, first) ->
    getLastLetter_(last) is getFirstLetter_(first)

