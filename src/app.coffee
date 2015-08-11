amqp        = require 'AMQP-boilerplate'
mongoose    = require 'mongoose'
log         = require './log.js'
user        = require './user.js'
util        = require 'util'

name        = 'datamanager'

amqp.Initialize name, () ->

    mongoose.connect 'mongodb://localhost/test'
    db = mongoose.connection

    db.on 'error', (e) ->
        console.log 'connection error:' + e

    db.once 'open', (callback) ->
        console.log "connected to the database."  

        user.init mongoose
        

        amqp.CreateRequestQueue name, (message) ->    
    
            sender = message.sender
            recieverMessageId = message.id

            console.log '+++++++++++++++++++++++++++ receive message'
            console.log util.inspect message, false, null
            console.log '+++++++++++++++++++++++++++++++++++++++++++'

            ParseMessage message

    ParseMessage = (message) ->
        switch message.type
            when "logger" then processLog message
            when "user" then processUser message
            else
                console.log "wrong type"
                message.error = "wrong type"
                amqp.SendMessage message.sender, message.payload

    processLog = (message) ->
        log.processMessage message, amqp

    processUser = (message) ->
        user.processMessage message, amqp