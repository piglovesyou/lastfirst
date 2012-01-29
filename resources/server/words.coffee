
###
 DB setting.
###

mongoose = require 'mongoose'

WordSchema = new mongoose.Schema
  content: String
  createdBy: String
  createdAt: Date
  liked: Array

mongoose.model('Words', WordSchema)
mongoose.connect('mongodb://localhost/lastFirst')
exports.Words = mongoose.model('Words')

# findOptions =
#   sort: [['createdAt', 'descending']]
#   limit: 12

