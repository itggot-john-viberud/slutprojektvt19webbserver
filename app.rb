require 'slim'
require 'sinatra'
require 'SQLite3'
require 'bcrypt'
require 'byebug'
require 'json'
require 'sinatra-websocket'
require_relative 'function.rb'
enable :sessions
#include module
set :secured_paths, ["/the_dark_room/:username", "/new_message"]
set :sockets, []
set :server, 'thin'

# Check if user is logged in and give thereafter acses to the sites
#
# @session [String] :user, the name of the user
before do
    if settings.secured_paths.any? { |elem| request.path.start_with?(elem) } 
        halt 403 unless session[:user]
    end
end

# Display error 403 when user doent have the authority
error 403 do
    "Forbidden dude"
end

# Display error 404
error 404 do
    "muuu"
end

# Display Landing Page
#
get("/") do
    slim(:index)
end

# Loggs in and redirect to (on sucses) '/the_dark_room/', on failed redirect to '/failed'
#
# @param [String] :Username, The username of the user
# @param [String] :Password, The password of the user
#
# @see MyModel#loggin
post("/login") do
    if loggin(params) == true
        session[:user] = params["Username"]
        redirect("/the_dark_room/"+params["Username"])
    else
        redirect("/failed")
    end
end

# Updates an existing logged in status to not logged in and redirects to '/'
#
post("/logout") do
    session.destroy
    redirect("/")
end

# Display failed Page
#
get("/failed") do
    slim(:failed)
end

# Display new page, where you can register a user
#
get("/new") do
    slim(:new)
end

# Creates a new user and redirects to '/'
#
# @param [String] :Username, The name of the new user
# @param [String] :Password1, The first password of the new user
# @param [String] :Password2, The secound password of the new user
# @param [String] :Mail, The mail of the new user
# @param [File] :file, The profile picture of the new user
#
# @see MyModel#create_user
post("/create") do
    if create_user(params) == true
        redirect('/')
    else
        redirect('/failed')
    end
end 

# Attempts to create the user and redirects to ('/')
#
# @param [String] Username, The username
# @param [String] Password1, The password
# @param [String] Password2, The repeated password
# @param [String] :Mail, The mail of the new user
# @param [File] :file, The profile picture of the new user
#
# @see MyModel#create_user
get("/the_dark_room/:username") do
    username = session[:user]
    room= chattrooms(username)
    chat = "NOOB"
    user = "none"
    slim(:the_dark_room, locals:{
        rooms: room, chats: chat, users: user})
end

# Displays room page, based on user, chat id
# A websocket, which creates a connection between computer and server
#
# @param [String] query_string, The search parameters delimited by spaces
#
# @see MyModel#chattrooms
# @see MyModel#show
# @see MyModel#send_message
get('/the_dark_room/:username/:id') do
    room_id = params["id"]
    if params["id"] != "css.css"
        session[:room_id] = params["id"]
    end
    username = session[:user]
    room = chattrooms(username)
    chat, user = show(room_id)
    
    if !request.websocket?
        slim(:the_dark_room, locals:{
            rooms: room, chats: chat, users: user})
    else
        request.websocket do |ws|
            ws.onopen do
                settings.sockets << ws
            end
            ws.onmessage do |msg|
                message_id = send_message(params, msg)
                p message_id
                if params[:file]
                    EM.next_tick { settings.sockets.each{|s| s.send(file_name) } }
                end
                EM.next_tick { settings.sockets.each{|s| 
                    s.send(
                        {
                            message: msg,
                            id: message_id,
                            user: session[:user],
                        }.to_json
                    ) 
                } }
            end
            ws.onclose do
                warn("websocket closed")
                settings.sockets.delete(ws)
            end
        end
    end
end

# Attempts post picture and updates the session
#
# @param [File] file, the picture file
#
# @see MyModel#send_picture
post("/new_picture") do
    send_picture(params)
    redirect("/the_dark_room/:username/#{session[:room_id]}")
end 

# Deletes an existing message and updates the session
#
# @param [Integer] :id, The ID of the message
#
# @see MyModel#delete
post('/delete/:id') do
    delete(params)
    redirect("/the_dark_room/:username/#{session[:room_id]}")
end

# Display edit page based on mesage id
#   
# @param [Integer] :id, The ID of the message
#
# @see MyModel#edit
get("/edit/:id") do
    result = edit(params)
    slim(:edit, locals:{
    chat: result.first})    
end

# Edits an existing message and updates session
#
# @param [Integer] :id, The ID of the message
# @param [String] Text, The text of the message
# @param [File] Bild, The picture of the message
#
# @see MyModel#edit_execute
post('/edit_execute/:id') do
    edit_execute(params)
    redirect("/the_dark_room/:username/#{session[:room_id]}")
end

# Display editprofil page based on user
#   
# @param [String] :user, The username of the user
#
# @see MyModel#editprofil
get("/editprofil/:user") do
    result = editprofil(params)
    slim(:editprofil, locals:{
    profil: result.first})    
end

# Edits an existing user and redirects to '/the_dark_room'
#
# @param [String] :user, The username of the user
# @param [String] Text, The text of the message
# @param [File] Bild, The picture of the message
#
# @see MyModel#editprofil_execute
post('/editprofil_execute/:user') do
    session[:user] = editprofil_execute(params)
    redirect("/the_dark_room/:username")
end

# Display create room Page
#
get("/create_room") do
    slim(:create_room)
end

# Creates a new room and redirects to '/the_dark_room'
#
# @param [String] Roomname, The title of the new room
#
# @see MyModel#finish_room
post("/finish_room") do
    finish_room(params)
    redirect("/the_dark_room/:username")
end

# Display invite Page based on rum id
#
get("/invite/:id") do
    slim(:invite, locals:{info_invite: params})  
end

# Attempts invite and updates the session
#
# @param [String] Username
#
# @see MyModel#invite_execute
post("/invite_execute/:id") do
    invite_execute(params)
end

# Attempts for user to leave room and updates the session
#
# @param [Interger] room_id, The room id
#
# @see MyModel#leave
post("/leave/:room_id") do
    leave(params)
    redirect("/the_dark_room/:username")
end
