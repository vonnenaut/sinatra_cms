# cms.rb

# A file-based content management system from Launch School's RB175: Network Applications course which uses Ruby's Sinatra web library to provide CRUD functionality, ability to read and display text or markdown files, using redcarpet markdown parser, yaml to store user account information with passwords hashed via bcrypt and containing testing code using Minitest.

# Note:  To add support for new file extensions and rendering, an appropriate renderer method (akin to render_markdown) must be implemented, a case branch added to load_file_content which calls it and a branch created in in error_for_filename to allow the new extension.

require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/contrib"
require "tilt/erubis"
require "redcarpet"
require "yaml"
require "bcrypt"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

# set path for files
def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    render_markdown(content)
  end
end

def get_filenames
  pattern = File.join(data_path, "*")

  Dir.glob(pattern).map do |path|
    File.basename(path)
  end
end

def error_for_filename(name)
  if !(1..100).cover? name.size
    "A name is required."
  elsif get_filenames.include? name
    "File name already exists."
  elsif !name.match(/(.txt$|.md$)/)
    "File extension must be .txt or .md."
  end
end

def signed_in?
  session.key?(:username)
end

def check_if_signed_in
  unless signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end
    YAML.load_file(credentials_path)
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

# check if signed in; if so, list all files; if not, redirect to signin view
get "/" do
  @files = get_filenames
  @username = session[:username] if signed_in?

  erb :index, layout: :layout
  # if signed_in?
  #   @files = get_filenames
  #   @username = session[:username]
  
  #   erb :index, layout: :layout
  # else
  #   redirect "/users/signin"
  # end
end

get "/users/signin" do

  erb :signin, layout: :layout
end

post "/users/signin" do
  username = params[:username]

  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :signin
  end
end

post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end

# show new document form
get "/new" do
  check_if_signed_in

  erb :new, layout: :layout
end

# Create a new, empty, named document
post "/create" do
  check_if_signed_in

  filename = params[:filename].to_s

  # validate user input and handle any errors
  error = error_for_filename(filename)
  if error
    session[:message] = error
    status 422

    erb :new, layout: :layout
  else
    # create new document with given name
    path = File.join(data_path, filename)
    File.write(path, "")
    session[:message] ="#{params[:filename]} was created."

    redirect "/"
  end 
end

# read a file
get "/:filename" do
  path = File.join(data_path, params[:filename])

  if File.exist?(path)
    load_file_content(path)
  else 
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

# edit an existing file
get "/:filename/edit" do
  check_if_signed_in

  path = File.join(data_path, params[:filename])
  
  @filename = params[:filename]
  @content = File.read(path)

  erb :edit
end

# save changes to an edit of a file
post "/:filename" do
  check_if_signed_in

  path = File.join(data_path, params[:filename])

  File.write(path, params[:content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end

# delete a document
post "/:filename/delete" do
  check_if_signed_in
  path = File.join(data_path, params[:filename])

  File.delete(path)

  session[:message] = "#{params[:filename]} has been deleted."
  redirect "/"
end

# mitigate vulnerability which allows viewing app's source code
get "/view" do
  file_path = File.join(data_path, File.basename(params[:filename]))
  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end
