amqp        = require 'AMQP-boilerplate'
mongoose    = require 'mongoose'
log         = require './schemas/log'
user        = require './schemas/user'
task        = require './schemas/task'
output      = require './schemas/output'
zbrmqueues  = require './schemas/zbrmqueues'
chat        = require './schemas/chat'
util        = require 'util'

name        = 'datamanager'

amqp.Initialize name, () ->

    mongoose.connect 'mongodb://195.143.229.153/zettabox'
    db = mongoose.connection

    db.on 'error', (e) ->
        console.log 'connection error:' + e

    db.once 'open', (callback) ->
        console.log "connected to the database."  

        user.init mongoose
        task.init mongoose
        output.init mongoose
        zbrmqueues.init mongoose
        chat.init mongoose
        log.init mongoose

        amqp.CreateRequestQueue name, (message) ->    
    
            sender = message.sender
            recieverMessageId = message.id

            console.log '+++++++++++++++++++++++++++ receive message'
            console.log util.inspect message, false, null
            console.log '+++++++++++++++++++++++++++++++++++++++++++'

            ParseMessage message

    ParseMessage = (message) ->
        if message.action is 'kill' then process.exit(1)

        switch message.type
            when "logger"       then processLog message
            when "user"         then processUser message
            when "task"         then processTask message
            when "output"       then processOutput message
            when "zbrmqueues"   then processZbrmqueues message
            when "chat"         then processChat message
            else
                console.log "wrong type"
                message.error = "wrong type"
                amqp.SendMessage message.sender, message.payload

    processLog = (message) ->
        try
            log.processMessage message, amqp
        catch e
            #ignore

    processUser = (message) ->
        try
            user.processMessage message, amqp
        catch e
            #ignore

    processTask = (message) ->
        try
            task.processMessage message, amqp
        catch e
            #ignore

    processOutput = (message) ->
        try
            output.processMessage message, amqp
        catch e
            #ignore

    processZbrmqueues = (message) ->
        try
            zbrmqueues.processMessage message, amqp
        catch e
            #ignore

    processChat = (message) ->
        try
            chat.processMessage message, amqp
        catch e
            #ignore
