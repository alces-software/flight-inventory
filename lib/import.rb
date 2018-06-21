
class Import
  CONTROLLER_IP = '10.101.0.46'
  CONTROLLER_PASSWORD = ENV.fetch('ALCES_INSECURE_PASSWORD')

  def self.run
    Net::SSH.start(CONTROLLER_IP, 'root', password: CONTROLLER_PASSWORD) do |ssh|
      self.new(ssh).run
    end
  end

  def run
    # XXX Reset everything on each run for now.
    `rails db:reset`

    servers_to_chassis = import_chassis
    network_adapters_to_servers = import_servers(servers_to_chassis)
    import_network_adapters(network_adapters_to_servers)
    import_nodes
  end

  private

  attr_reader :ssh_connection

  def initialize(ssh_connection)
    @ssh_connection = ssh_connection
  end

  def import_chassis
    import_assets_of_type(Chassis, child_class: Server)
  end

  def import_servers(servers_to_chassis)
    import_assets_of_type(
      Server,
      parent_class: Chassis,
      parents_map: servers_to_chassis,
      child_class: NetworkAdapter
    )
  end

  def import_network_adapters(network_adapters_to_servers)
    import_assets_of_type(
      NetworkAdapter,
      parent_class: Server,
      parents_map: network_adapters_to_servers
    )
  end

  def import_assets_of_type(klass, parent_class: nil, parents_map: nil, child_class: nil)
    asset_type = klass.to_s.underscore
    human_asset_type = asset_type.humanize(capitalize: false)

    parent_type = parent_class.to_s.underscore
    child_type = child_class.to_s.underscore

    STDERR.puts "Importing #{human_asset_type.pluralize}"

    all_data = metal_view("assets.#{asset_type.pluralize}")
    STDERR.puts "Found #{all_data.length} #{human_asset_type.pluralize}"

    assets = all_data.map do |data|
      name = asset_name(data)
      STDERR.puts "Importing #{human_asset_type} #{name}"

      asset_attributes = {name: name, data: data}
      if parent_class
        parent_name = parents_map.fetch(name)
        parent = parent_class.find_by_name!(parent_name)
        asset_attributes.merge!(parent_type => parent)
      end

      klass.create!(asset_attributes)
    rescue KeyError => ex
      STDERR.puts "WARNING: #{human_asset_type} #{name} has no #{parent_class}, skipping: #{ex.message}"
    end.compact

    # Exit early unless there's a child class to find relationships with.
    return unless child_class

    # Create Child name -> Asset name hash
    relationships = assets.flat_map do |asset|
      children_names = asset.data[child_type.pluralize].flat_map do |reference|
        # Reference is an @WilliamMcCumstie-style Metalware asset reference,
        # e.g. `^rack1-r630-chassis-780-server1`; we just want the name of the
        # referenced asset.
        reference.gsub(/^\^/, '')
      end

      children_names.zip([asset.name] * children_names.length)
    end.to_h

    STDERR.puts "Found these #{child_type.humanize(capitalize: false)}-#{human_asset_type} relationships:"
    STDERR.puts JSON.pretty_generate(relationships).gsub(/^/, '    ')

    # Return the child-asset relationships to use when importing children.
    relationships
  end

  def import_nodes
    all_nodes = metal_view('nodes.map(&:name)')
    # XXX This gets all nodes on old Metalware; above only works on latest
    # Metalware with https://github.com/alces-software/metalware/pull/430
    # merged.
    # all_nodes = ssh.exec!("nodeattr --expand | awk '{print $1}'").lines.map(&:chomp)

    STDERR.puts "Found #{all_nodes.length} nodes: #{all_nodes.join(', ')}"

    all_nodes.each do |node|
      if node == 'local'
        STDERR.puts 'Skipping local node'
        next
      end

      STDERR.puts "Importing node #{node}..."

      # XXX Use below with old Metalware, as above.
      # node_data = JSON.parse(ssh.exec!("metal view node.#{node} 2> /dev/null"))
      node_data = metal_view("nodes.#{node}.to_h")

      node_asset_data = metal_view("nodes.#{node}.asset")
      node_server = asset_name(node_asset_data)

      Node.create!(
        name: node,
        data: node_data,
        server: Server.find_by_name!(node_server)
      )
    end
  end

  def metal_view(view_args)
    metal_command = "metal view '#{view_args}' 2> /dev/null"
    STDERR.puts ">>> #{metal_command}"
    output = ssh_connection.exec!(metal_command)
    JSON.parse(output)
  end

  def asset_name(asset_data)
    asset_data.dig('metadata', 'name')
  end
end
