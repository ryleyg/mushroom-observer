ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

# Used to test image uploads.  params[:upload] is essentially a file with
# a "content_type" field added to it.
class FilePlus < File
  attr_accessor :content_type
  def size
    File.size(path)
  end
end

class Test::Unit::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = true

  # Add more helper methods to be used by all tests here...
end

def debug(a=nil, b=nil, c=nil, d=nil, e=nil, f=nil)
  @debug_file ||= File.new("debug.log", "w")
  first = true
  for x in [a, b, c, d, e, f]
    @debug_file.write(" ") if !first
    @debug_file.write(stringify(x))
    first = false
  end
end

def stringify(x)
  if x.class == Array
    y = x.map {|z| stringify(z)}
    return "[" + y.join(", ") + "]"
  elsif x.class == Hash
    str = ""
    for k, v in x
      str += ",\n" if str != ""
      str += k.to_s + " => " + v.stringify
    end
    return "{\n" + str + "\n}"
  else
    return x.to_s
  end
end

# The whole purpose of this is to create a directory full of sample HTML files
# that we can run the W3C validator on -- this has nothing to do with debugging!
def html_dump(label, html, params)
  html_dir = '../html'
  if File.directory?(html_dir) and html[0..11] != '<html><body>'
    file_name = "#{html_dir}/#{label}.html"
    count = 0
    while File.exists?(file_name)
      file_name = "#{html_dir}/#{label}_#{count}.html"
      count += 1
      if count > 100
        raise(RangeError, "More than 100 files found with a label of '#{label}'")
      end
    end
    print "Creating html_dump file: #{file_name}\n"
    file = File.new(file_name, "w")
    # show_params(file, params, "params")
    file.write(html)
    file.close
  end
end

def show_params(file, hash, prefix)
  if hash.is_a?(Hash)
    hash.each {|k,v| show_params(file, v, "#{prefix}[#{k.to_s}]")}
  else
    file.write("#{prefix} = [#{hash.to_s}]<br>\n")
  end
end

def get_with_dump(page, params={})
  get(page, params)
  html_dump(page, @response.body, params)
end

def post_with_dump(page, params={})
  post(page, params)
  html_dump(page, @response.body, params)
end

######################################

# Pages that require login
def login(user='rolf', password='testpassword')
  # get :news
  user = User.authenticate(user, password)
  assert(user)
  session[:user_id] = user.id
end

def logout
  session[:user_id] = nil
end

def requires_login(page, params={}, stay_on_page=true, user='rolf', password='testpassword')
  get(page, params) # Expect redirect
  assert_redirected_to(:controller => "account", :action => "login")
  user = User.authenticate(user, password)
  assert(user)
  session[:user_id] = user.id
  flash[:notice] = nil
  flash[:notice_level] = 0
  get_with_dump(page, params)
  if stay_on_page
    assert_response :success
    assert_template page.to_s
  end
end

def post_requires_login(page, params={}, stay_on_page=true, user='rolf', password='testpassword')
  post(page, params) # Expect redirect
  assert_redirected_to(:controller => "account", :action => "login")
  user = User.authenticate(user, password)
  assert(user)
  session[:user_id] = user.id
  flash[:notice] = nil
  flash[:notice_level] = 0
  post_with_dump(page, params)
  if stay_on_page
    assert_response :success
    assert_template page.to_s
  end
end

def requires_user(page, alt_page, params={}, stay_on_page=true, username='rolf', password='testpassword')
  alt_username = 'mary'
  if username == 'mary':
    alt_username = 'rolf'
  end
  get(page, params) # Expect redirect
  assert_redirected_to(:controller => "account", :action => "login")
  user = User.authenticate(alt_username, 'testpassword')
  assert(user)
  session[:user_id] = user.id
  get(page, params) # Expect redirect
  if alt_page.class == Array
    assert_redirected_to(:controller => alt_page[0], :action => alt_page[1])
  else
    assert_template alt_page.to_s
  end

  login username, password
  flash[:notice] = nil
  flash[:notice_level] = 0
  get_with_dump(page, params)
  if stay_on_page
    assert_response :success
    assert_template page.to_s
  end
end

def post_requires_user(page, alt_page, params={}, stay_on_page=true, username='rolf', password='testpassword')
  alt_username = 'mary'
  if username == 'mary':
    alt_username = 'rolf'
  end
  post(page, params) # Expect redirect
  assert_redirected_to(:controller => "account", :action => "login")
  user = User.authenticate(alt_username, 'testpassword')
  assert(user)
  session[:user_id] = user.id
  post(page, params) # Expect redirect
  if alt_page.class == Array
    assert_redirected_to(:controller => alt_page[0], :action => alt_page[1])
  else
    assert_template alt_page.to_s
  end

  login username, password
  flash[:notice] = nil
  flash[:notice_level] = 0
  post_with_dump(page, params)
  if stay_on_page
    assert_response :success
    assert_template page.to_s
  end
end

# Assert the existence of a given link in the response body, and check
# that it points to the right place.
def assert_link_in_html(label, url_opts, message = nil)
  clean_backtrace do
    url_opts[:only_path] = true if url_opts[:only_path].nil?
    url = URI.unescape(@controller.url_for(url_opts))
    # Find each occurrance of "label", then make sure it is inside a link...
    # i.e. that there is no </a> between it and the previous <a href="blah"> tag.
    found_it = false
    @response.body.gsub('&nbsp;',' ').split(label).each do |str|
      # Find the last <a> tag in the string preceding the label.
      atag = str[str.rindex("<a ")..-1]  
      if !atag.include?("</a>")
        if atag =~ /^<a href="([^"]*)"/
          url2 = URI.unescape($1).html_to_ascii
          if url == url2
            found_it = true
            break
          else
            assert_block(build_message(message, "Expected <?> link to point to <?>, instead it points to <?>", label, url, url2)) { false}
          end
        end
      end
    end
    if found_it
      assert_block("") { true } # to count the assertion
    else
      assert_block(build_message(message, "Expected HTML to contain link called <?>.", label)) { false}
    end
  end
end

# Assert that a form exists which posts to the given url.
def assert_form_action(url_opts, message = nil)
  clean_backtrace do
    url_opts[:only_path] = true if url_opts[:only_path].nil?
    url = URI.unescape(@controller.url_for(url_opts))
    # Find each occurrance of <form action="blah" method="post">.
    found_it = false
    found = {}
    @response.body.split("<form action").each do |str|
      if str =~ /^="([^"]*)" [^>]*method="post"/
        url2 = URI.unescape($1).gsub('&amp;', '&')
        if url == url2
          found_it = true
          break
        end
        found[url2] = 1
      end
    end
    if found_it
      assert_block("") { true } # to count the assertion
    elsif found.keys
      assert_block(build_message(message, "Expected HTML to contain form that posts to <?>, but only found these: <?>.", url, found.keys.sort.join(">, <"))) { false }
    else
      assert_block(build_message(message, "Expected HTML to contain form that posts to <?>, but found nothing at all.", url)) { false }
    end
  end
end

# Assert that a response body is same as contents of a given file.
# Pass in a block to use as a filter on both contents of response and file.
def assert_response_equal_file(file, &block)
  assert_string_equal_file(@response.body.clone, file, &block)
end

# Assert that a string is same as contents of a given file.
# Pass in a block to use as a filter on both contents of response and file.
def assert_string_equal_file(str, *files)
  result = false
  msg    = nil

  # Check string against each file, looking for at least one that matches.
  body1  = str
  body1  = yield(body1) if block_given?
  for file in files
    body2 = File.open(file) {|fh| fh.read}
    body2 = yield(body2) if block_given?
    if body1 == body2
      # Stop soon as we find one that matches.
      result = true
      break
    elsif !msg
      # Write out expected (old) and received (new) files for debugging purposes.
      File.open(file + '.old', 'w') {|fh| fh.write(body2)}
      File.open(file + '.new', 'w') {|fh| fh.write(body1)}
      msg = "File #{file} wrong:\n" + `diff #{file}.old #{file}.new`
      File.delete(file + '.old') if File.exists?(file + '.old')
    end
  end
  
  if result
    # Clean out old files from previous failure(s).
    for file in files
      File.delete(file + '.new') if File.exists?(file + '.new')
    end
  else
    assert(false, msg)
  end
end

# Test whether the n-1st queued email matches.  For example:
#   assert_email(0, {
#     :flavor  => 'comment',
#     :from    => @mary,
#     :to      => @rolf,
#     :comment => @comment_on_minmal_unknown.id
#   })
def assert_email(n, args)
  email = QueuedEmail.find(:first, :offset => n)
  assert(email)
  for arg in args.keys
    case arg
    when :flavor
      assert_equal(args[arg], email.flavor, "Flavor is wrong")
    when :from
      assert_equal(args[arg].id, email.user_id, "Sender is wrong")
    when :to
      assert_equal(args[arg].id, email.to_user_id, "Recipient is wrong")
    when :note
      assert_equal(args[arg], email.get_note, "Value of note is wrong")
    else
      assert_equal(args[arg], email.get_integer(arg) || email.get_string(arg), "Value of #{arg} is wrong")
    end
  end
end
