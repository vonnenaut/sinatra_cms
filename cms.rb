# cms.rb
require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "pathname"
require "redcarpet"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

root = File.expand_path("..", __FILE__)

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
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
  
  erb :index
end

get "/:filename" do
  path = root + "/data/" + params[:filename]

  if File.exist?(path)
    load_file_content(path)
  else 
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  path = root + "/data/" + params[:filename]
  
  @filename = params[:filename]
  @content = File.read(path)

  erb :edit
end

post "/:filename" do
  path = root + "/data/" + params[:filename]

  File.write(path, params[:content])

  session[:message] = "#{params[:filename]} has been updated"
  redirect "/"
end
