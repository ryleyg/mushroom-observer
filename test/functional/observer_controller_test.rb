require File.dirname(__FILE__) + '/../test_helper'
require 'observer_controller'
require 'fileutils'

class ObserverControllerTest < Test::Unit::TestCase
  fixtures :images
  fixtures :images_observations
  fixtures :licenses
  fixtures :locations
  fixtures :names
  fixtures :naming_reasons
  fixtures :namings
  fixtures :observations
  fixtures :users
  fixtures :votes

  def setup
    @controller = ObserverController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Test constructing observations in various ways (with minimal namings).
  def generic_construct_observation(params, o_num, g_num, n_num)
    o_count = Observation.all.length
    g_count = Naming.all.length
    n_count = Name.all.length
    score   = @rolf.reload.contribution

    params[:observation] = {
      :where          => 'right here',
      'when(1i)'      => '2007',
      'when(2i)'      => '10',
      'when(3i)'      => '31',
      :specimen       => '0',
      :thumb_image_id => '0',
    }.merge(params[:observation] || {})
    params[:vote] = {
      :value => '3',
    }.merge(params[:vote] || {})

    post_requires_login(:create_observation, params)
    if o_num == 1
      assert_response(:action => :show_observation)
    else
      assert_response(:success)
    end

    assert_equal(o_count + o_num, Observation.all.length)
    assert_equal(g_count + g_num, Naming.all.length)
    assert_equal(n_count + n_num, Name.all.length)
    assert_equal(score + o_num + 2*g_num + 10*n_num, @rolf.reload.contribution)
    if o_num == 1
      assert_not_equal(0, @controller.instance_variable_get('@observation').thumb_image_id)
    end
  end

################################################################################

  # ----------------------------
  #  General tests.
  # ----------------------------

  def test_page_loads
    local_fixtures :rss_logs

    get_with_dump(:index)
    assert_response(:list_rss_logs)
    assert_link_in_html(:app_intro.t, :action => 'intro')
    assert_link_in_html(:app_create_account.t, :controller => 'account',
                        :action => 'signup')

    get_with_dump(:ask_webmaster_question)
    assert_response(:ask_webmaster_question)
    assert_form_action(:action => 'ask_webmaster_question')

    get_with_dump(:color_themes)
    assert_response(:color_themes)
    for theme in CSS
      get_with_dump(theme)
      assert_response(theme)
    end

    get_with_dump(:how_to_help)
    assert_response(:how_to_help)

    get_with_dump(:how_to_use)
    assert_response(:how_to_use)

    get_with_dump(:intro)
    assert_response(:intro)

    get_with_dump(:list_observations)
    assert_response(:list_observations)

    get_with_dump(:list_rss_logs)
    assert_response(:list_rss_logs)

    get_with_dump(:news)
    assert_response(:news)

    get_with_dump(:observations_by_name)
    assert_response(:list_observations)

    get_with_dump(:rss)
    assert_response(:rss)

    get_with_dump(:show_rss_log, :id => 1)
    assert_response(:show_rss_log)

    get_with_dump(:users_by_contribution)
    assert_response(:users_by_contribution)

    get_with_dump(:show_user, :id => 1)
    assert_response(:show_user)

    get_with_dump(:show_site_stats)
    assert_response(:show_site_stats)

    get_with_dump(:show_user_observations, :id => 1)
    assert_response(:list_observations)

    get_with_dump(:login)
    assert_response(:controller => "account", :action => "login")
  end

  def test_prev_and_next_observation
    # Uses default observation query
    get_with_dump(:next_observation, :id => 2)
    id = SequenceState.last.id
    assert_redirected_to(:action => "show_observation", :id => 1,
                         :search_seq => nil, :seq_key => id)

    get_with_dump(:prev_observation, :id => 2)
    id = SequenceState.last.id
    assert_redirected_to(:action => "show_observation", :id => 3,
                         :search_seq => nil, :seq_key => id)
  end

  # Created in response to a performance problem seen in the wild
  def test_advanced_searches
    for (type, action, response) in [
      [ nil,           :advanced_obj_search,     :list_observations                ],
      [ "Image",       :advanced_search_results, [:image,    :advanced_obj_search] ],
      [ "Observation", :advanced_search_results, [:observer, :advanced_obj_search] ],
      [ "Description", :advanced_search_results, [:name,     :advanced_obj_search] ],
    ]
      get_with_dump(action,
        :search => {
          :name => "Don't know",
          :observer => "myself",
          :type => type,
          :content => "Long pink stem and small pink cap",
          :location => "Eastern Oklahoma"
        },
        :commit => "Search"
      )
      assert_response(response)
    end
  end

  def test_pattern_search
    params = {:commit => nil, :search => {:pattern => "12"}}
    get_with_dump(:pattern_search, params)
    assert_response(:controller => "observer", :action => "observation_search")
    assert_equal("12", @request.session[:pattern])

    params = {:commit => :app_images_find.l, :search => {:pattern => "34"}}
    get_with_dump(:pattern_search, params)
    assert_response(:controller => "image", :action => "image_search")
    assert_equal("34", @request.session[:pattern])

    params = {:commit => :app_names_find.l, :search => {:pattern => "56"}}
    get_with_dump(:pattern_search, params)
    assert_response(:controller => "name", :action => "name_search")
    assert_equal("56", @request.session[:pattern])

    params = {:commit => :app_locations_find.l, :search => {:pattern => "78"}}
    get_with_dump(:pattern_search, params)
    assert_response(:controller => "location", :action => "list_place_names",
                    :pattern => "78")
  end

  def test_observation_search
    @request.session[:pattern] = "12"
    get_with_dump(:observation_search)
    assert_response(:list_observations)
    assert_equal(:list_observations_matching.t(:pattern => '12'),
                 @controller.instance_variable_get('@title'))

    get_with_dump(:observation_search, :page => 2)
    assert_response(:list_observations)
    assert_equal(:list_observations_matching.t(:pattern => '12'),
                 @controller.instance_variable_get('@title'))
  end

  # Created in response to a bug seen in the wild
  def test_where_search_next_page
    @request.session[:where] = "Burbank"
    params = { :page => 2 }
    get_with_dump(:location_search, params)
    assert_response(:list_observations)
  end

  # Created in response to a bug seen in the wild
  def test_where_search_pattern
    params = { :pattern => "Burbank" }
    get_with_dump(:location_search, params)
    assert_response(:list_observations)
  end

  def test_send_webmaster_question
    params = {
      :user => { :email => "rolf@mushroomobserver.org" },
      :question => { :content => "Some content" },
    }
    post(:ask_webmaster_question, params)
    assert_response(:controller => "observer", :action => "list_rss_logs")

    flash[:notice] = nil
    params[:user][:email] = ''
    post(:ask_webmaster_question, params)
    assert_response(:success)
    assert_equal(:ask_webmaster_need_address.t, flash[:notice])

    flash[:notice] = nil
    params[:user][:email] = 'spammer'
    post(:ask_webmaster_question, params)
    assert_response(:success)
    assert_equal(:ask_webmaster_need_address.t, flash[:notice])

    flash[:notice] = nil
    params[:user][:email] = 'bogus@email.com'
    params[:question][:content] = ''
    post(:ask_webmaster_question, params)
    assert_response(:success)
    assert_equal(:ask_webmaster_need_content.t, flash[:notice])

    flash[:notice] = nil
    params[:question][:content] = "Buy <a href='http://junk'>Me!</a>"
    post(:ask_webmaster_question, params)
    assert_response(:success)
    assert_equal(:ask_webmaster_antispam.t, flash[:notice])
  end

  def test_show_observation
    get_with_dump(:show_observation, :id => @coprinus_comatus_obs.id)
    assert_response(:show_observation)
    obs = @coprinus_comatus_obs.id
    seq = SequenceState.last.id
    assert_form_action(:action => 'show_observation', :id => obs, :obs => obs,
                       :seq_key => seq)

    get_with_dump(:show_observation, :id => @unknown_with_no_naming.id)
    assert_response(:show_observation)
    obs = @unknown_with_no_naming.id
    seq = SequenceState.last.id
    assert_form_action(:action => 'show_observation', :id => obs, :obs => obs,
                       :seq_key => seq)

    # Test a naming owned by the observer but the observer has 'No Opinion'.
    # This is a regression test for a bug in _show_namings.rhtml
    # Ensure that rolf owns @obs_with_no_opinion.
    user = login('rolf')
    assert_equal(@strobilurus_diminutivus_obs.user, user)
    get_with_dump(:show_observation, :id => @strobilurus_diminutivus_obs.id)
    assert_response(:show_observation)
  end

  def test_show_user_no_id
    assert_raises(ActiveRecord::RecordNotFound, "Couldn't find User without an ID") do
      get_with_dump(:show_user)
    end
  end

  def test_ask_questions
    id = @coprinus_comatus_obs.id
    requires_login(:ask_observation_question, :id => id)
    assert_form_action(:action => 'send_observation_question', :id => id)

    id = @mary.id
    requires_login(:ask_user_question, :id => id)
    assert_form_action(:action => 'send_user_question', :id => id)

    id = @in_situ.id
    requires_login(:commercial_inquiry, :id => id)
    assert_form_action(:action => 'send_commercial_inquiry', :id => id)
  end

  def test_destroy_observation
    assert(obs = @minimal_unknown)
    id = obs.id
    params = { :id => id.to_s }
    assert_equal("mary", obs.user.login)
    requires_user(:destroy_observation, [:show_observation], params, 'mary')
    assert_response(:action => :list_observations)
    assert_raises(ActiveRecord::RecordNotFound) do
      obs = Observation.find(id)
    end
  end

  def test_some_admin_pages
    for (page, response, params) in [
      [ :users_by_name,      :users_by_name,   {} ],
      [ :email_features,     :email_features,  {} ],
      [ :send_feature_email, [:users_by_name], {:feature_email => {:content => 'test'}} ],
    ]
      logout
      get(page, params)
      assert_response(:controller => "account", :action => "login")

      login('rolf')
      get(page, params)
      assert_response(:action => "list_rss_logs")
      assert('', flash[:notice].to_s.match(/denied/))

      make_admin('rolf')
      get_with_dump(page, params)
      assert_response(response)
    end
  end

  def test_send_emails
    image = @commercial_inquiry_image
    params = {
      :id => image.id,
      :commercial_inquiry => {
        :content => "Testing commercial_inquiry"
      }
    }
    requires_login(:send_commercial_inquiry, params)
    assert_response(:controller => :image, :action => :show_image)

    obs = @minimal_unknown
    params = {
      :id => obs.id,
      :question => {
        :content => "Testing question"
      }
    }
    requires_login(:send_observation_question, params)
    assert_response(:action => :show_observation)
    assert_equal(:ask_observation_question_success.t, flash[:notice])

    user = @mary
    params = {
      :id => user.id,
      :email => {
        :subject => "Email subject",
        :content => "Email content"
      }
    }
    requires_login(:send_user_question, params)
    assert_response(:action => :show_user)
    assert_equal(:ask_user_question_success.t, flash[:notice])
  end

  def test_show_notifications
    local_fixtures :notifications

    # First, create a naming notification email, making sure it has a template,
    # and making sure the person requesting the notifcation is not the same
    # person who created the underlying observation (otherwise nothing happens).
    @coprinus_comatus_notification.user = @mary
    @coprinus_comatus_notification.note_template = 'blah!'
    assert(@coprinus_comatus_notification.save)
    QueuedEmail.queue_emails(true)
    QueuedEmail::Naming.create_email(@coprinus_comatus_notification, @coprinus_comatus_other_naming)

    # Now we can be sure show_notifications is supposed to actually show a
    # non-empty list, and thus that this test is meaningful.
    requires_login(:show_notifications, :id => @coprinus_comatus_obs)
    assert_response(:show_notifications)
  end

  # ------------------------------
  #  Test creating observations.
  # ------------------------------

  # Test "get" side of create_observation.
  def test_create_observation
    requires_login(:create_observation)
    assert_form_action(:action => 'create_observation', :approved_name => '')
  end

  def test_construct_observation
    local_fixtures :notifications

    # Test a simple observation creation with an approved unique name
    where = "test_construct_observation_simple"
    generic_construct_observation({
      :observation => { :where => where, :thumb_image_id => '0' },
      :name => { :name => "Coprinus comatus" }
    }, 1,1,0)
    obs = assigns(:observation)
    nam = assigns(:naming)
    assert_equal(where, obs.where)
    assert_equal(@coprinus_comatus.id, nam.name_id)
    assert_equal("2.03659", "%.5f" % obs.vote_cache)
    assert_not_nil(obs.rss_log)
    # This was getting set to zero instead of nil if no images were uploaded
    # when obs was created.
    assert_equal(nil, obs.thumb_image_id)

    # Test a simple observation creation of an unknown
    where = "test_construct_observation_unknown"
    generic_construct_observation({
      :observation => { :where => where },
      :name => { :name => "Unknown" }
    }, 1,0,0)
    obs = assigns(:observation)
    assert_equal(where, obs.where) # Make sure it's the right observation
    assert_not_nil(obs.rss_log)

    # Test an observation creation with a new name
    generic_construct_observation({
      :name => { :name => "New name" }
    }, 0,0,0)

    # Test an observation creation with an approved new name
    new_name = "Argus arg-arg"
    generic_construct_observation({
      :name => { :name => new_name },
      :approved_name => new_name
    }, 1,1,2)

    # Test an observation creation with an approved section (should fail)
    new_name = "Argus section Argus"
    generic_construct_observation({
      :name => { :name => new_name },
      :approved_name => new_name
    }, 0,0,0)

    # Test an observation creation with an approved junk name
    new_name = "This is a bunch of junk"
    generic_construct_observation({
      :name => { :name => new_name },
      :approved_name => new_name
    }, 0,0,0)

    # Test an observation creation with multiple matches
    generic_construct_observation({
      :name => { :name => "Amanita baccata" }
    }, 0,0,0)

    # Test an observation creation with one of the multiple matches chosen
    generic_construct_observation({
      :name => { :name => "Amanita baccata" },
      :chosen_name => { :name_id => @amanita_baccata_arora.id }
    }, 1,1,0)

    # Test an observation creation with one of the multiple matches chosen
    generic_construct_observation({
      :name => { :name => @pluteus_petasatus_deprecated.text_name }
    }, 1,1,0)
    nam = assigns(:naming)
    assert_equal(@pluteus_petasatus_approved.id, nam.name_id)

    # Test an observation creation with a deprecated name
    generic_construct_observation({
      :name => { :name => "Lactarius subalpinus" }
    }, 0,0,0)

    # Test an observation creation with a deprecated name, but a chosen approved alternative
    new_name = "Lactarius subalpinus"
    generic_construct_observation({
      :name => { :name => new_name },
      :approved_name => new_name,
      :chosen_name => { :name_id => @lactarius_alpinus.id }
    }, 1,1,0)
    nam = assigns(:naming)
    assert(nam.name, @lactarius_alpinus)

    # Test an observation creation with a deprecated name that has been approved
    new_name = "Lactarius subalpinus"
    generic_construct_observation({
      :name => { :name => new_name },
      :approved_name => new_name,
      :chosen_name => { }
    }, 1,1,0)
    nam = assigns(:naming)
    assert_equal(nam.name, @lactarius_subalpinus)

    # Test an observation creation with an approved new name
    new_name = "Agaricus novus"
    Name.find_by_text_name('Agaricus').destroy
    generic_construct_observation({
      :name => { :name => new_name },
      :approved_name => new_name
    }, 1,1,2)
    name = Name.find_by_text_name(new_name)
    assert(name)
    assert_equal(new_name, name.text_name)

    count_before = QueuedEmail.all.length
    name = @agaricus_campestris
    notifications = Notification.find_all_by_flavor_and_obj_id(:name, name.id)
    assert_equal(2, notifications.length)

    where = "test_construct_observation_simple"
    generic_construct_observation({
      :observation => { :where => where },
      :name => { :name => name.text_name }
    }, 1,1,0)
    obs = assigns(:observation)
    nam = assigns(:naming)
    assert_equal(where, obs.where) # Make sure it's the right observation
    assert_equal(name.id, nam.name_id) # Make sure it's the right name
    assert_not_nil(obs.rss_log)

    count_after = QueuedEmail.all.length
    assert_equal(count_before+2, count_after)
  end

  def test_name_resolution
    login('rolf')

    params = {
      :observation => {
        :when => Time.now,
        :where => 'somewhere',
        :specimen => '0',
        :thumb_image_id => '0',
      },
      :name => {},
      :vote => { :value => "3" },
    }

    # Can we create observation with existing genus?
    params[:name][:name] = 'Agaricus'
    params[:approved_name] = nil
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@agaricus.id, assigns(:observation).name_id)

    params[:name][:name] = 'Agaricus sp'
    params[:approved_name] = nil
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@agaricus.id, assigns(:observation).name_id)

    params[:name][:name] = 'Agaricus sp.'
    params[:approved_name] = nil
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@agaricus.id, assigns(:observation).name_id)

    # Can we create observation with genus and add author?
    params[:name][:name] = 'Agaricus Author'
    params[:approved_name] = 'Agaricus Author'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@agaricus.id, assigns(:observation).name_id)
    assert_equal('Agaricus sp. Author', @agaricus.reload.search_name)
    @agaricus.author = nil
    @agaricus.search_name = 'Agaricus sp.'
    @agaricus.save

    params[:name][:name] = 'Agaricus sp Author'
    params[:approved_name] = 'Agaricus sp Author'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@agaricus.id, assigns(:observation).name_id)
    assert_equal('Agaricus sp. Author', @agaricus.reload.search_name)
    @agaricus.author = nil
    @agaricus.search_name = 'Agaricus sp.'
    @agaricus.save

    params[:name][:name] = 'Agaricus sp. Author'
    params[:approved_name] = 'Agaricus sp. Author'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@agaricus.id, assigns(:observation).name_id)
    assert_equal('Agaricus sp. Author', @agaricus.reload.search_name)

    # Can we create observation with genus specifying author?
    params[:name][:name] = 'Agaricus Author'
    params[:approved_name] = nil
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@agaricus.id, assigns(:observation).name_id)

    params[:name][:name] = 'Agaricus sp Author'
    params[:approved_name] = nil
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@agaricus.id, assigns(:observation).name_id)

    params[:name][:name] = 'Agaricus sp. Author'
    params[:approved_name] = nil
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@agaricus.id, assigns(:observation).name_id)

    # Can we create observation with deprecated genus?
    params[:name][:name] = 'Psalliota'
    params[:approved_name] = 'Psalliota'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@psalliota.id, assigns(:observation).name_id)

    params[:name][:name] = 'Psalliota sp'
    params[:approved_name] = 'Psalliota sp'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@psalliota.id, assigns(:observation).name_id)

    params[:name][:name] = 'Psalliota sp.'
    params[:approved_name] = 'Psalliota sp.'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@psalliota.id, assigns(:observation).name_id)

    # Can we create observation with deprecated genus, adding author?
    params[:name][:name] = 'Psalliota Author'
    params[:approved_name] = 'Psalliota Author'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@psalliota.id, assigns(:observation).name_id)
    assert_equal('Psalliota sp. Author', @psalliota.reload.search_name)
    @psalliota.author = nil
    @psalliota.search_name = 'Psalliota sp.'
    @psalliota.save

    params[:name][:name] = 'Psalliota sp Author'
    params[:approved_name] = 'Psalliota sp Author'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@psalliota.id, assigns(:observation).name_id)
    assert_equal('Psalliota sp. Author', @psalliota.reload.search_name)
    @psalliota.author = nil
    @psalliota.search_name = 'Psalliota sp.'
    @psalliota.save

    params[:name][:name] = 'Psalliota sp. Author'
    params[:approved_name] = 'Psalliota sp. Author'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal(@psalliota.id, assigns(:observation).name_id)
    assert_equal('Psalliota sp. Author', @psalliota.reload.search_name)

    # Can we create new quoted genus?
    params[:name][:name] = '"One"'
    params[:approved_name] = '"One"'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal('"One"', assigns(:observation).name.text_name)
    assert_equal('"One" sp.', assigns(:observation).name.search_name)

    params[:name][:name] = '"Two" sp'
    params[:approved_name] = '"Two" sp'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal('"Two"', assigns(:observation).name.text_name)
    assert_equal('"Two" sp.', assigns(:observation).name.search_name)

    params[:name][:name] = '"Three" sp.'
    params[:approved_name] = '"Three" sp.'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal('"Three"', assigns(:observation).name.text_name)
    assert_equal('"Three" sp.', assigns(:observation).name.search_name)

    params[:name][:name] = '"One"'
    params[:approved_name] = nil
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal('"One"', assigns(:observation).name.text_name)

    params[:name][:name] = '"One" sp'
    params[:approved_name] = nil
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal('"One"', assigns(:observation).name.text_name)

    params[:name][:name] = '"One" sp.'
    params[:approved_name] = nil
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal('"One"', assigns(:observation).name.text_name)

    # Can we create species under the quoted genus?
    params[:name][:name] = '"One" foo'
    params[:approved_name] = '"One" foo'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal('"One" foo', assigns(:observation).name.text_name)

    params[:name][:name] = '"One" "bar"'
    params[:approved_name] = '"One" "bar"'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal('"One" "bar"', assigns(:observation).name.text_name)

    params[:name][:name] = '"One" Author'
    params[:approved_name] = '"One" Author'
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal('"One"', assigns(:observation).name.text_name)
    assert_equal('"One" sp. Author', assigns(:observation).name.search_name)

    params[:name][:name] = '"One" sp Author'
    params[:approved_name] = nil
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal('"One"', assigns(:observation).name.text_name)
    assert_equal('"One" sp. Author', assigns(:observation).name.search_name)

    params[:name][:name] = '"One" sp. Author'
    params[:approved_name] = nil
    post(:create_observation, params)
    assert_response(:action => "show_observation")
    assert_equal('"One"', assigns(:observation).name.text_name)
    assert_equal('"One" sp. Author', assigns(:observation).name.search_name)
  end

  # ----------------------------------------------------------------
  #  Test edit_observation and edit_naming, both "get" and "post".
  # ----------------------------------------------------------------

  # (Sorry, these used to all be edit/update_observation, now they're
  # confused because of the naming stuff.)
  def test_edit_observation
    obs = @coprinus_comatus_obs
    assert_equal("rolf", obs.user.login)
    params = { :id => obs.id.to_s }
    requires_user(:edit_observation, ["observer", "show_observation"], params)
    assert_form_action(:action => 'edit_observation')
  end

  def test_update_observation
    local_fixtures :rss_logs
    obs = @detailed_unknown
    modified = obs.rss_log.modified
    new_where = "test_update_observation"
    new_notes = "blather blather blather"
    new_specimen = false
    params = {
      :id => obs.id.to_s,
      :observation => {
        :where => new_where,
        "when(1i)" => "2001",
        "when(2i)" => "2",
        "when(3i)" => "3",
        :notes => new_notes,
        :specimen => new_specimen,
        :thumb_image_id => "0",
      },
      :log_change => { :checked => '1' }
    }
    post_requires_user(:edit_observation, ["observer", "show_observation"],
                       params, 'mary')
    assert_response(:action => :show_observation)
    assert_equal(10, @rolf.reload.contribution)
    obs = assigns(:observation)
    assert_equal(new_where, obs.where)
    assert_equal("2001-02-03", obs.when.to_s)
    assert_equal(new_notes, obs.notes)
    assert_equal(new_specimen, obs.specimen)
    assert_not_equal(modified, obs.rss_log.modified)
    assert_not_equal(0, obs.thumb_image_id)
  end

  def test_update_observation_no_logging
    local_fixtures :rss_logs
    obs = @detailed_unknown
    modified = obs.rss_log.modified
    where = "test_update_observation_no_logging"
    params = {
      :id => obs.id.to_s,
      :observation => {
        :where => where,
        :when => obs.when,
        :notes => obs.notes,
        :specimen => obs.specimen
      },
      :log_change => { :checked => '0' }
    }
    post_requires_user(:edit_observation, ["observer", "show_observation"],
                       params, 'mary')
    assert_response(:action => :show_observation)
    assert_equal(10, @rolf.reload.contribution)
    obs = assigns(:observation)
    assert_equal(where, obs.where)
    assert_equal(modified, obs.rss_log.modified)
  end

  # ----------------------------
  #  Test namings.
  # ----------------------------

  # Now test the naming part of it.
  def test_create_naming_get
    obs = @coprinus_comatus_obs
    params = {
      :id => obs.id.to_s
    }
    requires_login(:create_naming, params)
    assert_form_action(:action => 'create_naming', :approved_name => '')
  end

  # Now test the naming part of it.
  def test_edit_naming_get
    nam = @coprinus_comatus_naming
    params = {
      :id => nam.id.to_s
    }
    requires_user(:edit_naming, ["observer", "show_observation"], params)
    assert_form_action(:action => 'edit_naming', :approved_name => nam.text_name)
  end

  def test_update_observation_new_name
    login('rolf')
    nam = @coprinus_comatus_naming
    old_name = nam.text_name
    new_name = "Easter bunny"
    params = {
      :id => nam.id.to_s,
      :name => { :name => new_name }
    }
    post(:edit_naming, params)
    assert_response(:edit_naming)
    assert_equal(10, @rolf.reload.contribution)
    obs = assigns(:naming)
    assert_not_equal(new_name, nam.text_name)
    assert_equal(old_name, nam.text_name)
  end

  def test_update_observation_approved_new_name
    login('rolf')
    nam = @coprinus_comatus_naming
    old_name = nam.text_name
    new_name = "Easter bunny"
    params = {
      :id => nam.id.to_s,
      :name => { :name => new_name },
      :approved_name => new_name,
      :vote => { :value => 1 }
    }
    post(:edit_naming, params)
    assert_response(:action => :show_observation)
    # Clones naming, creates Easter sp and E. bunny, but no votes.
    assert_equal(32, @rolf.reload.contribution)
    nam = assigns(:naming)
    assert_equal(new_name, nam.text_name)
    assert_not_equal(old_name, nam.text_name)
    assert(!nam.name.deprecated)
  end

  def test_update_observation_multiple_match
    login('rolf')
    nam = @coprinus_comatus_naming
    old_name = nam.text_name
    new_name = "Amanita baccata"
    params = {
      :id => nam.id.to_s,
      :name => { :name => new_name }
    }
    post(:edit_naming, params)
    assert_response(:edit_naming)
    assert_equal(10, @rolf.reload.contribution)
    nam = assigns(:naming)
    assert_not_equal(new_name, nam.text_name)
    assert_equal(old_name, nam.text_name)
  end

  def test_update_observation_chosen_multiple_match
    login('rolf')
    nam = @coprinus_comatus_naming
    old_name = nam.text_name
    new_name = "Amanita baccata"
    params = {
      :id => nam.id.to_s,
      :name => { :name => new_name },
      :chosen_name => { :name_id => @amanita_baccata_arora.id },
      :vote => { :value => 1 }
    }
    post(:edit_naming, params)
    assert_response(:action => :show_observation)
    # Must be cloning naming with no vote.
    assert_equal(12, @rolf.reload.contribution)
    nam = assigns(:naming)
    assert_equal(new_name, nam.name.text_name)
    assert_equal(new_name + " sensu Arora", nam.text_name)
    assert_not_equal(old_name, nam.text_name)
  end

  def test_update_observation_deprecated
    login('rolf')
    nam = @coprinus_comatus_naming
    old_name = nam.text_name
    new_name = "Lactarius subalpinus"
    params = {
      :id => nam.id.to_s,
      :name => { :name => new_name }
    }
    post(:edit_naming, params)
    assert_response(:edit_naming)
    assert_equal(10, @rolf.reload.contribution)
    nam = assigns(:naming)
    assert_not_equal(new_name, nam.text_name)
    assert_equal(old_name, nam.text_name)
  end

  def test_update_observation_chosen_deprecated
    login('rolf')
    nam = @coprinus_comatus_naming
    start_name = nam.name
    new_name = "Lactarius subalpinus"
    chosen_name = @lactarius_alpinus
    params = {
      :id => nam.id.to_s,
      :name => { :name => new_name },
      :approved_name => new_name,
      :chosen_name => { :name_id => chosen_name.id },
      :vote => { :value => 1 }
    }
    post(:edit_naming, params)
    assert_response(:action => :show_observation)
    # Must be cloning naming, with no vote.
    assert_equal(12, @rolf.reload.contribution)
    nam = assigns(:naming)
    assert_not_equal(start_name.id, nam.name_id)
    assert_equal(chosen_name.id, nam.name_id)
  end

  def test_update_observation_accepted_deprecated
    login('rolf')
    nam = @coprinus_comatus_naming
    start_name = nam.name
    new_text_name = @lactarius_subalpinus.text_name
    params = {
      :id => nam.id.to_s,
      :name => { :name => new_text_name },
      :approved_name => new_text_name,
      :chosen_name => { },
      :vote => { :value => 3 },
    }
    post(:edit_naming, params)
    assert_response(:action => :show_observation)
    # Must be cloning the naming, but no votes?
    assert_equal(12, @rolf.reload.contribution)
    nam = assigns(:naming)
    assert_not_equal(start_name.id, nam.name_id)
    assert_equal(new_text_name, nam.name.text_name)
  end

  # ------------------------------------------------------------
  #  Test proposing new names, casting and changing votes, and
  #  setting and changing preferred_namings.
  # ------------------------------------------------------------

  # This is the standard case, nothing unusual or stressful here.
  def test_propose_naming
    o_count = Observation.all.length
    g_count = Naming.all.length
    n_count = Name.all.length
    v_count = Vote.all.length
    nr_count = NamingReason.all.length

    # Make a few assertions up front to make sure fixtures are as expected.
    assert_equal(@coprinus_comatus.id, @coprinus_comatus_obs.name_id)
    assert(@coprinus_comatus_naming.user_voted?(@rolf))
    assert(@coprinus_comatus_naming.user_voted?(@mary))
    assert(!@coprinus_comatus_naming.user_voted?(@dick))
    assert(@coprinus_comatus_other_naming.user_voted?(@rolf))
    assert(@coprinus_comatus_other_naming.user_voted?(@mary))
    assert(!@coprinus_comatus_other_naming.user_voted?(@dick))

    # Rolf, the owner of @coprinus_comatus_obs, already has a naming, which
    # he's 80% sure of.  Create a new one (the genus Agaricus) that he's 100%
    # sure of.  (Mary also has a naming with two votes.)
    params = {
      :id => @coprinus_comatus_obs.id,
      :name => { :name => "Agaricus" },
      :vote => { :value => "3" },
      :reason => {
        "1" => { :check => "1", :notes => "Looks good to me." },
        "2" => { :check => "1", :notes => "" },
        "3" => { :check => "0", :notes => "Spore texture." },
        "4" => { :check => "0", :notes => "" }
      }
    }
    login('rolf')
    post(:create_naming, params)
    assert_response(:redirect)

    # Make sure the right number of objects were created.
    assert_equal(o_count + 0, Observation.all.length)
    assert_equal(g_count + 1, Naming.all.length)
    assert_equal(n_count + 0, Name.all.length)
    assert_equal(v_count + 1, Vote.all.length)
    assert_equal(nr_count + 3, NamingReason.all.length)

    # Make sure contribution is updated correctly.
    assert_equal(12, @rolf.reload.contribution)

    # Make sure everything I need is reloaded.
    @coprinus_comatus_obs.reload

    # Get new objects.
    naming = Naming.last
    vote = Vote.last

    # Make sure observation was updated and referenced correctly.
    assert_equal(3, @coprinus_comatus_obs.namings.length)
    assert_equal(@agaricus.id, @coprinus_comatus_obs.name_id)

    # Make sure naming was created correctly and referenced.
    assert_equal(@coprinus_comatus_obs, naming.observation)
    assert_equal(@agaricus.id, naming.name_id)
    assert_equal(@rolf, naming.user)
    assert_equal(3, naming.naming_reasons.length)
    assert_equal(1, naming.votes.length)

    # Make sure vote was created correctly.
    assert_equal(naming, vote.naming)
    assert_equal(@rolf, vote.user)
    assert_equal(3, vote.value)

    # Make sure reasons were created correctly.
    nr1 = naming.naming_reasons[0]
    nr2 = naming.naming_reasons[1]
    nr3 = naming.naming_reasons[2]
    nr4 = NamingReason.new
    assert_equal(naming, nr1.naming)
    assert_equal(naming, nr2.naming)
    assert_equal(naming, nr3.naming)
    assert_equal(1, nr1.reason)
    assert_equal(2, nr2.reason)
    assert_equal(3, nr3.reason)
    assert_equal("Looks good to me.", nr1.notes)
    assert_equal("", nr2.notes)
    assert_equal("Spore texture.", nr3.notes)
    assert(nr1.check)
    assert(nr2.check)
    assert(nr3.check)
    assert(!nr4.check)

    # Make sure a few random methods work right, too.
    assert_equal(3, naming.vote_sum)
    assert_equal(vote, naming.users_vote(@rolf))
    assert(naming.user_voted?(@rolf))
    assert(!naming.user_voted?(@mary))
  end

  # Now see what happens when rolf's new naming is less confident than old.
  def test_propose_uncertain_naming
    g_count = Naming.all.length
    params = {
      :id => @coprinus_comatus_obs.id,
      :name => { :name => "Agaricus" },
      :vote => { :value => "-1" },
    }
    login('rolf')
    post(:create_naming, params)
    assert_response(:redirect)
    assert_equal(12, @rolf.reload.contribution)

    # Make sure everything I need is reloaded.
    @coprinus_comatus_obs.reload
    @coprinus_comatus_naming.reload

    # Get new objects.
    naming = Naming.last

    # Make sure observation was updated right.
    assert_equal(@coprinus_comatus.id, @coprinus_comatus_obs.name_id)

    # Sure, check the votes, too, while we're at it.
    assert_equal(3, @coprinus_comatus_naming.vote_sum) # 2+1 = 3
  end

  # Now see what happens when a third party proposes a name, and it wins.
  def test_propose_dicks_naming
    o_count = Observation.all.length
    g_count = Naming.all.length
    n_count = Name.all.length
    v_count = Vote.all.length
    nr_count = NamingReason.all.length

    # Dick proposes "Conocybe filaris" out of the blue.
    params = {
      :id => @coprinus_comatus_obs.id,
      :name => { :name => "Conocybe filaris" },
      :vote => { :value => "3" },
    }
    login("dick")
    post(:create_naming, params)
    assert_response(:redirect)
    assert_equal(12, @dick.reload.contribution)
    naming = Naming.last

    # Make sure the right number of objects were created.
    assert_equal(o_count + 0, Observation.all.length)
    assert_equal(g_count + 1, Naming.all.length)
    assert_equal(n_count + 0, Name.all.length)
    assert_equal(v_count + 1, Vote.all.length)
    assert_equal(nr_count + 1, NamingReason.all.length)

    # Make sure everything I need is reloaded.
    @coprinus_comatus_obs.reload
    @coprinus_comatus_naming.reload
    @coprinus_comatus_other_naming.reload

    # Check votes.
    assert_equal(3, @coprinus_comatus_naming.vote_sum)
    assert_equal(0, @coprinus_comatus_other_naming.vote_sum)
    assert_equal(3, naming.vote_sum)
    assert_equal(2, @coprinus_comatus_naming.votes.length)
    assert_equal(2, @coprinus_comatus_other_naming.votes.length)
    assert_equal(1, naming.votes.length)

    # Make sure observation was updated right.
    assert_equal(@conocybe_filaris.id, @coprinus_comatus_obs.name_id)
  end

  # Test a bug in name resolution: was failing to recognize that
  # "Genus species (With) Author" was recognized even if "Genus species"
  # was already in the database.
  def test_create_naming_with_author_when_name_without_author_already_exists
    params = {
      :id => @coprinus_comatus_obs.id,
      :name => { :name => "Conocybe filaris (With) Author" },
      :vote => { :value => "3" },
    }
    login("dick")
    post(:create_naming, params)
    assert_response(:action => "show_observation", :id => @coprinus_comatus_obs.id)
    # Dick is being added as an editor on Conocybe filaris.
    assert_equal(22, @dick.reload.contribution)
    naming = Naming.last
    assert_equal("Conocybe filaris", naming.name.text_name)
    assert_equal("(With) Author", naming.name.author)
    assert_equal(@conocybe_filaris.id, naming.name_id)
  end

  # Test a bug in name resolution: was failing to recognize that
  # "Genus species (With) Author" was recognized even if "Genus species"
  # was already in the database.
  def test_create_naming_fill_in_author
    params = {
      :id => @coprinus_comatus_obs.id,
      :name => { :name => 'Agaricus campestris' },
    }
    login("dick")
    post(:create_naming, params)
    assert_response(:success) # really means failed
    assert_equal('Agaricus campestris L.', @controller.instance_variable_get('@what'))
  end

  # Test a bug in name resolution: was failing to recognize that
  # "Genus species (With) Author" was recognized even if "Genus species"
  # was already in the database.
  def test_create_name_with_quotes
    name = 'Foo "bar" Author'
    params = {
      :id => @coprinus_comatus_obs.id,
      :name => { :name => name },
      :approved_name => name
    }
    login("dick")
    post(:create_naming, params)
    assert_response(:success) # really means failed
    assert(name = Name.find_by_text_name('Foo "bar"'))
    assert_equal('Foo "bar" Author', name.search_name)
  end

  # ----------------------------
  #  Test voting.
  # ----------------------------

  # Now have Dick vote on Mary's name.
  # Votes: rolf=2/-3, mary=1/3, dick=-1/3
  # Rolf prefers naming 3 (vote 2 -vs- -3).
  # Mary prefers naming 9 (vote 1 -vs- 3).
  # Dick now prefers naming 9 (vote 3).
  # Summing, 3 gets 2+1/3=1, 9 gets -3+3+3/4=.75, so 3 gets it.
  def test_cast_vote_dick
    login('dick')
    post(:cast_vote, :vote => {
      :value     => "3",
      :naming_id => @coprinus_comatus_other_naming.id
    })
    assert_equal(11, @dick.reload.contribution)

    # Make sure everything I need is reloaded.
    @coprinus_comatus_obs.reload
    @coprinus_comatus_naming.reload
    @coprinus_comatus_other_naming.reload

    # Check votes.
    assert_equal(3, @coprinus_comatus_naming.vote_sum)
    assert_equal(2, @coprinus_comatus_naming.votes.length)
    assert_equal(3, @coprinus_comatus_other_naming.vote_sum)
    assert_equal(3, @coprinus_comatus_other_naming.votes.length)

    # Make sure observation was updated right.
    assert_equal(@coprinus_comatus.id, @coprinus_comatus_obs.name_id)

    # If Dick votes on the other as well, then his first vote should
    # get demoted and his preference should change.
    # Summing, 3 gets 2+1+3/4=1.5, 9 gets -3+3+2/4=.5, so 3 keeps it.
    @coprinus_comatus_naming.change_vote(@dick, 3)
    assert_equal(12, @dick.reload.contribution)
    @coprinus_comatus_obs.reload
    @coprinus_comatus_naming.reload
    @coprinus_comatus_other_naming.reload
    assert_equal(3, @coprinus_comatus_naming.users_vote(@dick).value)
    assert_equal(6, @coprinus_comatus_naming.vote_sum)
    assert_equal(3, @coprinus_comatus_naming.votes.length)
    assert_equal(2, @coprinus_comatus_other_naming.users_vote(@dick).value)
    assert_equal(2, @coprinus_comatus_other_naming.vote_sum)
    assert_equal(3, @coprinus_comatus_other_naming.votes.length)
    assert_equal(@coprinus_comatus.id, @coprinus_comatus_obs.name_id)
  end

  # Now have Rolf change his vote on his own naming. (no change in prefs)
  # Votes: rolf=3->2/-3, mary=1/3, dick=x/x
  def test_cast_vote_rolf_change
    login('rolf')
    post(:cast_vote, :vote => {
      :value     => "2",
      :naming_id => @coprinus_comatus_naming.id
    })
    assert_equal(10, @rolf.reload.contribution)

    # Make sure everything I need is reloaded.
    @coprinus_comatus_obs.reload
    @coprinus_comatus_naming.reload
    @coprinus_comatus_other_naming.reload

    # Make sure observation was updated right.
    assert_equal(@coprinus_comatus.id, @coprinus_comatus_obs.name_id)

    # Check vote.
    assert_equal(3, @coprinus_comatus_naming.vote_sum)
    assert_equal(2, @coprinus_comatus_naming.votes.length)
  end

  # Now have Rolf increase his vote for Mary's. (changes consensus)
  # Votes: rolf=2/-3->3, mary=1/3, dick=x/x
  def test_cast_vote_rolf_second_greater
    login('rolf')
    post(:cast_vote, :vote => {
      :value     => "3",
      :naming_id => @coprinus_comatus_other_naming.id
    })
    assert_equal(10, @rolf.reload.contribution)

    # Make sure everything I need is reloaded.
    @coprinus_comatus_obs.reload
    @coprinus_comatus_naming.reload
    @coprinus_comatus_other_naming.reload

    # Make sure observation was updated right.
    assert_equal(@agaricus_campestris.id, @coprinus_comatus_obs.name_id)

    # Check vote.
    @coprinus_comatus_other_naming.reload
    assert_equal(6, @coprinus_comatus_other_naming.vote_sum)
    assert_equal(2, @coprinus_comatus_other_naming.votes.length)
  end

  # Now have Rolf increase his vote for Mary's insufficiently. (no change)
  # Votes: rolf=2/-3->-1, mary=1/3, dick=x/x
  # Summing, 3 gets 2+1=3, 9 gets -1+3=2, so 3 keeps it.
  def test_cast_vote_rolf_second_lesser
    login('rolf')
    post(:cast_vote, :vote => {
      :value     => "-1",
      :naming_id => @coprinus_comatus_other_naming.id
    })
    assert_equal(10, @rolf.reload.contribution)

    # Make sure everything I need is reloaded.
    @coprinus_comatus_obs.reload
    @coprinus_comatus_naming.reload
    @coprinus_comatus_other_naming.reload

    # Make sure observation was updated right.
    assert_equal(@coprinus_comatus.id, @coprinus_comatus_obs.name_id)

    # Check vote.
    assert_equal(3, @coprinus_comatus_naming.vote_sum)
    assert_equal(2, @coprinus_comatus_other_naming.vote_sum)
    assert_equal(2, @coprinus_comatus_other_naming.votes.length)
  end

  # Now, have Mary delete her vote against Rolf's naming.  This NO LONGER has the effect
  # of excluding Rolf's naming from the consensus calculation due to too few votes.
  # (Have Dick vote first... I forget what this was supposed to test for, but it's clearly
  # superfluous now).
  # Votes: rolf=2/-3, mary=1->x/3, dick=x/x->3
  # Summing after Dick votes,   3 gets 2+1/3=1, 9 gets -3+3+3/4=.75, 3 keeps it.
  # Summing after Mary deletes, 3 gets 2/2=1,   9 gets -3+3+3/4=.75, 3 still keeps it in this voting algorithm, arg.
  def test_cast_vote_mary
    login('dick')
    @coprinus_comatus_other_naming.change_vote(@dick, 3)
    assert_equal(@coprinus_comatus.id, @coprinus_comatus_obs.name_id)
    assert_equal(11, @dick.reload.contribution)

    login('mary')
    post(:cast_vote, :vote => {
      :value     => Vote.delete_vote,
      :naming_id => @coprinus_comatus_naming.id
    })
    assert_equal(9, @mary.reload.contribution)

    # Make sure everything I need is reloaded.
    @coprinus_comatus_obs.reload
    @coprinus_comatus_naming.reload
    @coprinus_comatus_other_naming.reload

    # Check votes.
    assert_equal(2, @coprinus_comatus_naming.vote_sum)
    assert_equal(1, @coprinus_comatus_naming.votes.length)
    assert_equal(3, @coprinus_comatus_other_naming.vote_sum)
    assert_equal(3, @coprinus_comatus_other_naming.votes.length)

    # Make sure observation is changed correctly.
    assert_equal(@coprinus_comatus.id, @coprinus_comatus_obs.name_id)
  end

  # Rolf can destroy his naming if Mary deletes her vote on it.
  def test_rolf_destroy_rolfs_naming
    # First delete Mary's vote for it.
    login('mary')
    @coprinus_comatus_naming.change_vote(@mary, Vote.delete_vote)
    assert_equal(9, @mary.reload.contribution)

    old_naming_id = @coprinus_comatus_naming.id
    old_vote1_id = @coprinus_comatus_owner_vote.id
    old_vote2_id = @coprinus_comatus_other_vote.id
    old_naming_reason_id = @cc_macro_reason.id

    login('rolf')
    get(:destroy_naming, :id => @coprinus_comatus_naming.id)

    # Make sure everything I need is reloaded.
    @coprinus_comatus_obs.reload
    @coprinus_comatus_other_naming.reload

    # Make sure naming and associated vote and reason were actually destroyed.
    assert_raises(ActiveRecord::RecordNotFound) do
      Naming.find(old_naming_id)
    end
    assert_raises(ActiveRecord::RecordNotFound) do
      Vote.find(old_vote1_id)
    end
    assert_raises(ActiveRecord::RecordNotFound) do
      Vote.find(old_vote2_id)
    end
    assert_raises(ActiveRecord::RecordNotFound) do
      NamingReason.find(old_naming_reason_id)
    end

    # Make sure observation was updated right.
    assert_equal(@agaricus_campestris.id, @coprinus_comatus_obs.name_id)

    # Check votes. (should be no change)
    assert_equal(0, @coprinus_comatus_other_naming.vote_sum)
    assert_equal(2, @coprinus_comatus_other_naming.votes.length)
  end

  # Make sure Rolf can't destroy his naming if Dick prefers it.
  def test_rolf_destroy_rolfs_naming_when_dick_prefers_it
    old_naming_id = @coprinus_comatus_naming.id
    old_vote1_id = @coprinus_comatus_owner_vote.id
    old_vote2_id = @coprinus_comatus_other_vote.id
    old_naming_reason_id = @cc_macro_reason.id

    # Make Dick prefer it.
    login('dick')
    @coprinus_comatus_naming.change_vote(@dick, 3)
    assert_equal(11, @dick.reload.contribution)

    # Have Rolf try to destroy it.
    login('rolf')
    get(:destroy_naming, :id => @coprinus_comatus_naming.id)

    # Make sure naming and associated vote and reason are still there.
    assert(Naming.find(old_naming_id))
    assert(Vote.find(old_vote1_id))
    assert(Vote.find(old_vote2_id))
    assert(NamingReason.find(old_naming_reason_id))

    # Make sure observation is unchanged.
    assert_equal(@coprinus_comatus.id, @coprinus_comatus_obs.name_id)

    # Check votes are unchanged.
    assert_equal(6, @coprinus_comatus_naming.vote_sum)
    assert_equal(3, @coprinus_comatus_naming.votes.length)
    assert_equal(0, @coprinus_comatus_other_naming.vote_sum)
    assert_equal(2, @coprinus_comatus_other_naming.votes.length)
  end

  # Rolf makes changes to vote and reasons of his naming.  Shouldn't matter
  # whether Mary has voted on it.
  def test_edit_naming_thats_being_used_just_change_reasons
    o_count = Observation.all.length
    g_count = Naming.all.length
    n_count = Name.all.length
    v_count = Vote.all.length
    nr_count = NamingReason.all.length

    # Rolf makes superficial changes to his naming.
    login('rolf')
    post(:edit_naming,
      :id => @coprinus_comatus_naming.id,
      :name => { :name => @coprinus_comatus.search_name },
      :vote => { :value => "3" },
      :reason => {
        "1" => { :check => "1", :notes => "Change to macro notes." },
        "2" => { :check => "1", :notes => "" },
        "3" => { :check => "0", :notes => "Add some micro notes." },
        "4" => { :check => "0", :notes => "" }
      }
    )
    assert_equal(10, @rolf.reload.contribution)

    # Make sure the right number of objects were created.
    assert_equal(o_count + 0, Observation.all.length)
    assert_equal(g_count + 0, Naming.all.length)
    assert_equal(n_count + 0, Name.all.length)
    assert_equal(v_count + 0, Vote.all.length)
    assert_equal(nr_count + 2, NamingReason.all.length)

    # Make sure everything I need is reloaded.
    @coprinus_comatus_obs.reload
    @coprinus_comatus_naming.reload
    @coprinus_comatus_owner_vote.reload

    # Make sure observation is unchanged.
    assert_equal(@coprinus_comatus.id, @coprinus_comatus_obs.name_id)

    # Check votes.
    assert_equal(4, @coprinus_comatus_naming.vote_sum) # 2+1 -> 3+1
    assert_equal(2, @coprinus_comatus_naming.votes.length)

    # Check new reasons.
    assert_equal(3, @coprinus_comatus_naming.naming_reasons.length)
    nr1 = @coprinus_comatus_naming.naming_reasons[0]
    nr2 = @coprinus_comatus_naming.naming_reasons[1]
    nr3 = @coprinus_comatus_naming.naming_reasons[2]
    assert_equal(1, nr1.reason)
    assert_equal(2, nr2.reason)
    assert_equal(3, nr3.reason)
    assert_equal("Change to macro notes.", nr1.notes)
    assert_equal("", nr2.notes)
    assert_equal("Add some micro notes.", nr3.notes)
  end

  # Rolf makes changes to name of his naming.  Shouldn't be allowed to do this
  # if Mary has voted on it.  Should clone naming, vote, and reasons.
  def test_edit_naming_thats_being_used_change_name
    o_count = Observation.all.length
    g_count = Naming.all.length
    n_count = Name.all.length
    v_count = Vote.all.length
    nr_count = NamingReason.all.length

    # Now, Rolf makes name change to his naming (leave rest the same).
    login('rolf')
    post(:edit_naming,
      :id => @coprinus_comatus_naming.id,
      :name => { :name => "Conocybe filaris" },
      :vote => { :value => "2" },
      :reason => {
        "1" => { :check => "1", :notes => "Isn't it obvious?" },
        "2" => { :check => "0", :notes => "" },
        "3" => { :check => "0", :notes => "" },
        "4" => { :check => "0", :notes => "" }
      }
    )
    assert_equal(12, @rolf.reload.contribution)

    # Make sure the right number of objects were created.
    assert_equal(o_count + 0, Observation.all.length)
    assert_equal(g_count + 1, Naming.all.length)
    assert_equal(n_count + 0, Name.all.length)
    assert_equal(v_count + 1, Vote.all.length)
    assert_equal(nr_count + 1, NamingReason.all.length)

    # Get new objects.
    naming = Naming.last
    vote = Vote.last
    nr = NamingReason.last

    # Make sure everything I need is reloaded.
    @coprinus_comatus_obs.reload
    @coprinus_comatus_naming.reload
    @coprinus_comatus_owner_vote.reload

    # Make sure observation is unchanged.
    assert_equal(@conocybe_filaris.id, @coprinus_comatus_obs.name_id)

    # Make sure old naming is unchanged.
    assert_equal(@coprinus_comatus.id, @coprinus_comatus_naming.name_id)
    assert_equal(1, @coprinus_comatus_naming.naming_reasons.length)
    assert_equal(@cc_macro_reason, @coprinus_comatus_naming.naming_reasons.first)
    assert_equal(3, @coprinus_comatus_naming.vote_sum)
    assert_equal(2, @coprinus_comatus_naming.votes.length)

    # Check new naming.
    assert_equal(@coprinus_comatus_obs, naming.observation)
    assert_equal(@conocybe_filaris.id, naming.name_id)
    assert_equal(@rolf, naming.user)
    assert_equal(1, naming.naming_reasons.length)
    assert_equal(nr, naming.naming_reasons.first)
    assert_equal(@cc_macro_reason.reason, nr.reason)
    assert_equal(@cc_macro_reason.notes, nr.notes)
    assert_equal(2, naming.vote_sum)
    assert_equal(1, naming.votes.length)
    assert_equal(vote, naming.votes.first)
    assert_equal(2, vote.value)
    assert_equal(@rolf, vote.user)
  end

  def test_show_votes
    # First just make sure the page displays.
    get_with_dump(:show_votes, :id => @coprinus_comatus_naming.id)
    assert_response(:show_votes)

    # Now try to make somewhat sure the content is right.
    table = @coprinus_comatus_naming.calc_vote_table
    str1 = Vote.agreement(@coprinus_comatus_owner_vote.value)
    str2 = Vote.agreement(@coprinus_comatus_other_vote.value)
    for str in table.keys
      if str == str1 && str1 == str2
        assert_equal(2, table[str][:num])
      elsif str == str1
        assert_equal(1, table[str][:num])
      elsif str == str2
        assert_equal(1, table[str][:num])
      else
        assert_equal(0, table[str][:num])
      end
    end
  end

  # -----------------------------------
  #  Test extended observation forms.
  # -----------------------------------

  def test_javascripty_name_reasons
    login('rolf')

    # If javascript isn't enabled, then checkbox isn't required.
    post(:create_observation,
      :observation => { :where => 'where', :when => Time.now },
      :name => { :name => @coprinus_comatus.text_name },
      :vote => { :value => 3 },
      :reason => {
        "1" => { :check => '0', :notes => ''    },
        "2" => { :check => '0', :notes => 'foo' },
        "3" => { :check => '1', :notes => ''    },
        "4" => { :check => '1', :notes => 'bar' }
      }
    )
    assert_response(:redirect) # redirected = successfully created
    naming = Naming.find(assigns(:naming).id)
    reasons = naming.naming_reasons.map(&:reason).sort
    assert_equal([2,3,4], reasons)

    # If javascript IS enabled, then checkbox IS required.
    post(:create_observation,
      :observation => { :where => 'where', :when => Time.now },
      :name => { :name => @coprinus_comatus.text_name },
      :vote => { :value => 3 },
      :reason => {
        "1" => { :check => '0', :notes => ''    },
        "2" => { :check => '0', :notes => 'foo' },
        "3" => { :check => '1', :notes => ''    },
        "4" => { :check => '1', :notes => 'bar' }
      },
      :was_js_on => 'yes'
    )
    assert_response(:redirect) # redirected = successfully created
    naming = Naming.find(assigns(:naming).id)
    reasons = naming.naming_reasons.map(&:reason).sort
    assert_equal([3,4], reasons)
  end

  def test_create_with_image_upload
    login('rolf')

    time0 = Time.utc(2000)
    time1 = Time.utc(2001)
    time2 = Time.utc(2002)
    time3 = Time.utc(2003)
    now   = 1.week.ago

    FileUtils.cp_r(IMG_DIR.gsub(/test_images$/, 'setup_images'), IMG_DIR)
    file = "#{RAILS_ROOT}/test/fixtures/images/Coprinus_comatus.jpg"
    file1 = FilePlus.new(file)
    file1.content_type = 'image/jpeg'
    file2 = FilePlus.new(file)
    file2.content_type = 'image/jpeg'
    file3 = FilePlus.new(file)
    file3.content_type = 'image/jpeg'

    new_image_1 = Image.create(
      :copyright_holder => 'holder_1',
      :when => time1,
      :notes => 'notes_1',
      :user_id => 1,
      :image => file1,
      :content_type => 'image/jpeg',
      :created => now,
      :modified => now
    )

    new_image_2 = Image.create(
      :copyright_holder => 'holder_2',
      :when => time2,
      :notes => 'notes_2',
      :user_id => 2,
      :image => file2,
      :content_type => 'image/jpeg',
      :created => now,
      :modified => now
    )

    post(:create_observation,
      :observation => {
        :where => 'zzyzx',
        :when => time0,
        :thumb_image_id => 0,   # (make new image the thumbnail)
        :notes => 'blah',
      },
      :image => { '0' => {
        :image => file3,
        :copyright_holder => 'holder_3',
        :when => time3,
        :notes => 'notes_3'
      }},
      # (attach these two images once observation created)
      :good_images => "#{new_image_1.id} #{new_image_2.id}",
      "image_#{new_image_1.id}_notes" => 'notes_1',
      "image_#{new_image_2.id}_notes" => 'notes_2_new'
    )
    assert_response(:redirect) # redirected = successfully created

    obs = Observation.find_by_where('zzyzx')
    assert_equal(1, obs.user_id)
    assert_equal(time0, obs.when)
    assert_equal('zzyzx', obs.place_name)

    imgs = obs.images.sort_by(&:id)
    img_ids = imgs.map(&:id)
    assert_equal([new_image_1.id, new_image_2.id, new_image_2.id+1], img_ids)
    assert_equal(new_image_2.id+1, obs.thumb_image_id)
    assert_equal('holder_1', imgs[0].copyright_holder)
    assert_equal('holder_2', imgs[1].copyright_holder)
    assert_equal('holder_3', imgs[2].copyright_holder)
    assert_equal(time1, imgs[0].when)
    assert_equal(time2, imgs[1].when)
    assert_equal(time3, imgs[2].when)
    assert_equal('notes_1',     imgs[0].notes)
    assert_equal('notes_2_new', imgs[1].notes)
    assert_equal('notes_3',     imgs[2].notes)
    assert(imgs[0].modified < 1.day.ago)
    assert(imgs[1].modified > 1.day.ago)
  end

  def test_image_upload_when_create_fails
    login('rolf')

    FileUtils.cp_r(IMG_DIR.gsub(/test_images$/, 'setup_images'), IMG_DIR)
    file = "#{RAILS_ROOT}/test/fixtures/images/Coprinus_comatus.jpg"
    file = FilePlus.new(file)
    file.content_type = 'image/jpeg'

    post(:create_observation,
      :observation => {
        :where => '',  # will cause failure
        :when => Time.now,
      },
      :image => { '0' => {
        :image => file,
        :copyright_holder => 'zuul',
        :when => Time.now,
      }}
    )
    assert_response(:success) # success = failure, paradoxically

    # Make sure image was created, but that it is unattached, and that it has
    # been kept in the @good_images array for attachment later.
    img = Image.find_by_copyright_holder('zuul')
    assert(img)
    assert_equal([], img.observations)
    assert([img.id], @controller.instance_variable_get('@good_images').map(&:to_s))
  end

  # ----------------------------
  #  Interest.
  # ----------------------------

  def test_interest_in_show_observation
    login('rolf')

    # No interest in this observation yet.
    get(:show_observation, :id => @minimal_unknown.id)
    assert_response(:success)
    assert_link_in_html(/<img[^>]+watch\d*.png[^>]+>[\w\s]*/,
      :controller => 'interest', :action => 'set_interest',
      :type => 'Observation', :id => @minimal_unknown.id, :state => 1
    )
    assert_link_in_html(/<img[^>]+ignore\d*.png[^>]+>[\w\s]*/,
      :controller => 'interest', :action => 'set_interest',
      :type => 'Observation', :id => @minimal_unknown.id, :state => -1
    )

    # Turn interest on and make sure there is an icon linked to delete it.
    Interest.create(:object => @minimal_unknown, :user => @rolf, :state => true)
    get(:show_observation, :id => @minimal_unknown.id)
    assert_response(:success)
    assert_link_in_html(/<img[^>]+halfopen\d*.png[^>]+>/,
      :controller => 'interest', :action => 'set_interest',
      :type => 'Observation', :id => @minimal_unknown.id, :state => 0
    )
    assert_link_in_html(/<img[^>]+ignore\d*.png[^>]+>/,
      :controller => 'interest', :action => 'set_interest',
      :type => 'Observation', :id => @minimal_unknown.id, :state => -1
    )

    # Destroy that interest, create new one with interest off.
    Interest.find_all_by_user_id(@rolf.id).last.destroy
    Interest.create(:object => @minimal_unknown, :user => @rolf, :state => false)
    get(:show_observation, :id => @minimal_unknown.id)
    assert_response(:success)
    assert_link_in_html(/<img[^>]+halfopen\d*.png[^>]+>/,
      :controller => 'interest', :action => 'set_interest',
      :type => 'Observation', :id => @minimal_unknown.id, :state => 0
    )
    assert_link_in_html(/<img[^>]+watch\d*.png[^>]+>/,
      :controller => 'interest', :action => 'set_interest',
      :type => 'Observation', :id => @minimal_unknown.id, :state => 1
    )
  end
end
