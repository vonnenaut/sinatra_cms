# cms.rb
require "sinatra"
require "sinatra/reloader"
require "sinatra/contrib"
require "tilt/erubis"
require "redcarpet"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

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

def error_for_document_name(name)
  if !(1..100).cover? name.size
    "A name is required."
  elsif get_filenames.include? name
    "File name already exists."
  end
end

get "/" do
  @files = get_filenames
  
  erb :index, layout: :layout
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
  path = File.join(data_path, params[:filename])
  
  @filename = params[:filename]
  @content = File.read(path)

  erb :edit
end

post "/:filename" do
  path = File.join(data_path, params[:filename])

  File.write(path, params[:content])

  session[:message] = "#{params[:filename]} has been updated"
  redirect "/"
end

get "/document/new" do

  erb :new_document, layout: :layout
end

# Create a new, empty, named file
post "/" do
  # To-Do: Troubleshoot validation check failure: not catching empty or already-used filename
  document_name = params[:document_name].strip

  error = error_for_document_name(document_name)
  puts "error: #{error}"

  if error
    session[:message] = error
    erb :new_document, layout: :layout
  else
    # create new file with given name
    filename = params[:document_name]
    File.open("#{data_path}/#{filename}", "w+")
    session[:message] ="#{params[:document_name]} was created."
    redirect "/"
  end

  # refresh the list of files to be rendered at index.erb
  @files = get_filenames

  erb :index, layout: :layout
end
