
ALL_FIELDS = [
  :authors_names,
  :editors_names,
  :images,
  :past_locations,
  :species_lists,
  :species_list_entries,
  :comments,
  :observations,
  :namings,
  :votes,
  :users
]

FIELD_WEIGHTS = {
  :authors_names => 100,
  :editors_names => 10,
  :images => 10,
  :past_locations => 5,
  :species_lists => 5,
  :species_list_entries => 1,
  :comments => 1,
  :observations => 1,
  :namings => 1,
  :votes => 1,
  :users => 0
}

# Default is field.to_s.  This is the table it queries to get the number of objects.
FIELD_TABLES = {
  :species_list_entries => "observations_species_lists",
}

FIELD_CONDITIONS = {
  :users => "verified is not null"
}

################################################################################
#
#  This class manages user contributions / rankings.
#
#  Global Constants:
#    ALL_FIELDS                List of fields, presumably in a pleasing order.
#    FIELD_WEIGHTS             Weight of each field in user metric.
#    FIELD_TITLES              Title to use for each field in view.
#    FIELD_TABLES              Name of table to count rows of for each field.
#                              (only the exceptions; default is field name)
#
#  Public Methods:
#    get_site_data             Returns stats for entire site.
#    get_user_data(user_id)    Returns stats for given user.
#    get_all_user_data         Returns stats for all users.
#
#  Callbacks:
#    SiteData.update_contribution(mode, obj)
#                              Keep user.contribution up to date.
#
#  Private:
#    load_user_data(id=nil)    Populates @user_data (some stuff hard-coded).
#    load_field_counts(...)    Populates a single column in @user_data.
#    calc_metric(fields)       Calculates score of a single user.
#    get_field_count(field)    Looks up number of entries in a given table.
#
#  Static internal data structure: (created by load_user_data)
#    @user_data        This is a 2-D hash keyed on user_id then field name:
#      :images           Number of images the user has posted.
#      ...
#      :observations     Number of observations user has posted.
#      :name             User's legal_name.
#      :id               User's id.
#
################################################################################

class SiteData

  # This is called every time any object (not just ones we care about) is
  # created or destroyed.  Figure out what kind of object from the class name,
  # and then update the owner's contribution as appropriate.
  def self.update_contribution(mode, obj, field=nil, num=1)
    field = obj.class.to_s.sub(/.*::/,'').tableize.to_sym if !field
    weight = FIELD_WEIGHTS[field]
# print ">>>> #{mode} #{field} #{weight} #{num} (##{obj.id}#{obj.respond_to?(:text_name) ? ' ' + obj.text_name : ''})\n"
    if weight && weight > 0 &&
       obj.respond_to?('user_id') && (user = User.find_by_id(obj.user_id))
      user.contribution = 0 if !user.contribution
      user.contribution += (mode == :create ? weight : -weight) * num
# print " -> #{user.contribution}"
      user.save
    end
# print "\n"
  end

  # Return stats for entire site.  Returns simple hash mapping object type
  # to number of that object: <tt>result[:images] = num_images</tt>
  def get_site_data
    result = {}
    for field in ALL_FIELDS
      result[field] = get_field_count(field)
    end
    result
  end

  # Return stats for a single user.  Returns simple hash mapping object type
  # to number of that object: <tt>result[:images] = num_images</tt>
  def get_user_data(id)
    load_user_data(id)
    @user_data[@user_id]
  end

  # Load stats for all users.  Returns nothing.  Use get_user_data to query
  # individual user's stats.
  def get_all_user_data
    load_user_data(nil)
  end

################################################################################

private

  def calc_metric(fields)
    metric = 0
    if fields
      for field in ALL_FIELDS
        count = fields[field] || 0
        metric += FIELD_WEIGHTS[field] * count
      end
    end
    fields[:metric] = metric
    return metric
  end

  def get_field_count(field)
    result = 0
    table = FIELD_TABLES[field]
    if table.nil?
      table = field
    end
    query = "select count(*) as c from %s" % table
    if FIELD_CONDITIONS[field]
      query += " where #{FIELD_CONDITIONS[field]}"
    end
    data = User.connection.select_all(query)
    for d in data
      result = d['c'].to_i
    end
    result
  end

  def load_user_data(id=nil)
    @user_id = id
    users = nil
    if id.nil?
      users = User.find(:all)
    else
      @user_id = id.to_i
      users = [User.find(id)]
    end

    # Fill in table by performing one query for each object being counted.
    @user_data = {}
    for user in users
      @user_data[user.id] = { :name => user.legal_name, :id => user.id }
    end
    for field in ALL_FIELDS
      table = FIELD_TABLES[field]
      if !table
        load_field_counts(field) if field != :users
      else
        conditions = @user_id ? "user_id = #{@user_id}" : "user_id > 0"
        case field
        when :species_list_entries:
          # This exception only occurs for species list entries for the moment.
          table = "species_lists s, observations_species_lists os"
          conditions += " and s.id=os.species_list_id"
        end
        query = %(
          SELECT count(*) as c, user_id
          FROM #{table}
          WHERE #{conditions}
          GROUP BY user_id
          ORDER BY c DESC
        )
        load_field_counts(field, query)
      end
    end

    # Now fix any user contribution caches that have the incorrect number.
    for user in users
      contribution = calc_metric(@user_data[user.id])
      if bonuses = user.bonuses
        for points, reason in bonuses
          contribution += points
        end
      end
      if user.contribution != contribution
        user.contribution = contribution
        user.save
      end
    end
  end

  def load_field_counts(field, query=nil)
    result = []
    if query.nil?
      conditions = @user_id ? "user_id = #{@user_id}" : "user_id > 0"
      query = "SELECT count(*) AS c, user_id FROM %s WHERE %s GROUP BY user_id" % [field, conditions]
    end
    data = User.connection.select_all(query)
    for d in data
      user_id = d['user_id'].to_i
      @user_data[user_id][field] = d['c'].to_i
    end
  end
end
