ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CmsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end

  def test_viewing_history_document
    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "1993 - Yukihiro Matsumoto dreams up Ruby."
  end

  def test_not_found
    # get a file that doesn't exist
    get "/doesnotexist.txt"
   
    # verify app redirects user
    assert_equal 302, last_response.status

    # request page user was redirected to
    get last_response["location"]

    # check page loaded correctly and displays error message
    assert_equal 200, last_response.status
    assert_includes last_response.body, "doesnotexist.txt does not exist."

    # check that error message disappears on reload of page
    get "/"
    refute_includes last_response.body, "The specified file was not found."
  end

  def test_viewing_markdown_document
    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>A File-based Content Management System (CMS)</h1>"
  end

  def test_editing_document
    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end

  # def test_updating_document
  #   post "/changes.txt", content: "new content"

  #   assert_equal 302, last_response.status

  #   get last_response["location"]

  #   assert_includes last_response.body, "changes.txt has been updated"

  #   get "/changes.txt"
  #   assert_equal 200, last_response.status
  #   assert_includes last_response.body, "new content"
  # end  
end
