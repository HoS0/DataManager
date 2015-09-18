mongoose = null
User = null

exports.init = (mongo) ->
    mongoose = mongo

    UserSchema = mongoose.Schema 
        username: String,
        password: String

    User = mongoose.model 'user', UserSchema

exports.processMessage = (message, amqp) ->  
    
    console.log "====== log user    ======  " + message.action
        
    switch message.action
        when "create"
            user = new User
                username: message.payload.username,
                password: message.payload.password
            
            user.save (err, user) ->
                if err then return console.error err

                console.log "====== log user    ======" + message.payload.username + message.payload.password + new Date()
                
                User.find (err, users) ->
                    if err then return console.error err
                    console.log users
                    amqp.SendMessage message.sender, users

        when "retrieve"
            User.find (err, users) ->
                if err then return console.error err

                userFound = false

                for u in users
                    if u.username is message.payload.username and u.password is message.payload.password
                        userFound = true
                        message.payload = 
                            authorized: true                        
                        message.responceNeeded = false
                        amqp.SendMessage message.sender, message

                if userFound is false
                    message.payload = 
                        authorized: false
                    message.responceNeeded = false
                    amqp.SendMessage message.sender, message

        else
            console.log "wrong action"
            message.error = "wrong action"
            amqp.SendMessage message.sender, message.payload