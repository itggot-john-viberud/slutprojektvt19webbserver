require 'slim'
require 'sinatra'
require 'SQLite3'
require 'bcrypt'
require 'byebug'
require 'json'
require 'sinatra-websocket'
require_relative 'function.rb'

enable :sessions

set :secured_paths, ["/the_dark_room/:username", "/new_message"]
set :sockets, []
set :server, 'thin'


before do
    if settings.secured_paths.any? { |elem| request.path.start_with?(elem) } 
        if session[:user]
        else
            halt 403
        end
    end
end

error 403 do
    "Forbidden dude"
end

error 404 do
    "muuu"
end

get("/") do
    slim(:index)
end

post("/login") do
    if loggin(params) == true
        session[:user] = params["Username"]
        redirect("/the_dark_room/"+params["Username"])
    else
        redirect("/failed")
    end
end

post("/logout") do
    session.destroy
    redirect("/")
end

get("/failed") do
    slim(:failed)
end
get("/new") do
    slim(:new)
end
post("/create") do
    create_user()
end 


get("/the_dark_room/:username") do
    username = session[:user]
    room = chattrooms(username)
    chat = "NOOB"
    slim(:the_dark_room, locals:{
        rooms: room, chats: chat})
end

get('/the_dark_room/:username/:id') do
    room_id = params["id"]
    if params["id"] != "css.css"
        session[:room_id] = params["id"]
    end
    username = session[:user]
    room = chattrooms(username)
    chat = show(room_id)
    if !request.websocket?
        slim(:the_dark_room, locals:{
            rooms: room, chats: chat})
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
                # EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
                # EM.next_tick { settings.sockets.each{|s| s.send(session[:user]) } }
            end
            ws.onclose do
                warn("websocket closed")
                settings.sockets.delete(ws)
            end
        end
    end
end

post("/new_message") do
    send_message(params)
    redirect("/the_dark_room/:username/#{session[:room_id]}")
end 

post('/delete/:id') do
    delete(params)
    redirect("/the_dark_room/:username/#{session[:room_id]}")
end

get("/edit/:id") do
    byebug
    result = edit(params)
    slim(:edit, locals:{
    chat: result.first})    
end

post('/edit_execute/:id') do
    edit_execute(params)
    redirect("/the_dark_room/:username/#{session[:room_id]}")
end

get("/create_room") do
    slim(:create_room)
end

post("/finish_room") do
    finish_room(params)
    redirect("/the_dark_room/:username")
end