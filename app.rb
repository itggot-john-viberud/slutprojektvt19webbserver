require 'slim'
require 'sinatra'
require 'SQLite3'
require 'bcrypt'
require 'byebug'
require_relative 'function.rb'
enable :sessions

configure do
    set :secured_paths, ["/the_dark_room/:username", "/new_message"]
end

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
    slim(:the_dark_room, locals:{
        rooms: room, chats: chat})
end

post("/new_message") do
    send_message(params)
    redirect("/the_dark_room/:username/#{session[:room_id]}")
end 
