$: << File.dirname(__FILE__)
require 'rake_helpers'

namespace :nodeclass do
  desc 'List node classes'
  task :list => :environment do
    names = NodeClass.all.map(&:name)
    regex = ENV['match'] # if nil, everything matches
    names.grep(/#{regex}/).map{|n| puts n}
  end

  desc 'Add a new node class'
  task :add => :environment do
    if ENV['name']
      name = ENV['name']
    else
      puts 'Must specify class name (name=<class>).'
      exit 1
    end

    if NodeClass.find_by_name(name)
      puts 'Class already exists!'
      exit 1
    end

    NodeClass.new(:name => name).save!
    puts 'Class successfully created!'
  end

  desc 'Delete a node class'
  task :del => :environment do
    begin
      get_class(ENV['name']).destroy
      puts 'Group successfully deleted!'
    rescue NoMethodError
      puts 'Class doesn\'t exist!'
      exit 1
    rescue => e
      puts e.message
      exit 1
    end
  end
end

namespace :nodegroup do
  desc 'List node groups'
  task :list => :environment do
    names = NodeGroup.all.map(&:name)
    regex = ENV['match'] # if nil, everything matches
    names.grep(/#{regex}/).map{|n| puts n}
  end

  desc 'List classes that belong to a node group'
  task :listclasses => :environment do
    nodegroup = get_group(ENV['name'])

    begin
      nodegroup.node_classes.map(&:name).map{|n| puts n}
    rescue => e
      puts e.message
      exit 1
    end
  end

  desc 'Add a new node group'
  task :add => :environment do
    if ENV['name']
      name = ENV['name']
    else
      puts 'Must specify group name (name=<group>).'
      exit 1
    end

    if NodeGroup.find_by_name(name)
      puts 'Group already exists!'
      exit 1
    end

    nodegroup = NodeGroup.new(:name => name)

    if ENV['classes']
      classes = ENV['classes'].split(',').map(&:strip)
      nodegroup.node_classes = NodeClass.find_all_by_name(classes)
    end

    nodegroup.save!
    puts 'Group successfully created!'
  end

  desc 'Add a class to a nodegroup'
  task :addclass => :environment do
    nodegroup = get_group(ENV['name'])
    nodeclass = get_class(ENV['class'])

    begin
     classes = nodegroup.node_classes
     if classes.include?(nodeclass)
       puts "Group '#{nodegroup.name}' already includes class '#{nodeclass.name}'"
     else
       classes << nodeclass
       puts "Class '#{nodeclass.name}' added to node group '#{nodegroup.name}'"
     end
    rescue => e
      puts e.message
      exit 1
    end
  end

  desc 'Remove a class from a nodegroup'
  task :delclass => :environment do
    nodegroup = get_group(ENV['name'])
    nodeclass = get_class(ENV['class'])

    begin
      classes = nodegroup.node_classes
      unless classes.include?(nodeclass)
        puts "Group '#{nodegroup.name}' does not include class '#{nodeclass.name}'"
      else
        classes.delete(nodeclass)
        puts "Class '#{nodeclass.name}' removed from node group '#{nodegroup.name}'"
      end
    rescue => e
      puts e.message
      exit 1
    end
  end

  # deprecated - use variables instead
  task :parameters => :environment do
    nodegroup = get_group(ENV['name'])

    # Show parameters
    unless ENV['parameters']
      nodegroup.parameters.each do |p|
        puts "#{p.key}=#{p.value}"
      end
      exit
    end

    given_parameters = Hash[ ENV['parameters'].split(',').map do |param|
      param_array = param.split('=',2)
      if param_array.size != 2
        raise ArgumentError, "Could not parse parameter #{param_array.first} given. Perhaps you're missing a '='"
      end
      if param_array[0].nil? or param_array[0].empty?
        raise ArgumentError, "Could not parse parameters. Please check your format. Perhaps you need to name a parameter before a '='"
      end
      if param_array[1].nil? or param_array[1].empty?
        raise ArgumentError, "Could not parse parameters #{param_array.first}. Please check your format"
      end
      param_array
    end ]

    begin
      ActiveRecord::Base.transaction do
        given_parameters.each do |key, value|
          param, *dupes = *nodegroup.parameters.find_all_by_key(key)
          if param
            # Change existing parameters
            param.value = value
            param.save!
            # If there were duplicate params from the previous buggy version of
            # this code, remove them
            dupes.each { |d| d.destroy }
          else
            # Create new parameters
            nodegroup.parameters.create(:key => key, :value => value)
          end
        end

        nodegroup.save!
        puts "Node group parameters successfully edited for #{nodegroup.name}!"
      end
    rescue => e
      puts "There was a problem saving the node group: #{e.message}"
      exit 1
    end

  end

  desc 'Show/Edit/Add variables for a node group'
  task :variables => :environment do
    nodegroup = get_group(ENV['name'])

    # Show variables
    unless ENV['variables']
      nodegroup.parameters.each do |p|
        puts "#{p.key}=#{p.value}"
      end
      exit
    end

    given_parameters = Hash[ ENV['variables'].split(',').map do |param|
      param_array = param.split('=',2)
      if param_array.size != 2
        raise ArgumentError, "Could not parse variable #{param_array.first} given. Perhaps you're missing a '='"
      end
      if param_array[0].nil? or param_array[0].empty?
        raise ArgumentError, "Could not parse variables. Please check your format. Perhaps you need to name a variable before a '='"
      end
      if param_array[1].nil? or param_array[1].empty?
        raise ArgumentError, "Could not parse variables #{param_array.first}. Please check your format"
      end
      param_array
    end ]

    begin
      ActiveRecord::Base.transaction do
        given_parameters.each do |key, value|
          param, *dupes = *nodegroup.parameters.find_all_by_key(key)
          if param
            # Change existing variables
            param.value = value
            param.save!
            # If there were duplicate variables from the previous buggy version of
            # this code, remove them
            dupes.each { |d| d.destroy }
          else
            # Create new variables
            nodegroup.parameters.create(:key => key, :value => value)
          end
        end

        nodegroup.save!
        puts "Node group variables successfully edited for #{nodegroup.name}!"
      end
    rescue => e
      puts "There was a problem saving the node group: #{e.message}"
      exit 1
    end

  end

  desc 'Edit a node group'
  task :edit => :environment do
    nodegroup = get_group(ENV['name'])

    exit unless ENV['classes']

    begin
      classes = ENV['classes'].split(',').map(&:strip)
      nodegroup.node_classes = NodeClass.find_all_by_name(classes)
      nodegroup.save!
      puts 'Group successfully edited!'
    rescue => e
      puts e.message
      exit 1
    end
  end

  desc 'Delete a node group'
  task :del => :environment do
    begin
      get_group(ENV['name']).destroy
      puts 'Group successfully deleted!'
    rescue => e
      puts e.message
      exit 1
    end
  end

  desc 'Automatically adds all nodes to a group'
  task :add_all_nodes => :environment do
    group = get_group(ENV['name'])

    begin
      Node.all.each do |node|
        node_groups = node.node_groups
        node_groups << group unless node_groups.include?(group)
      end
    rescue => e
      puts "There was a problem adding all nodes to the group '#{group}': #{e.message}"
      exit 1
    end
  end
end
