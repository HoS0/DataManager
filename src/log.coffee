mongoose = null
Log = null

exports.init = (mongo) ->
    mongoose = mongo

    LogSchema = mongoose.Schema
        severity: String
        message: String
        service: String
        date: String
        stacktrace: String

    Log = mongoose.model 'user', LogSchema

exports.processMessage = (message, amqp) ->  
    switch message.action
        when "create"
            console.log "creating log"
            log = new Log
                severity: message.payload.severity,
                message: message.payload.message,
                service: message.payload.service,
                date: new Date(),
                stacktrace: message.payload.stacktrace
            log.save (err, log) ->
                if err then return console.error err
                console.log "====== log created ======" + message.payload.severity + message.payload.message + new Date()

        when "retrieve" 
            user.find (err, logs) ->
                if err then return console.error err
                console.log logs
                amqp.SendMessage message.sender, logs

        else
            console.log "wrong action"
            message.error = "wrong action"
            amqp.SendMessage message.sender, message.payload