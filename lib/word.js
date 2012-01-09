(function() {
  var Word, Words, _;

  _ = require("underscore");

  Words = null;

  /*
   Class for word.
   @extends Word_
  */

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

  exports.set = function(Words_) {
    Words = Words_;
    if (Words) {
      return Word;
    } else {
      return null;
    }
  };

}).call(this);
