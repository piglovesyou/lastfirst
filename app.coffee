
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

console.log Words

findOptions =
  sort: [['createdAt', 'descending']]
  limit: 5



###
 Include resources.
###
User = require('./resources/user').User
Word = require('./resources/word').set(Words)
users = require('./resources/users').getInstance()



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

  



###
 Socket IO listening.
###
  
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
    
    
    
    





oauthScopes = [
  'https://www.googleapis.com/auth/userinfo.profile'
]
oauthQuery =
  response_type: 'token'
  scope: oauthScopes.join('+')
  redirect_uri: SECRET.GOOGLE_OAUTH_REDIRECT_TO
  client_id: SECRET.GOOGLE_OAUTH_CLIENT_IE
oauthUrl = 'https://accounts.google.com/o/oauth2/auth?' +
    querystring.stringify(oauthQuery)

# GET requests. 
app.get "/", (req, res) ->
  res.render "index",
    title: "LastFirstApp"
    oauthUrl: oauthUrl
    isProduction: SECRET.IS_PRODUCTION

app.get "/about", (req, res) ->
  res.render "about",
    title: "LastFirstApp - about"
    oauthUrl: oauthUrl

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

