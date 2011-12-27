
###
 Include libraries.
###

SECRET = require('secret-strings').LAST_FIRST
_ = require("underscore")
require('./underscore_extention')
crypto = require('crypto')
md5 = (str) ->
  crypto.createHash('md5').update(str).digest('hex')
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
  liked: Array
)
mongoose.model('Words', WordSchema)
mongoose.connect('mongodb://localhost/lastFirst')
Words = mongoose.model('Words')

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
    https.get options, (res) =>
      res.on 'data', (data) =>
        json = JSON.parse(data.toString())
        if !json.error
          @id = md5(json.user_id)
          @isValid_ = true
          @socket.emit 'validated nicely!',
            userId: @id
          fn()
        else
          @socket.emit 'need login'
  





###
 Class for word.
 @extends Word_
###
class Word
  content: null
  model_: null
  createdBy: null
  createdAt: null
  lastLetter: null
  isSaved: false

  constructor: (post) ->
    if _.keys(post).length is 2 and
        post.content and post.createdBy
      @model_ = new Words()
      @model_.createdAt = new Date()
      @model_ = _.extend(@model_, post)
      @lastLetter = _.last(post)
  save: (fn) ->
    if @model_
      @model_.save () ->
        @isSaved = true
        fn()

    
getInitialWord = () ->
  {
    content: 'しりとり'
    createdBy: 'initial post by server'
  }

saveInitialWord = (fn) ->
  word = new Word(getInitialWord())
  word.save(fn)

findRecentWords = (fn) ->
  Words.find {},[],findOptions,fn

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


###
 Singleton class for managing users.
###
class Users
  users_: {}  # only validated users are here.
  penaltyUserIds_: []


  constructor: () ->
  # @param {User} user
  add: (user) ->
    if user.id
      @users_[user.id] = user
  remove: (id) ->
    delete @users_[id]
  has: (id) ->
    !!@users_[id]
  setPenaltyUser: (id) ->
    @penaltyUserIds_.push(id)
    _.delay () =>
      @penaltyUserIds_ = _.without(@penaltyUserIds_, id)
      user = @users_[id]
      if user
        user.socket.emit 'release penalty',
          message: 'Now you can post.'
    , 60 * 60 * 1000
  isPenaltyUser: (id) ->
    _.include(@penaltyUserIds_, id)
users = new Users()


# user that has id (validated).
#users = {}

#penaltyUserIds = []
# need above to manage
# - validated users
# - penalty users












  
io.sockets.on 'connection', (socket) ->
  user = new User(socket)
  updateWords(socket)
  socket.on 'got token', (data) ->
    token = data.token
    user.setToken(token)
    user.validate () ->
      users.add(user)
      updateWords(socket)
      if users.isPenaltyUser(user.id)
        socket.emit 'got penalty',
          message: 'ん! you can\'t post for a while.'
  socket.on 'post word', (post) ->
    if not user.isValid()
      socket.emit 'error message',
        message: 'you bad boy.'
    if users.isPenaltyUser(user.id)
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
      users.setPenaltyUser(user.id)
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

  socket.on 'like', (data) ->
    userId = data.userId
    wordId = data.wordId
    if users.has(data.userId)
      Words.findById wordId, (err, word) ->
        unless err
          liked = word.liked
          if _.include(liked, userId)
            socket.emit 'error message',
              message: 'you bad boy.'
          else
            word.liked.push(userId)
            Words.update {_id: wordId}, {liked: liked}, null, () ->
              io.sockets.emit 'update like', word
    
  socket.on 'disconnect', () ->
    users.remove(user.id)
    
    
    
    





# GET requests. 
oathScopes = [
  'https://www.googleapis.com/auth/userinfo.profile'
]
oathQuery =
  response_type: 'token'
  scope: oathScopes.join('+')
  redirect_uri: SECRET.GOOGLE_OAUTH_REDIRECT_TO
  client_id: SECRET.GOOGLE_OAUTH_CLIENT_IE
oathUrl = 'https://accounts.google.com/o/oauth2/auth?' +
    querystring.stringify(oathQuery)

app.get "/", (req, res) ->
  res.render "index",
    title: "LastFirstApp"
    oathUrl: oathUrl
    isProduction: SECRET.IS_PRODUCTION

app.get "/about", (req, res) ->
  res.render "about",
    title: "LastFirstApp - about"
    oathUrl: oathUrl

# dev
app.get "/dev", (req, res) ->
  res.render "dev",
    isProduction: true
    title: "dev"

app.get "/oauth2callback", (req, res) ->
  token = req.query.code
  res.render "oauth2callback"
    layout: false
    title: "LastFirstApp"

app.listen SECRET.PORT

