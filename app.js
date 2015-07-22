var amqp = require('AMQP-boilerplate');
var mongoose = require('mongoose');
var log = require('./Schemas/log.js');
var user = require('./Schemas/user.js');

mongoose.connect('mongodb://localhost/test'); 

var util = require('util');



var name = 'datamanager';

amqp.Initialize(name);

var db = mongoose.connection;

db.on('error', function (e) {
    
    console.log('connection error:' + e);
});

var Log = mongoose.model('log', log.LogSchema);
var User = mongoose.model('user', user.UserSchema);

db.once('open', function (callback) {
    
    console.log("-- database connected.");
      
    amqp.CreateRequestQueue(name, function (message) {
    
        //if (!ValidateIncommingMessage(message)) return;
    
        var sender = message.sender;
        var recieverMessageId = message.id;
        
        console.log('+++++++++++++++++++++++++++ receive message');
        
        console.log(util.inspect(message, false, null));

        console.log('+++++++++++++++++++++++++++++++++++++++++++');
    
        ParseMessage(message);            
    });
});


var SendFailResponceBack = function (message, reason) {

    if (message.responceNeeded) {
        message.error = reason;
        message.responceNeeded = false;
        
        if (message.sender)
            amqp.SendMessage(message.sender, message);
    }
}

var ValidateIncommingMessage = function (message) {
    
    if (!message.type || message.type !== name) {
        
        console.log('warning', 'Message received from: ' + message.sender + ' with unappropriated type: ' + message.type);
        SendFailResponceBack(message, 'type of message is not logger, but received by logger');
        return false;
    }
    
    if (message.action !== 'create' && message.action !== 'retrieve') {

        console.log('warning', 'Message received from: ' + message.sender + ' with unappropriated action: ' + message.action);
        SendFailResponceBack(message, 'logger only accepts create and retrieve for action');
        return false;
    }

    return;
}

var ParseMessage = function (message) {

    switch(message.type)
    {
        case "logger":
            processLog(message);
            break;

        case "user":
            processUser(message);
            break;

        default:
            console.log("wrong type");
            message.error = "wrong type";
            amqp.SendMessage(message.sender, message.payload);
            break;
    }
}

var processLog = function(message)
{

    switch(message.action)
    {
        case "create":
            var log = new Log({
                severity: message.payload.severity,
                message: message.payload.message,
                service: message.payload.service,
                date: new Date(),
                stacktrace: message.payload.stacktrace
            });
            
            log.save(function (err, log) {
                if (err) return console.error(err);

                console.log("====== log created ======" + message.payload.severity + message.payload.message + new Date());
            });    
            break;

        case "retrieve":
            user.find(function (err, logs) {
                if (err) return console.error(err);
                console.log(logs);

                amqp.SendMessage(message.sender, logs);
            })   
            break;

        default:
            console.log("wrong action");
            message.error = "wrong action";
            amqp.SendMessage(message.sender, message.payload);
            break;
    }
    
}

var processUser = function(message)
{
    console.log("====== log user    ======" + message.action);
    switch(message.action)
    {
        case "create":
            var user = new User({
                username: message.payload.username,
                password: message.payload.password
            });
            
            user.save(function (err, user) {
                if (err) return console.error(err);

                console.log("====== log user    ======" + message.payload.username + message.payload.password + new Date());
                
                User.find(function (err, users) {

                    if (err) return console.error(err);
                    console.log(users);

                    amqp.SendMessage(message.sender, users);
                })
            });
            break;

        case "retrieve":    

            User.find(function (err, users) {

                if (err) return console.error(err);
                console.log(users);

                console.log(message.sender);

                var userFound = false;

                users.forEach(function (u){
                    if (u.username === message.payload.username && u.password === message.payload.password)
                    {
                        userFound = true;
                        message.payload = {
                            authorized: true
                        }
                        message.responceNeeded = false;
                        amqp.SendMessage(message.sender, message);
                    }
                });

                if(userFound === false)
                {
                    message.payload = {
                        authorized: false
                    }
                    message.responceNeeded = false;
                    amqp.SendMessage(message.sender, message);
                }

                console.log(message);
            })
            break;


        default:
            console.log("wrong action");
            message.error = "wrong action";
            amqp.SendMessage(message.sender, message.payload);
            break;
    }
}