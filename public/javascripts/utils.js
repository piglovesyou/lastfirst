(function() {
  /*
   Utils in LastFirstApp
   http://lastfirst.stakam.net/
  
   Depands on:
     socket.io.js
     underscore.js
     jquery-1.7.js
  */
  var getFirstLetter_, getLastLetter_;
  var __slice = Array.prototype.slice;
  window.cn = function(arg) {
    return console.log.apply(this, arg);
  };
  /*
   Utils common in server and client.
  */
  getFirstLetter_ = function(str) {
    var count, len, result;
    count = 1;
    len = str.length;
    if (len >= 2 && /^[ゃ-ょ|ー]$/.test(str[1])) {
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
    if (len >= 2 && /^[ゃ-ょ|ー]$/.test(str[lastIndex])) {
      if (len >= 3 && /^[ー]$/.test(str[lastIndex - 1])) {
        count = 3;
      } else {
        count = 2;
      }
    }
    str = _.last(str, count);
    if (_.isArray(str)) {
      return str = str.join('');
    }
  };
  _.mixin({
    isValidWord: function(str) {
      if (_.isString(str) && /^[あ-ん|ー]+$/.test(str) && /^[^を]+$/.test(str) && !/っ$/.test(str)) {
        return _.all(str.split(''), function(letter, index, array) {
          if (index === 0) {
            return /^[^ゃ-ょ|^っ]$/.test(letter);
          } else {
            if (/^[ゃ-ょ]$/.test(letter)) {
              return /^[きしちにひみりぎじぢび]$/.test(array[index - 1]);
            }
            if (letter === 'っ') {
              return /^[^っ]$/.test(array[index - 1]);
            }
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
  /*
   Client side utils.
  */
  _.mixin({
    parseParamString: function(str, sep) {
      var pairArr, pairStr, result, _i, _len, _ref;
      if (sep == null) {
        sep = '&';
      }
      result = {};
      _ref = str.split(sep);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        pairStr = _ref[_i];
        pairArr = pairStr.split('=');
        result[pairArr[0]] = pairArr[1];
      }
      return result;
    },
    stringifyParam: function(paramObj, sep) {
      var key, keys, lastIndex, result, _i, _len;
      if (sep == null) {
        sep = '&';
      }
      result = '';
      keys = _.keys(paramObj);
      lastIndex = keys.length - 1;
      for (_i = 0, _len = keys.length; _i < _len; _i++) {
        key = keys[_i];
        result += key + '=' + paramObj[key];
        if (_i !== lastIndex) {
          result += sep;
        }
      }
      return result;
    },
    now: function() {
      return Date.now() || +new Date();
    },
    getCookies: function() {
      return _.parseParamString(document.cookie, '; ');
    },
    setCookies: function(keyValuePairs) {
      var key, _results;
      _results = [];
      for (key in keyValuePairs) {
        _results.push(document.cookie = key + '=' + keyValuePairs[key]);
      }
      return _results;
    },
    niceDate: (function(date, lang) {
      var DAY, HOUR, MINUTE, MONTH, SECOND, WEEK, YEAR, dateFormat, formatize, langs, pluralize;
      SECOND = 1000;
      MINUTE = 60 * SECOND;
      HOUR = 60 * MINUTE;
      DAY = 24 * HOUR;
      WEEK = 7 * DAY;
      MONTH = 31 * DAY;
      YEAR = 365 * DAY;
      langs = {
        en: {
          AGO: ' ago',
          AFTER: ' after',
          SECOND: ' second',
          MINUTE: ' minute',
          HOUR: ' hour',
          DAY: ' day',
          WEEK: ' week',
          MONTH: ' month',
          YEAR: ' year',
          PLURAL: 's'
        },
        ja: {
          AGO: '前',
          AFTER: '後',
          SECOND: '秒',
          MINUTE: '分',
          HOUR: '時間',
          DAY: '日',
          WEEK: '週',
          MONTH: '月',
          YEAR: '年'
        }
      };
      dateFormat = {
        en: {
          HOUR_MINUTE: "%_:%_",
          MONTH_DATE: "%_.%_",
          YEAR_MONTH_DATE: "%_.%_.%_"
        },
        ja: {
          HOUR_MINUTE: "%_:%_",
          MONTH_DATE: ["%_", langs.ja.MONTH, "%_", langs.ja.DAY].join(''),
          YEAR_MONTH_DATE: ["%_", langs.ja.YEAR, "%_", langs.ja.MONTH, "%_", langs.ja.DAY].join('')
        }
      };
      pluralize = function(num, str, lang) {
        num = Math.floor(num);
        if (lang.PLURAL && num > 1) {
          return num + str + lang.PLURAL;
        } else {
          return num + str;
        }
      };
      formatize = function() {
        var format, value, values, _i, _len;
        format = arguments[0], values = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        for (_i = 0, _len = values.length; _i < _len; _i++) {
          value = values[_i];
          format = format.replace("%_", value);
        }
        return format;
      };
      return function(date, lang_) {
        var agoOrLater, dist, fmt, now;
        if (_.isString(date) || _.isNumber(date)) {
          date = new Date(date);
        }
        if (_.isDate(date)) {
          now = new Date().getTime();
          lang_ = _.isString(lang_) && langs[lang_] ? lang_ : "ja";
          lang = langs[lang_];
          fmt = dateFormat[lang_];
          dist = now - date.getTime();
          agoOrLater = dist > 0 ? lang.AGO : lang.AFTER;
          dist = Math.abs(dist);
          if (dist < MINUTE) {
            return "" + (pluralize(dist / SECOND, lang.SECOND, lang)) + agoOrLater;
          } else if (dist < HOUR) {
            return "" + (pluralize(dist / MINUTE, lang.MINUTE, lang)) + agoOrLater;
          } else if (dist < DAY) {
            return "" + (pluralize(dist / HOUR, lang.HOUR, lang)) + agoOrLater;
          } else if (dist < DAY * 3) {
            return "" + (pluralize(dist / DAY, lang.DAY, lang)) + agoOrLater;
          } else if (dist < YEAR) {
            return "" + (formatize(fmt.MONTH_DATE, date.getMonth() + 1, date.getDate()));
          } else {
            return "" + (formatize(fmt.YEAR_MONTH_DATE, date.getFullYear(), date.getMonth() + 1, date.getDate()));
          }
        }
      };
    })()
  });
}).call(this);
