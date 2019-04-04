require 'slim'
require 'sinatra'
require 'SQLite3'
require 'bcrypt'
require 'byebug'
require_relative 'app.rb'
enable :sessions

def connect
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    return db
end

def create_user
    db = connect()
    new_name = params["Username"]
    new_password = params["Password1"]
    new_mail = params["Mail"]
    
    if params["Password1"] == params["Password2"]
        new_password_hash = BCrypt::Password.create(new_password)
        db.execute("INSERT INTO user (Username, Password, Mail) VALUES (?,?,?)", new_name, new_password_hash, new_mail)
        redirect("/")
    else 
        redirect("/failed")
    end
end

def loggin(params)
    db = connect()
    result = db.execute("SELECT Username, Password FROM user WHERE Username = '#{params["Username"]}'")
    if BCrypt::Password.new(result[0]["Password"]) == params["Password"]
       return true
    else
        return false
    end
end

def get_user_id(username)
    db = connect()
    user_id = db.execute("SELECT Id FROM user WHERE Username = ?", username)
    return user_id.first["Id"]
end

def get_rooms_in_room(user_id)
    db = connect()
    rooms = db.execute("select room.Id, room.Name from room
        inner join user_room on room.Id = user_room.RoomId
        where user_room.UserId = ?", user_id)
    return rooms
end

def chattrooms(username)
    db = connect()
    user_id = get_user_id(username)
    roominfo = get_rooms_in_room(user_id)
    return roominfo
end

def get_chat(room_id)
    db = connect()

    result = db.execute("SELECT Username, Text, Bild FROM chat WHERE RoomId = ?", room_id.to_i)
    return result
end


def show(room_id)
    chat = get_chat(room_id)
    return chat

end

def picture(file, filename)
    file_name = SecureRandom.hex(10)
    oof = filename.split('.')
    file_name <<'.'
    file_name << oof[1]
    File.open("./public/img/chat/#{file_name}", 'wb') do |f|
        f.write(file.read)
    end
    return file_name
end

#FileUtils.cp( params["file"]["tempfile"].path, "./omg.jpg")

def send_message(params)
    db = connect()
    new_text = params["Text"]
    creator = session[:user]
    room_id = session[:room_id]
    if params[:file]
        filename = params[:file][:filename]
        file = params[:file][:tempfile]
        file_name = picture(file, filename)
        result = db.execute("INSERT INTO chat (RoomId, Text, Bild, Username) VALUES (?,?,?,?)", room_id, new_text, file_name, creator)
    else
        result = db.execute("INSERT INTO chat (RoomId, Text, Username) VALUES (?,?,?)", room_id, new_text, creator)
    end

    return result
end


