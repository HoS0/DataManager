mongoose = null
Model = null

modelName = ""

exports.init = (mongo) ->
    mongoose = mongo

    # schema to be set
    Schema = mongoose.Schema
        numberOfQueue: Number
        queues: []
        createdAt: Date
        providers: []

    modelName = "Queues"

    Model = mongoose.model modelName, Schema

sendFailResponceBack = (message, amqp, reason) ->
    message.responceNeeded = false
    message.error = reason;
    message.payload.error = reason
    amqp.SendMessage message.sender, message


sendResponceBack = (message, amqp, payload) ->
    message.responceNeeded= false
    message.payload = payload
    amqp.SendMessage message.sender, message


exports.processMessage = (message, amqp) ->  
    switch message.action
        when "create"
            console.log "creating " + modelName

            # model to be set
            model = new Model
                numberOfQueue: message.payload.numberOfQueue
                queues: message.payload.queues
                createdAt: new Date()
                providers: message.payload.providers

            model.save (err, modelr) ->
                if err
                    sendFailResponceBack message, amqp, err
                    return console.error err

        when "retrieve"             

            if message.payload
                request = message.payload
                switch request.type
                    when "byDate"
                        condition =
                            createdAt:
                                $gte: message.payload.from
                                $lt: message.payload.to

                        Model.find(condition).sort({'createdAt': -1}).limit(1).exec (err, models) ->
                            if err
                                sendFailResponceBack message, amqp, err
                                return console.error err

                            sendResponceBack message, amqp, models

            else 
                #Model.find (err, models) ->
                #    if err 
                #        sendFailResponceBack message, amqp, err
                #        return console.error err

                #    sendResponceBack message, amqp, models


        when "removeAll"     
            Model.remove (err) ->
                if err
                    sendFailResponceBack message, amqp, err
                    return console.error err

                sendResponceBack message, amqp,{msg: "all rows has removed"}

        else
            sendFailResponceBack message, amqp, "wrong action"

