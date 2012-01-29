var Word, Words, _;

_ = require("underscore");

/*
 Class for word.
 @extends Word_
*/

Words = require('./words').Words;

Word = (function() {

  Word.prototype.content = null;

  Word.prototype.model_ = null;

  Word.prototype.createdBy = null;

  Word.prototype.createdAt = null;

  Word.prototype.lastLetter = null;

  Word.prototype.isSaved = false;

  function Word(post) {
    if (_.keys(post).length === 2 && post.content && post.createdBy) {
      this.model_ = new Words();
      this.model_.createdAt = new Date();
      this.model_ = _.extend(this.model_, post);
      this.lastLetter = _.last(post);
    }
  }

  Word.prototype.save = function(fn) {
    if (this.model_) {
      return this.model_.save(function() {
        this.isSaved = true;
        return fn();
      });
    }
  };

  return Word;

})();

exports.Word = Word;
