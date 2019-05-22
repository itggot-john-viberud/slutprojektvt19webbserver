require 'slim'
require 'sinatra'
require 'SQLite3'
require 'bcrypt'
require 'byebug'
require_relative 'app.rb'
enable :sessions

#module MyModule
    


    def connect()
        db = SQLite3::Database.new("db/database.db")
        db.results_as_hash = true
        return db
    end

    def picture_profil(file, filename)
        file_name = SecureRandom.hex(10)
        oof = filename.split('.')
        file_name <<'.'
        file_name << oof[1]
        File.open("./public/img/profil_img/#{file_name}", 'wb') do |f|
            f.write(file.read)
        end
        return file_name
    end

    def create_user()
        db = connect()
        new_name = params["Username"]
        new_password = params["Password1"]
        new_mail = params["Mail"]
        
        if params["Password1"] == params["Password2"]
            new_password_hash = BCrypt::Password.create(new_password)
            if params[:file]
                filename = params[:file][:filename]
                file = params[:file][:tempfile]
                file_name = picture_profil(file, filename)
                result = db.execute("INSERT INTO user (Username, Password, Mail, Bild) VALUES (?,?,?,?)", new_name, new_password_hash, new_mail, file_name)
            else
                db.execute("INSERT INTO user (Username, Password, Mail) VALUES (?,?,?)", new_name, new_password_hash, new_mail)
            end
            return true
        else 
            return false
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
        return user_id.first
    end


    def get_rooms_in_room(user_id)
        db = connect()
        rooms = db.execute("SELECT room.Id, room.Name, user_room.Role from room
            inner join user_room on room.Id = user_room.RoomId
            where user_room.UserId = ?", user_id["Id"])
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
        
        chat = db.execute("SELECT Id, Username, Text, Bild FROM chat WHERE RoomId = ?", room_id.to_i)
        users = db.execute("SELECT user.Id, user.Username, user.Bild, user_room.Role from user
            inner join user_room on user.Id = user_room.UserId
            where user_room.RoomId = ?", room_id.to_i)

        return chat, users
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
    def send_picture(params)
        db = connect()
        creator = session[:user]
        room_id = session[:room_id]
        if params[:file]
            filename = params[:file][:filename]
            file = params[:file][:tempfile]
            file_name = picture(file, filename)
            result = db.execute("INSERT INTO chat (RoomId, Bild, Username) VALUES (?,?,?)", room_id, file_name, creator)
        end
    end

    def send_message(params, msg)
        db = connect()
        new_text = msg
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

        result = db.execute("SELECT Id FROM chat WHERE Text = ? AND Username = ?", new_text, creator)
        return result[-1].first[1]
    end

    def delete(params)
        db = connect()
        id = params["id"]
        result_new = db.execute("DELETE FROM chat WHERE Id=?", id)
    end

    def edit(params)
        db = connect()
        id = params["id"]
        result = db.execute("SELECT RoomId, Text, Bild, Id, Username FROM chat WHERE Id=?", id)
        return result
    end

    def edit_execute(params)
        db = connect()
        new_text = params["Text"]
        id = params["id"]

        if params[:file]
            filename = params[:file][:filename]
            file = params[:file][:tempfile]
            file_name = picture(file, filename)
            result_new = db.execute("UPDATE chat
                SET Text = ?, Bild = ?
                WHERE Id = ?",
                new_text, file_name, id)
        else
            result_new = db.execute("UPDATE chat
                SET Text = ?
                WHERE Id = ?",
                new_text, id)
        end
    end

    def editprofil(params)
        db = connect()
        user = session[:user]
        result = db.execute("SELECT Username, Bild, Id FROM user WHERE Username=?", user)
        return result
    end

    def editprofil_execute(params)
        db = connect()
        new_name = params["username"]
        id = get_user_id(session[:user])
        if params[:file]
            filename = params[:file][:filename]
            file = params[:file][:tempfile]
            file_name = picture_profil(file, filename)
            byebug
            result_new = db.execute("UPDATE user
                SET Username = ?, Bild = ?
                WHERE Id = ?",
                new_name, file_name, id["Id"])
        else
            result_new = db.execute("UPDATE user
                SET Username = ?
                WHERE Id = ?",
                new_name, id["Id"])
        end
        return new_name
    end

    def get_room_id(roomname)
        db = connect()
        room_id = db.execute("SELECT Id FROM room WHERE Name = ?", roomname)
        return room_id.first["Id"]
    end

    def finish_room(params)
        db = connect()
        new_name = params["Roomname"]
        
        db.execute("INSERT INTO room (Name) VALUES (?)", new_name)

        user_id = get_user_id(session[:user])
        room_id = get_room_id(new_name)
        db.execute("INSERT INTO user_room (UserId, RoomId, Role) VALUES (?,?,?)", user_id["Id"], room_id, "Admin")
    end


    def invite_execute(params)
        db = connect()
        user_id = db.execute("SELECT Id FROM user WHERE Username = ?", params["username"])
        if user_id.length > 0
            db.execute("INSERT INTO user_room (UserId, RoomId, Role) VALUES (?,?,?)", user_id.first["Id"], params["id"], params["role"])
            redirect("/the_dark_room/:username")
        else
            redirect("/invite/:id")
        end  
    end

    def leave(params)
        db = connect()
        user_id = get_user_id(session[:user])
        db.execute("DELETE FROM user_room WHERE UserId = ? AND RoomId = ?", user_id["Id"], params["room_id"])
    end
end