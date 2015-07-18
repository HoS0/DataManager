var mongoose = require('mongoose');

exports.LogSchema = mongoose.Schema({

    severity: String,
	message: String,
	service: String,
	date: String,
	stacktrace: String
});