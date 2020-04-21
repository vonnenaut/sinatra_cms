# cms.rb
require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

root = File.expand_path("..", __FILE__)

helpers do
  def load_file(path)    
    file = File.open(path, 'r')
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

get "/:file" do
  @file_name = params[:file]
  path = root + "/data/#{@file_name}"
  @file_contents = load_file(path)

  erb :file
end