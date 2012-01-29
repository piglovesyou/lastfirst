
SECRET = require('secret-strings').LAST_FIRST
NO_AUTH_FOR_DEV = not SECRET.IS_PRODUCTION and SECRET.NO_AUTH_FOR_DEV
_ = require("underscore")
https = require('https')
crypto = require('crypto')
md5 = (str) -> crypto.createHash('md5').update(str).digest('hex')
{updateWords} = require './socket_util'
users = require('./users').getInstance()

###
 Class for user.
###
class User
  socket: null
  id: ''
  token: ''
  isValid_: false
  isValid: () -> @isValid_
  setValid: (valid) -> @isValid_ = valid

  # private
  validateOK_: (@id) ->
    @isValid_ = true
    users.add(this)
    @socket.emit 'validated nicely!', userId: @id
    # @updateWords()

  # public
  constructor: (@socket) ->
    return false  if not @socket
    @updateWords()
    if NO_AUTH_FOR_DEV
      console.log '\nNO_AUTH_FOR_DEV......!!!!!\n'
      @validateOK_(_.uniqueId('dummy_account_'))
  setToken: (@token) ->
  validate: (fn) ->
    return if not @socket or not @token
    options =
      host: 'www.googleapis.com'
      path: '/oauth2/v1/tokeninfo?access_token=' + @token
    https.get options, (res) =>
      res.on 'data', (data) =>
        json = JSON.parse(data.toString())
        if !json.error
          @validateOK_(md5(json.user_id))
          fn()
        else
          @socket.emit 'need login'
  updateWords: ->
    updateWords(@socket)

exports.User = User


