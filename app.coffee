
###
 Include libraries.
###

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
  isValid: false

  constructor: (@socket) ->
  setToken: (@token) ->
  validate: () ->
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
          @isValid = true
          @socket.emit 'validated nicely!',
            userId: @id
          updateWords(@socket)
        else
          c 'need login.'
          @socket.emit 'need login'
  


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
    if @model_
      @model_.save(fn)
      @isSaved = true
    
  
  


# fn get `err' and `docs' argument
findRecentWords = (fn) ->
  WordModel.find {},[],findOptions, fn

lastDoc_ = {}
getLastDoc = () ->
  lastDoc_ or {}
# could be `io.socket'
updateWords = (socket) ->
  findRecentWords (err,docs) ->
    lastDoc_ = docs[0]
    socket.emit 'update', docs

  

  

###
 Socket IO listening.
###
# user.user_id
# user.socket
postLocked = false
io.sockets.on 'connection', (socket) ->
  user = new User(socket)
  updateWords(socket)

  socket.on 'got token', (data) ->
    c 'got token!!!!!!! from client'
    token = data.token
    user.setToken(token)
    user.validate()

  socket.on 'post word', (post) ->
    console.log '--------------------------------------'
    console.log getLastDoc().content
    if not user.isValid
      socket.emit 'error message',
        message: 'you bad boy.'
    else if postLocked
      socket.emit 'error message',
        message: 'post conflicted with someones post!'
    else if not _.isValidWord(post.content)
      socket.emit 'error message',
        message: 'Do you speak japanese?'
    else if not _.isValidLastFirst(getLastDoc().content, post.content)
      socket.emit 'error message',
        message: 'I\'m not sure it\'s being Last and First.'
    else
      postLocked = true
      word = new Word(post)
      word.save (err) ->
        postLocked = false
        unless err
          socket.emit 'posted successfully', post
          updateWords(io.sockets)
    
    





# HTTP request listening.
oathScopes = [
  'https://www.googleapis.com/auth/userinfo.profile'
]
oathQuery =
  response_type: 'token'
  scope: oathScopes.join('+')
  redirect_uri: 'http://' + SECRET.HOST + ':' + SECRET:PORT + '/oauth2callback'
  client_id: SECRET.GOOGLE_OAUTH_CLIENT_IE
oathUrl = 'https://accounts.google.com/o/oauth2/auth?' +
    querystring.stringify(oathQuery)

app.get "/", (req, res) ->
  res.render "index",
    title: "LastFirstApp"
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

