mongoose = null
Output = null

exports.init = (mongo) ->
    mongoose = mongo

    OutputSchema = mongoose.Schema
        serviceName: String
        date: String
        pid: Number
        data: String

    Output = mongoose.model 'output', OutputSchema

exports.processMessage = (message, amqp) ->  
    switch message.action
        when "create"
            console.log "creating output"
            output = new Output
                serviceName: message.payload.serviceName
                pid: message.payload.pid
                date: new Date()
                data: message.payload.data

            output.save (err, output) ->
                if err then return console.error err

                console.log '=======  saved output'

        when "retrieve"             

            if message.payload
                request = message.payload
                switch request.type

                    when "byPid"
                        Output.find {pid: request.value } , (err, outputs) ->
                            if err then return console.error err
                            message.responceNeeded= false
                            message.payload = outputs
                            amqp.SendMessage message.sender, message

                    when "byServiceName"
                        Output.find {serviceName: request.value } , (err, outputs) ->
                            if err then return console.error err
                            message.responceNeeded= false
                            message.payload = outputs
                            amqp.SendMessage message.sender, message


            else 
                Output.find (err, outputs) ->
                    if err then return console.error err
                    message.responceNeeded= false
                    message.payload = outputs
                    amqp.SendMessage message.sender, message



        else
            console.log "wrong action"
            message.error = "wrong action"
            amqp.SendMessage message.sender, message.payload