
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

    import_chassis
    import_servers
    import_network_adapters
    import_nodes
  end

  private

  attr_reader :ssh_connection,
    :server_chassis_relationships,
    :network_adapter_server_relationships

  def initialize(ssh_connection)
    @ssh_connection = ssh_connection
  end

  def import_chassis
    all_chassis_data = metal_view('assets.chassis')

    STDERR.puts "Found #{all_chassis_data.length} chassis"

    chassis = all_chassis_data.map do |data|
      name = asset_name(data)
      STDERR.puts "Importing chassis #{name}..."
      chassis = Chassis.create!(name: name, data: data)
    end

    # Create Server name -> Chassis name hash
    @server_chassis_relationships = chassis.flat_map do |a_chassis|
      server_names = a_chassis.data['servers'].flat_map do |reference|
        # Reference is an @WilliamMcCumstie-style Metalware asset reference,
        # e.g. `^rack1-r630-chassis-780-server1`; we just want the name of the
        # referenced asset.
        reference.gsub(/^\^/, '')
      end

      server_names.zip([a_chassis.name] * server_names.length)
    end.to_h

    STDERR.puts "Found these server-chassis relationships:"
    STDERR.puts JSON.pretty_generate(server_chassis_relationships).gsub(/^/, '    ')
  end

  def import_servers
    all_server_data = metal_view('assets.servers')

    STDERR.puts "Found #{all_server_data.length} servers"

    servers = all_server_data.map do |data|
      name = asset_name(data)
      STDERR.puts "Importing server #{name}"

      chassis_name = server_chassis_relationships.fetch(name)
      chassis = Chassis.find_by_name!(chassis_name)
      Server.create!(name: name, data: data, chassis: chassis)
    rescue KeyError => ex
      STDERR.puts "WARNING: Server #{name} has no chassis, skipping: #{ex.message}"
    end.compact

    # Create Network adapter name -> Server name hash
    @network_adapter_server_relationships = servers.flat_map do |server|
      network_adapter_names = server.data['network_adapters'].flat_map do |reference|
        # Reference is an @WilliamMcCumstie-style Metalware asset reference,
        # e.g. `^rack1-r630-chassis-780-server1`; we just want the name of the
        # referenced asset.
        reference.gsub(/^\^/, '')
      end

      network_adapter_names.zip([server.name] * network_adapter_names.length)
    end.to_h

    STDERR.puts "Found these network adapter-server relationships:"
    STDERR.puts JSON.pretty_generate(network_adapter_server_relationships).gsub(/^/, '    ')
  end

  def import_network_adapters
    all_network_adapter_data = metal_view('assets.network_adapters')

    STDERR.puts "Found #{all_network_adapter_data.length} network adapters"

    all_network_adapter_data.map do |data|
      name = asset_name(data)
      STDERR.puts "Importing network adapter #{name}"

      server_name = network_adapter_server_relationships.fetch(name)
      server = Server.find_by_name!(server_name)
      NetworkAdapter.create!(name: name, data: data, server: server)
    rescue KeyError => ex
      STDERR.puts "WARNING: Network adapter #{name} has no server, skipping: #{ex.message}"
    end
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
