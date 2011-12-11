(function() {
  var $list, socket;
  $list = null;
  socket = io.connect('http://localhost');
  socket.on('update', function(docs) {
    var doc, _i, _len, _results;
    docs.reverse();
    $list.empty();
    _results = [];
    for (_i = 0, _len = docs.length; _i < _len; _i++) {
      doc = docs[_i];
      _results.push($list.append("<div>" + doc.createdAt + "//" + doc.name + " :: " + doc.title + "</b>, " + doc.body + "</div>"));
    }
    return _results;
  });
  $(function() {
    var $form;
    $list = $('#list');
    $form = $('#post');
    return $form.submit(function(e) {
      var doc;
      doc = {
        name: $('input[name="name"]', this).val(),
        title: $('input[name="title"]', this).val(),
        body: $('input[name="body"]', this).val(),
        createdAt: new Date()
      };
      return socket.emit('post', doc);
    });
  });
}).call(this);
