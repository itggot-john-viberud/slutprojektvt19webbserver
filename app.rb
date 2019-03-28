require 'slim'
require 'sinatra'
require 'SQLite3'
require 'bcrypt'
require 'byebug'
require_relative 'function.rb'
enable :sessions

configure do
    set :secured_paths, ["/the_dark_room/:username"]
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
    byebug
    slim(:the_dark_room, locals:{
        rooms: room})
end



