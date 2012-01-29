var Word, Words, findOptions, findRecentWords, getInitialWord, lastDoc_, saveInitialWord, updateWords_, _;

_ = require('underscore');

Words = require('./words').Words;

Word = require('./word').Word;

findOptions = {
  sort: [['createdAt', 'descending']],
  limit: 12
};

getInitialWord = function() {
  return {
    content: 'しりとり',
    createdBy: 'initial post by server'
  };
};

saveInitialWord = function(fn) {
  var word;
  word = new Word(getInitialWord());
  return word.save(fn);
};

findRecentWords = function(fn) {
  return Words.find({}, [], findOptions, fn);
};

lastDoc_ = {};

exports.getLastDoc = function() {
  return lastDoc_ || {};
};

updateWords_ = function(socket, err, docs) {
  if (err) return;
  lastDoc_ = docs[0];
  return socket.emit('update', docs);
};

exports.updateWords = function(socket) {
  return findRecentWords(function(err, docs) {
    if (_.isEmpty(docs)) {
      return saveInitialWord(updateWords_.bind(this, socket));
    } else {
      return updateWords_(socket, err, docs);
    }
  });
};
