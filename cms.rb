# cms.rb
require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

root = File.expand_path("..", __FILE__)

helpers do
  def load_file(path)    
    file = File.read(path)
    return file if file

    session[:error] = "The specified file was not found."
    redirect "/"
  end
end

get "/" do
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
  
  erb :index
end

get "/:filename" do
  @file_name = params[:filename]
  path = root + "/data/#{@file_name}"
  headers["Content-Type"] = "text/plain"
  # @file_contents = load_file(path)
  File.read(path)

  erb :file
end