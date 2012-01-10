
  /*
   Extends underscore with word validation function.
  */

  (function() {
    var getFirstLetter_, getLastLetter_, _;
    if (this._ === void 0) {
      _ = require('underscore');
    } else {
      _ = this._;
    }
    getFirstLetter_ = function(str) {
      var count, len, result;
      count = 1;
      len = str.length;
      if (len >= 2 && /^[ゃゅょ|ー]$/.test(str[1])) {
        if (len >= 3 && /^[ー]$/.test(str[2])) {
          count = 3;
        } else {
          count = 2;
        }
      }
      result = [];
      _(count).times(function(i) {
        return result.push(str.slice(0, i + 1));
      });
      return result;
    };
    getLastLetter_ = function(str) {
      var count, lastIndex, len;
      count = 1;
      len = str.length;
      lastIndex = len - 1;
      if (len >= 2 && /^[ゃゅょ|ー]$/.test(str[lastIndex])) {
        if (len >= 3 && /^[ゃゅょ]$/.test(str[lastIndex - 1])) {
          count = 3;
        } else {
          count = 2;
        }
      }
      str = _.last(str, count);
      if (_.isArray(str)) return str = str.join('');
    };
    return _.mixin({
      isValidWord: function(str) {
        if (_.isString(str) && /^[あ-ん|ー]+$/.test(str) && /^[^を]+$/.test(str) && !/っ$/.test(str)) {
          return _.all(str.split(''), function(letter, index, array) {
            if (index === 0) {
              return /^[^ゃゅょ|^っ|^ー]$/.test(letter);
            } else {
              if (/^[ゃゅょ]$/.test(letter)) {
                return /^[きしちにひみりぎじぢび]$/.test(array[index - 1]);
              }
              if (letter === 'っ') return /^[^っ]$/.test(array[index - 1]);
              return true;
            }
          });
        } else {
          return false;
        }
      },
      isEndsN: function(str) {
        return /ん$/.test(str);
      },
      isValidLastFirst: function(last, first) {
        return _.include(getFirstLetter_(first), getLastLetter_(last));
      }
    });
  })();
