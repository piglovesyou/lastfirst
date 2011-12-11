

# variables
$list = null

# sockets init
socket = io.connect('http://localhost')
socket.on 'update', (docs) ->
  docs.reverse()
  $list.empty()
  for doc in docs
    $list.append "<div>#{doc.createdAt}//#{doc.name} :: #{doc.title}</b>, #{doc.body}</div>"

# jQuery init
$(->
  $list = $('#list')
  $form = $('#post')
  $form.submit (e) ->
    doc =
      name: $('input[name="name"]', this).val()
      title: $('input[name="title"]', this).val()
      body: $('input[name="body"]', this).val()
      createdAt: new Date()
    socket.emit 'post', doc
)


