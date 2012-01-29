
/*
 DB setting.
*/

var WordSchema, mongoose;

mongoose = require('mongoose');

WordSchema = new mongoose.Schema({
  content: String,
  createdBy: String,
  createdAt: Date,
  liked: Array
});

mongoose.model('Words', WordSchema);

mongoose.connect('mongodb://localhost/lastFirst');

exports.Words = mongoose.model('Words');
