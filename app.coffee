
###
 Include libraries.
###
express = require("express")
mongoose = require("mongoose")
_ = require("underscore")
url = require('url')
querystring = require('querystring')
https = require('https')



###
 Setting DB.
###
WordSchema = new mongoose.Schema(
  content: String
  createdBy: String
  createdAt: Date
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
    return false if !@socket or !@token
    options =
      host: 'www.googleapis.com'
      path: '/oauth2/v1/tokeninfo?access_token=' + @token
    https.get options, (res) =>
      res.on 'data', (data) =>
        json = JSON.parse(data.toString())
        if !json.error
          console.log json
          @id = json.user_id
          @isValid = true
          @socket.emit 'validated nicely!',
            user_id: @id
          updateWords(@socket)
        else
          @socket.emit 'validation fail',
            error: 'too bad.'
  


###
 Singleton class for managing users.
###
class Users
  constructor: (@id, @token) ->
  users_: []
  # @param {User} user
  add: (user) ->
    @users_.push(user)
  remove: (id) ->
    _.find @users_, (user) ->
      if user.id is id
        @users_[_i].splice()
        return true
  # @param {String} idOrToken
  # @return {Boolean}
  has: (idOrToken) ->
    _.find @users_, (user) ->
      user.id is idOrToken or user.token is idOrToken
users = new Users()





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
    if _.keys(post).length is 3 and
        post.content and post.createdBy and post.createdAt
      @model_ = new WordModel()
      @model_ = _.extend(@model_, post)
      @lastLetter = _.last(post)
    else
      console.log 'something goes wrong..'
  save: (fn) ->
    @model_.save(fn)
    @isSaved = true
    
  
  


# fn get `err' and `docs' argument
findRecentWords = (fn) ->
  WordModel.find {},[],findOptions, fn

# could be `io.socket'
updateWords = (socket) ->
  findRecentWords (err,docs) ->
    socket.emit 'update', docs

sendBadBoyMessage = (socket) ->
  socket.emit 'bad boy',
    error: 'you bad body.'
  

  

###
 Socket IO listening.
###
# user.user_id
# user.socket
io.sockets.on 'connection', (socket) ->
  user = new User(socket)
  updateWords(socket)

  socket.on 'got token', (data) ->
    token = data.token
    if !users.has(token)
      user.setToken(token)
      users.add(user)
      user.validate()

  socket.on 'post word', (post) ->
    if not user.isValid
      sendBadBoyMessage(socket)
      return
    word = new Word(post)
    word.save (err) ->
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
  redirect_uri: 'http://localhost:3000/oauth2callback'
  client_id: '381639783208.apps.googleusercontent.com'
oathUrl = 'https://accounts.google.com/o/oauth2/auth?' +
    querystring.stringify(oathQuery)

app.get "/", (req, res) ->
  res.render "index",
    title: "LastFirstApp"
    oathUrl: oathUrl

app.get "/oauth2callback", (req, res) ->
  token = req.query.code
  res.render "oauth2callback"
    layout: false
    title: "LastFirstApp"

app.listen 3000

