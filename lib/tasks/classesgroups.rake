namespace :nodeclass do
  desc 'List node classes'
  task :list => :environment do
    regex = false

    if ENV['match']
      regex = ENV['match']
    end

    NodeClass.find(:all).each do |nodeclass|
      if regex
        if nodeclass.name =~ /#{regex}/
          puts nodeclass.name
        end
      else
        puts nodeclass.name
      end
    end
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

    klass = NodeClass.new(:name => name)

    if klass.save
      puts 'Class successfully created!'
    end
  end

  desc 'Delete a node class'
  task :del => :environment do
    if ENV['name']
      name = ENV['name']
    else
      puts 'Must specify class name (name=<class>).'
      exit 1
    end

    begin
      nc = NodeClass.find_by_name(name)
      nc.destroy
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
    regex = false

    if ENV['match']
      regex = ENV['match']
    end

    NodeGroup.find(:all).each do |nodegroup|
      if regex
        if nodegroup.name =~ /#{regex}/
          puts nodegroup.name
        end
      else
        puts nodegroup.name
      end
    end
  end

  desc 'List classes that belong to a node group'
  task :listclasses => :environment do
    if ENV['name']
      name = ENV['name']
    else
      puts 'Must specify group name (name=<group>).'
      exit 1
    end

    begin
      nodegroup = NodeGroup.find_by_name(name)
      if nodegroup.nil?
        puts "Group doesn't exist!"
        exit 1
      end

      classes = nodegroup.node_classes
      classes.each do |klass|
        puts klass.name
      end
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

    classes = []

    if ENV['classes']
      ENV['classes'].split(/,\s*/).each do |klass|
        nc = NodeClass.find_by_name(klass)
        unless nc.nil?
          classes << nc
        end
      end
    end

    nodegroup = NodeGroup.new(:name => name)
    nodegroup.node_classes = classes

    if nodegroup.save
      puts 'Group successfully created!'
    end
  end

  desc 'Add a class to a nodegroup'
  task :addclass => :environment do
    if ENV['name']
      name = ENV['name']
    else
      puts 'Must specify group name (name=<group>).'
      exit 1
    end

    if ENV['class']
      classname = ENV['class']
    else
      puts 'Must specify class name (class=<classname>).'
      exit 1
    end

    begin
      nodegroup = NodeGroup.find_by_name(name)
      if nodegroup.nil?
        puts 'Group doesn\'t exist!'
        exit 1
      end

      nc = NodeClass.find_by_name(classname)
      if nc.nil?
        puts 'Class doesn\'t exist!'
        exit 1
      else
       classes = nodegroup.node_classes
       if classes.include?(nc)
         puts "Group '#{name}' already includes class '#{classname}'"
         exit 0
       else
         classes << nc
         nodegroup.node_classes = classes
         if nodegroup.save
           puts "Class '#{classname}' added to node group '#{name}'"
          end
        end
      end

    rescue => e
      puts e.message
      exit 1
    end
  end

  desc 'Remove a class from a nodegroup'
  task :delclass => :environment do
    if ENV['name']
      name = ENV['name']
    else
      puts 'Must specify group name (name=<group>).'
      exit 1
    end

    if ENV['class']
      classname = ENV['class']
    else
      puts 'Must specify class name (class=<classname>).'
      exit 1
    end

    begin
      nodegroup = NodeGroup.find_by_name(name)
      if nodegroup.nil?
        puts "Group doesn't exist!"
        exit 1
      end

      nc = NodeClass.find_by_name(classname)
      if nc.nil?
        puts "Class doesn't exist!"
        exit 1
      else
        classes = nodegroup.node_classes
        unless classes.include?(nc)
          puts "Group '#{name}' does not include class '#{classname}'"
          exit 0
        else
          classes.delete(nc)
          nodegroup.node_classes = classes
          if nodegroup.save
            puts "Class '#{classname}' removed from node group '#{name}'"
          end
        end
      end

    rescue => e
      puts e.message
      exit 1
    end
  end

  desc 'Show/Edit/Add parameters for a node group'
  task :parameters => :environment do
    group_name = ENV['name']

    if group_name.nil?
      puts 'Must specify node group name (name=<hostname>).'
      exit 1
    end

    begin
      group = NodeGroup.find_by_name(group_name)

      if group.nil?
        puts "Node group #{group_name} doesn\'t exist!"
        exit 1
      end
    rescue => e
      puts "There was a problem finding the node group: #{e.message}"
      exit 1
    end

    # Show parameters
    if ENV['parameters'].nil?
      group.parameters.each do |p|
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
          param, *dupes = *group.parameters.find_all_by_key(key)
          if param
            # Change existing parameters
            param.value = value
            param.save!
            # If there were duplicate params from the previous buggy version of
            # this code, remove them
            dupes.each { |d| d.destroy }
          else
            # Create new parameters
            group.parameters.create(:key => key, :value => value)
          end
        end

        group.save!
        puts "Node group parameters successfully edited for #{group.name}!"
      end
    rescue => e
      puts "There was a problem saving the node group: #{e.message}"
      exit 1
    end

  end

  desc 'Edit a node group'
  task :edit => :environment do
    if ENV['name']
      name = ENV['name']
    else
      puts 'Must specify group name (name=<group>).'
      exit 1
    end

    begin
      nodegroup = NodeGroup.find_by_name(name)

      classes = []

      if ENV['classes']
        ENV['classes'].split(/,\s*/).each do |klass|
          nc = NodeClass.find_by_name(klass)
          unless nc.nil?
            classes << nc
          end
        end
      end

      nodegroup.node_classes = classes

      if nodegroup.save
        puts 'Group successfully edited!'
      end
    rescue NoMethodError
      puts 'Group doesn\'t exist!'
      exit 1
    rescue => e
      puts e.message
      exit 1
    end
  end

  desc 'Delete a node group'
  task :del => :environment do
    if ENV['name']
      name = ENV['name']
    else
      puts 'Must specify group name (name=<group>).'
      exit 1
    end

    begin
      nodegroup = NodeGroup.find_by_name(name)
      nodegroup.destroy
    rescue NoMethodError
      puts 'Group doesn\'t exist!'
      exit 1
    rescue => e
      puts e.message
    end
  end

  desc 'Automatically adds all nodes to a group'
  task :add_all_nodes => :environment do
    if ENV['group']
      groupname = ENV['group']
    else
      puts 'Must specify group name (group=<groupname>).'
      exit 1
    end

    group = NodeGroup.find_by_name(groupname)
    if group.nil?
      puts "Cannot find group: #{groupname}"
      exit 1
    end

    begin
      Node.find(:all).each do |node|
        node_groups = node.node_groups
        unless node_groups.include?(group)
          node_groups.push(group)
          node.node_groups = node_groups
        end
      end
    rescue => e
      puts "There was a problem adding all nodes to the group '#{group}': #{e.message}"
      exit 1
    end
  end
end
