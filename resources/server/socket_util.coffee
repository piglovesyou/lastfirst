

_ = require 'underscore'

{Words} = require './words'
{Word}  = require './word'

findOptions =
  sort: [['createdAt', 'descending']]
  limit: 12

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

exports.updateWords = (socket) ->
  findRecentWords (err,docs) ->
    if _.isEmpty(docs)
      saveInitialWord(updateWords_.bind(@, socket))
    else
      updateWords_(socket, err, docs)


