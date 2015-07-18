var amqp = require('AMQP-boilerplate');
var mongoose = require('mongoose');
var log = require('./Schemas/log.js');

mongoose.connect('mongodb://localhost/test'); 

var name = 'datamanager';

amqp.Initialize(name);

var db = mongoose.connection;

db.on('error', function (e) {
    
    console.log('connection error:' + e);
});

var Log = mongoose.model('log', log.LogSchema);

db.once('open', function (callback) {
    
    console.log("connected");
  
      
    amqp.CreateRequestQueue(name, function (message) {
    
        //if (!ValidateIncommingMessage(message)) return;
    
        var sender = message.sender;
        var recieverMessageId = message.id;
        
        console.log('recieve message' + message);
        
        if (message.action === 'create') {
    
            console.log('recieve message for create from' + "---" + message.sender);
            
            ParseMessage(message);
            
        }
    
        if (message.action === 'retrieve') {
    
            console.log('recieve message for reterieve from' + "---" + message.sender);
        }
        
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
        
        console.log('warning', 'Message recieved from: ' + message.sender + ' with unapproperiate type: ' + message.type);
        SendFailResponceBack(message, 'type of message is not logger, but recieved by logger');
        return false;
    }
    
    if (message.action !== 'create' && message.action !== 'retrieve') {

        console.log('warning', 'Message recieved from: ' + message.sender + ' with unapproperiate action: ' + message.action);
        SendFailResponceBack(message, 'logger only accepts create and retieve for action');
        return false;
    }

    return;
}

var ParseMessage = function (message) {
    
    if(message.type === "logger")
    {
        
        var log1 = new Log({
            severity: message.payload.severity,
            message: message.payload.message,
            service: message.payload.service,
            date: message.payload.data,
            stacktrace: message.payload.stacktrace
        });
        
        log1.save(function (err, log1) {
            if (err) return console.error(err);
            
            
            Log.find(function (err, kittens) {
                if (err) return console.error(err);
                console.log(kittens);
            })
        });
      
        
    }
}

