mongoose = null
Task = null

exports.init = (mongo) ->
    mongoose = mongo

    TaskSchema = mongoose.Schema
        serviceName: String
        servicePath: String
        state: String
        startDate: String
        args: String
        pid: Number

    Task = mongoose.model 'task', TaskSchema

exports.processMessage = (message, amqp) ->  
    switch message.action
        when "create"
            console.log "creating task"
            task = new Task
                serviceName: message.payload.serviceName
                servicePath: message.payload.servicePath
                state: message.payload.state
                startDate: message.payload.startDate
                args: message.payload.args
                pid: message.payload.pid
                closeCode: null

            task.save (err, task) ->
                if err then return console.error err
                console.log "====== task created ======" + message.payload.severity + message.payload.message + new Date()

        when "retrieve"             

            if message.payload
                request = message.payload
                switch request.type
                    when "byPid"
                        Task.find {pid: request.value } , (err, tasks) ->
                            if err then return console.error err
                            console.log tasks
                            message.responceNeeded= false
                            message.payload = tasks
                            amqp.SendMessage message.sender, message

            else 
                Task.find (err, tasks) ->
                    if err then return console.error err
                    console.log tasks
                    message.responceNeeded= false
                    message.payload = tasks
                    amqp.SendMessage message.sender, message


        when "update"             
            console.log "updating task"

            request = {}
            if message.payload
                request = message.payload
                
            Task.update {pid: request.pid, serviceName: request.serviceName, servicePath: request.servicePath } , {state: request.state, closeCode: request.closeCode}, { multi: true } , (err, numAffected) ->
                if err then return console.error err
                message.responceNeeded= false
                message.payload = numAffected
                amqp.SendMessage message.sender, message

        else
            console.log "wrong action"
            message.error = "wrong action"
            amqp.SendMessage message.sender, message.payload