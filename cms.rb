# cms.rb
require "sinatra"
require "sinatra/reloader"
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

get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  
  erb :index, layout: :layout
end

get "/:filename" do
  path = File.join(data_path, params[:filename])

  if File.exist?(path)
    load_file_content(path)
  else 
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

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