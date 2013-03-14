class NodeGroupMembership < ActiveRecord::Base
  validates_presence_of :node_id, :node_group_id
  validates_uniqueness_of :node_id, :scope => :node_group_id

  belongs_to :node
  belongs_to :node_group

  attr_accessible :node, :node_id
  attr_accessible :node_group, :node_group_id

  def to_json(*args)
    {"node_group_id" => node_group_id, "node_id" => node_id}.to_json(*args)
  end
end
