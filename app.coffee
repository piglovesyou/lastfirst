
###
 Include libraries.
###

c = console.log

SECRET = require('secret-strings').LAST_FIRST
_ = require("underscore")
require('./underscore_extention')
express = require("express")
mongoose = require("mongoose")
url = require('url')
querystring = require('querystring')
https = require('https')




###
 DB setting.
###
WordSchema = new mongoose.Schema(
  content: String
  createdBy: String
  createdAt: Date
  nice: {type: Number, default: 0}
)
mongoose.model('WordModel', WordSchema)
mongoose.connect('mongodb://localhost/lastFirstDB')
WordModel = mongoose.model('WordModel')

findOptions =
  sort: [['createdAt', 'descending']]
  limit: 5



###
 App initialize.
###
app = module.exports = express.createServer()
io = require('socket.io').listen(app)
app.configure ->
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(__dirname + "/public")
app.configure "development", ->
  app.use express.errorHandler
    dumpExceptions: true
    showStack: true
app.configure "production", ->
  app.use express.errorHandler()






###
 Class for user.
###
class User
  socket: null
  id: ''
  token: ''
  isValid_: false
  isValid: () ->
    @isValid_
  setValid: (valid) ->
    @isValid_ = valid
  # gotPenalty: () ->
  #   @isValid_ = false
  #   _.delay () =>
  #     @socket.emit 'release penalty'
  #       message: 'Penalty released.'
  #     @isValid_ = true
  #   , 3 * 1000

  constructor: (@socket) ->
  setToken: (@token) ->
  validate: (fn) ->
    return if not @socket or not @token
    options =
      host: 'www.googleapis.com'
      path: '/oauth2/v1/tokeninfo?access_token=' + @token
    c 'before https.get'
    https.get options, (res) =>
      res.on 'data', (data) =>
        json = JSON.parse(data.toString())
        c 'got res from https.get', json
        if !json.error
          c 'validate successfully.'
          @id = json.user_id
          @isValid_ = true
          @socket.emit 'validated nicely!',
            userId: @id
          updateWords(@socket)
          fn()
        else
          c 'need login.'
          @socket.emit 'need login'
  






###
 Class for word.
###
class Word
  content: null
  lastLetter: null
  createdBy: null
  createdAt: null
  model_: null
  isSaved: false

  constructor: (post) ->
    if _.keys(post).length is 2 and
        post.content and post.createdBy
      @model_ = new WordModel()
      @model_.createdAt = new Date()
      @model_ = _.extend(@model_, post)
      @lastLetter = _.last(post)
    else
      c 'something goes wrong..'
  save: (fn) ->
    console.log '@model_', @model_
    if @model_
      @model_.save(fn)
      @isSaved = true
    
getInitialWord = () ->
  obj =
    content: 'しりとり'
    createdBy: 'initial post by server'

saveInitialWord = (fn) ->
  word = new WordModel()
  word = _.extend word, getInitialWord()
  word.save(fn)

findRecentWords = (fn) ->
  WordModel.find {},[],findOptions,fn

lastDoc_ = {}
getLastDoc = () ->
  lastDoc_ or {}

# could be `io.socket'
updateWords_ = (socket, err, docs) ->
  return  if err
  lastDoc_ = docs[0]
  socket.emit 'update', docs

updateWords = (socket) ->
  findRecentWords (err,docs) ->
    if _.isEmpty(docs)
      saveInitialWord(updateWords_.bind(@, socket))
    else
      updateWords_(socket, err, docs)

  

# key: userId, value: User instance

###
 Socket IO listening.
###
# user.user_id
# user.socket

# user that has id (validated).
users = {}

penaltyUserIds = []
setPenaltyUser = (user) ->
  penaltyUserIds.push(user.id)
  _.delay () ->
    penaltyUserIds = _.without(penaltyUserIds, user.id)
    user = users[user.id]
    if user
      user.socket.emit 'release penalty',
        message: 'Now you can post.'
  , 10 * 1000
# need above to manage
# - validated users
# - penalty users

###
 Singleton class for managing users.
###
# class Users
#   constructor: (@id, @token) ->
#   users_: []
#   # @param {User} user
#   add: (user) ->
#     @users_.push(user)
#   remove: (id) ->
#     _.find @users_, (user) ->
#       if user.id is id
#         @users_[_i].splice()
#         return true
#   # @param {String} idOrToken
#   # @return {Boolean}
#   has: (idOrToken) ->
#     _.find @users_, (user) ->
#       user.id is idOrToken or user.token is idOrToken
# users = new Users()
  
io.sockets.on 'connection', (socket) ->
  user = new User(socket)
  updateWords(socket)
  socket.on 'got token', (data) ->
    c 'got token!!!!!!! from client'
    token = data.token
    user.setToken(token)
    user.validate () ->
      users[user.id] = user
      if _.include(penaltyUserIds, user.id)
        socket.emit 'got penalty',
          message: 'ん! you can\'t post for a while.'
  socket.on 'post word', (post) ->
    console.log getLastDoc().content
    if not user.isValid()
      socket.emit 'error message',
        message: 'you bad boy.'
    if _.include(penaltyUserIds, user.id)
      socket.emit 'error message',
        message: 'ん! you can\'t post for a while.'
    else if postLocked
      socket.emit 'error message',
        message: 'post conflicted with someones post!'
    else if not _.isValidWord(post.content)
      socket.emit 'error message',
        message: 'Please enter a Japanese word in HIRAGANA.'
    else if not _.isValidLastFirst(getLastDoc().content, post.content)
      socket.emit 'error message',
        message: 'I\'m not sure it\'s being Last and First.'
    else if _.isEndsN(post.content)
      # user.gotPenalty()
      setPenaltyUser(user)
      word1 = new Word(post)
      word1.save () ->
        word2 = new Word(getInitialWord())
        word2.save () ->
          updateWords(io.sockets)
          socket.emit 'got penalty',
            message: 'ん! you can\'t post for a while.'
    else
      postLocked = true
      word = new Word(post)
      word.save (err) ->
        postLocked = false
        unless err
          socket.emit 'posted successfully', post
          updateWords(io.sockets)

  socket.on 'disconnect', () ->
    if users[user.id]
      delete users[user.id]
    
    
    
    





# GET requests. 
oathScopes = [
  'https://www.googleapis.com/auth/userinfo.profile'
]
oathQuery =
  response_type: 'token'
  scope: oathScopes.join('+')
  redirect_uri: 'http://' + SECRET.HOST + ':' + SECRET.PORT + '/oauth2callback'
  client_id: SECRET.GOOGLE_OAUTH_CLIENT_IE
oathUrl = 'https://accounts.google.com/o/oauth2/auth?' +
    querystring.stringify(oathQuery)

app.get "/", (req, res) ->
  res.render "index",
    title: "LastFirstApp"
    oathUrl: oathUrl

app.get "/about", (req, res) ->
  res.render "about",
    title: "LastFirstApp - about"
    oathUrl: oathUrl

# dev
app.get "/dev", (req, res) ->
  res.render "dev",
    title: "dev"

app.get "/oauth2callback", (req, res) ->
  token = req.query.code
  res.render "oauth2callback"
    layout: false
    title: "LastFirstApp"

app.listen SECRET.PORT

