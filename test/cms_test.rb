ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms"

class CmsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def session
    last_request.env["rack.session"]
  end

  def test_index_as_signed_in_user
    create_document "about.md"
    create_document "changes.txt"

    get "/", {}, {"rack.session" => { username: "admin"} }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
  end

  def test_viewing_text_document
    create_document "history.txt", "1993 - Yukihiro Matsumoto dreams up Ruby."

    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "1993 - Yukihiro Matsumoto dreams up Ruby."
  end

  def test_viewing_markdown_document
    create_document "about.md", "# Ruby is..." 

    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_not_found
    # get a file that doesn't exist
    get "/doesnotexist.txt"
   
    # verify app redirects user
    assert_equal 302, last_response.status
    assert_equal "doesnotexist.txt does not exist.", session[:message]
  end

  def test_editing_document
    create_document "changes.txt"
    
    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_updating_document
    post "/changes.txt", content: "new content"

    assert_equal 302, last_response.status

    assert_equal "changes.txt has been updated.", session[:message]

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_view_new_document_form
    get "/new"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, '<input type="submit"'
  end

  def test_create_new_document
    post "/create", document_name: "test.txt"
    assert_equal 302, last_response.status

    assert_equal "test.txt was created.", session[:message]

    get last_response["Location"]
    get last_response["Location"]
    assert_includes last_response.body, "test.txt"
  end

  def test_creating_document_without_name
    post "/create", document_name: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required"
  end

  def test_validating_existing_document_name
    create_document "test.txt"

    post "/create", document_name: "test.txt"
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'File name already exists.'
  end

  def test_deleting_document
    create_document("test.txt")

    post "/test.txt/delete"

    assert_equal 302, last_response.status

    assert_equal "test.txt has been deleted.", session[:message]

    get "/"
    refute_includes last_response.body, "test.txt"
  end

  def test_signin_form
    get "/users/signin"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_signin
    post "/users/signin", username: "admin", password: "secret"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "Welcome"
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_signin_with_bad_credentials
    post "/users/signin", username: "guest", password: "shhhh"
    assert_equal 422, last_response.status
    assert_nil session[:username]
    assert_includes last_response.body, "Invalid Credentials"
  end

  def test_signout
    get "/", {}, {"rack.session" => { username: "admin" } }
    assert_includes last_response.body, "Signed in as admin"

    post "/users/signout"
    assert_equal "You have been signed out.", session[:message]

    get last_response["Location"]
    assert_nil session[:username]
    get last_response["Location"]
    assert_includes last_response.body, 'Sign In'
  end
end
