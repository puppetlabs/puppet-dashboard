class RemoveUrlFromNodes < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :nodes, :url
  end

  def self.down
    add_column :nodes, :url, :string
  end
end
