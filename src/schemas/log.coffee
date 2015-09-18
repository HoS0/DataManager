mongoose = null
Model = null

modelName = ""

exports.init = (mongo) ->
    mongoose = mongo

    # schema to be set
    Schema = mongoose.Schema
        severity: String
        message: String
        service: String
        serviceId: String
        stacktrace: String
        createdAt: Date

    modelName = "log"

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

            service = ""
            serviceId = ""
            if message.payload.service
                array = message.payload.service.split('.');

                if(array[0])
                    service = array[0]
                if(array[1])
                    serviceId = array[1]

            # model to be set
            model = new Model
                severity: message.payload.severity,
                message: message.payload.message,
                service: service,
                serviceId: serviceId,
                createdAt: new Date(),
                stacktrace: message.payload.stacktrace

            model.save (err, modelr) ->
                if err
                    sendFailResponceBack message, amqp, err
                    return console.error err

        when "retrieve"             
            if message.payload
                request = message.payload
                condition = {}
                switch request.type
                    when "getByService"
                        array = message.payload.value.split(".");
                        if(array[0])
                            condition.service = array[0]
                        if(array[1])
                            condition.serviceId = array[1]

                        console.log condition

                    when "getByDate"
                        condition =
                            createdAt:
                                $gte: message.payload.from
                                $lt: message.payload.to

                Model.find(condition).sort({'createdAt': -1}).limit(100).exec (err, models) ->
                    if err
                        sendFailResponceBack message, amqp, err
                        return console.error err

                    sendResponceBack message, amqp, models


        when "removeAll"     
            Model.remove (err) ->
                if err
                    sendFailResponceBack message, amqp, err
                    return console.error err

                sendResponceBack message, amqp,{msg: "all rows has removed"}

        else
            sendFailResponceBack message, amqp, "wrong action"

