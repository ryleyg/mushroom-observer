class Initial < ActiveRecord::Migration
  def up
    create_table "comments", :force => true do |t|
      t.column "created", :datetime
      t.column "user_id", :integer
      t.column "summary", :string, :limit => 100
      t.column "comment", :text
      t.column "observation_id", :integer, :default => 0, :null => false
    end

    create_table "images", :force => true do |t|
      t.column "created", :datetime
      t.column "modified", :datetime
      t.column "content_type", :string, :limit => 100
      t.column "title", :string, :limit => 100
      t.column "owner", :string, :limit => 100
      t.column "user_id", :integer
      t.column "when", :date
      t.column "notes", :text
    end

    create_table "images_observations", :id => false, :force => true do |t|
      t.column "image_id", :integer, :default => 0, :null => false
      t.column "observation_id", :integer, :default => 0, :null => false
    end

    create_table "observations", :force => true do |t|
      t.column "created", :datetime
      t.column "modified", :datetime
      t.column "when", :date
      t.column "who", :string, :limit => 100
      t.column "user_id", :integer
      t.column "where", :string, :limit => 100
      t.column "what", :string, :limit => 100
      t.column "specimen", :boolean, :default => false, :null => false
      t.column "notes", :text
      t.column "thumb_image_id", :integer
    end

    create_table "users", :force => true do |t|
      t.column "login", :string, :limit => 80, :default => "", :null => false
      t.column "password", :string, :limit => 40, :default => "", :null => false
      t.column "email", :string, :limit => 80, :default => "", :null => false
      t.column "theme", :string, :limit => 40
      t.column "name", :string, :limit => 80
      t.column "created", :datetime
      t.column "last_login", :datetime
    end
  end

  def self.down
    drop_table "images_observations"
    drop_table "comments"
    drop_table "images"
    drop_table "observations"
    drop_table "users"
  end
end