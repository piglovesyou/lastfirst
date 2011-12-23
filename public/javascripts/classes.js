(function() {
  var Word, WordList, exports;
  exports = window;
  /*
   Singleton class for words.
  */
  WordList = (function() {
    WordList.prototype.wordInstances_ = [];
    WordList.prototype.element_ = null;
    WordList.prototype.getElement = function() {
      return this.element_;
    };
    function WordList(containerSelector) {
      this.element_ = $(containerSelector);
    }
    WordList.prototype.empty = function() {
      var word, _i, _len, _ref;
      _ref = this.wordInstances_;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        word = _ref[_i];
        word.dispose();
      }
      this.wordInstances_ = [];
      return this.element_.empty();
    };
    WordList.prototype.renderWords = function() {
      var word, _i, _len, _ref, _results;
      this.element_.empty();
      _ref = this.wordInstances_;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        word = _ref[_i];
        _results.push(word.render(this.element_));
      }
      return _results;
    };
    WordList.prototype.push = function(word) {
      return this.wordInstances_.push(word);
    };
    WordList.prototype.shift = function(word) {
      return this.wordInstances_.shift(word);
    };
    WordList.prototype.pop = function() {
      var word;
      word = this.wordInstances_.pop();
      return word.dispose();
    };
    WordList.prototype.get = function(id) {
      var word, _i, _len, _ref;
      _ref = this.wordInstances_;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        word = _ref[_i];
        if (word.id === id) {
          return word;
        }
      }
      return null;
    };
    WordList.prototype.getLastWord = function() {
      return this.wordInstances_[0];
    };
    return WordList;
  })();
  /*
   Class for a word.
  */
  Word = (function() {
    var $element_, $timeElm_, canRender_;
    $element_ = null;
    $timeElm_ = null;
    canRender_ = false;
    function Word(data) {
      this.content_ = data.content;
      this.createdBy_ = data.createdBy;
      this.createdAt_ = data.createdAt;
      this.canRender_ = !!(this.content_ && this.createdBy_ && this.createdAt_);
    }
    Word.prototype.render = function($parent) {
      var className, content, div;
      if (this.canRender_) {
        content = $("<span class='content'>" + this.content_ + "</span>");
        this.$timeElm_ = $("<span class='time'>" + this.createdAt_ + "</span>");
        className = 'word';
        div = $("<div class='" + className + "'></div>").append(content).append(this.$timeElm_);
        return $parent.append(div);
      }
    };
    Word.prototype.dispose = function() {
      var prop, _results;
      this.$element_.remove();
      _results = [];
      for (prop in this) {
        _results.push(this[prop] = null);
      }
      return _results;
    };
    return Word;
  })();
  exports.WordList = WordList;
  exports.Word = Word;
}).call(this);
