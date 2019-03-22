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


def chattrooms()
#posts = db.execute("SELECT Rubrik, Bild, Text, Id FROM posts WHERE Creator = '#{session[:user]}'")
end