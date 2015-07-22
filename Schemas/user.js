var mongoose = require('mongoose');

exports.UserSchema = mongoose.Schema({

    username: String,
    password: String
});