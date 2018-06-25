
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

    # Physical assets.
    import_networks
    chassis_maps = import_chassis
    import_psus(chassis_maps[Psu])
    server_maps = import_servers(chassis_maps[Server])
    import_network_adapters(server_maps[NetworkAdapter])

    # Logical assets.
    import_groups
    import_nodes
  end

  private

  attr_reader :ssh_connection

  def initialize(ssh_connection)
    @ssh_connection = ssh_connection
  end

  def import_networks
    # XXX Import networks without using `import_assets_of_type`, since these
    # are superficially similar but also simpler/different (networks do not
    # seem to have arbitrary other data associated with them, so don't need
    # `data` field, but we do want to ensure we always extract the required
    # `cable_colour` field).
    STDERR.puts 'Importing networks'

    networks_data = metal_view('assets.networks')
    STDERR.puts "Found #{networks_data.length} networks"

    networks_data.map do |data|
      name = asset_name(data)
      STDERR.puts "Importing network #{name}"
      cable_colour = data.fetch('cable_colour')
      Network.create!(name: name, cable_colour: cable_colour)
    end
  end

  def import_chassis
    import_assets_of_type(Chassis, child_classes: [Server, Psu])
  end

  def import_psus(psus_to_chassis)
    import_assets_of_type(
      Psu,
      parent_class: Chassis,
      parents_map: psus_to_chassis
    )
  end

  def import_servers(servers_to_chassis)
    import_assets_of_type(
      Server,
      parent_class: Chassis,
      parents_map: servers_to_chassis,
      child_classes: [NetworkAdapter]
    )
  end

  def import_network_adapters(network_adapters_to_servers)
    import_assets_of_type(
      NetworkAdapter,
      parent_class: Server,
      parents_map: network_adapters_to_servers
    ) do |adapters|
      adapters.each do |adapter|
        adapter.data.fetch('ports').each do |interface, _port_data|
          STDERR.puts "Importing network adapter port #{interface} for adapter #{adapter.name}"
          NetworkAdapterPort.create!(
            interface: interface,
            network_adapter: adapter
          )
        end
      end
    end
  end

  def import_assets_of_type(klass, parent_class: nil, parents_map: nil, child_classes: [])
    asset_type = klass.to_s.underscore
    human_asset_type = asset_type.humanize(capitalize: false)

    parent_type = parent_class.to_s.underscore

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

    # Allow performing additional asset-specific processing before returning
    # the asset child relationships hash (below).
    yield assets if block_given?

    child_classes.map do |child_class|
      child_type = child_class.to_s.underscore

      # Create Child name -> Asset name hash
      relationships = assets.flat_map do |asset|
        children_names = asset.data[child_type.pluralize].flat_map do |reference|
          # Reference is an @WilliamMcCumstie-style Metalware asset reference,
          # e.g. `^rack1-r630-chassis-780-server1`; we just want the name of
          # the referenced asset.
          reference.gsub(/^\^/, '')
        end

        children_names.zip([asset.name] * children_names.length)
      end.to_h

      STDERR.puts "Found these #{child_type.humanize(capitalize: false)}-#{human_asset_type} relationships:"
      STDERR.puts JSON.pretty_generate(relationships).gsub(/^/, '    ')

      # Return value of this function should be
      # `Hash[child_class, Hash[child_name, asset_name]]`.
      [child_class, relationships]
    end.to_h
  end

  def import_groups
    all_groups = metal_view('groups.map(&:name)')

    STDERR.puts "Found #{all_groups.length} groups: #{all_groups.join(', ')}"

    all_groups.map do |group|
      STDERR.puts "Importing group #{group}..."

      group_data = metal_view("groups.#{group}.to_h")

      Group.create!(
        name: group,
        data: group_data,
      )
    end
  end

  def import_nodes
    all_nodes = metal_view('nodes.map(&:name)')
    # XXX This gets all nodes on old Metalware; above only works on latest
    # Metalware with https://github.com/alces-software/metalware/pull/430
    # merged.
    # all_nodes = ssh.exec!("nodeattr --expand | awk '{print $1}'").lines.map(&:chomp)

    STDERR.puts "Found #{all_nodes.length} nodes: #{all_nodes.join(', ')}"

    all_nodes.each do |node_name|
      if node_name == 'local'
        STDERR.puts 'Skipping local node'
        next
      end

      STDERR.puts "Importing node #{node_name}..."

      # XXX Use below with old Metalware, as above.
      # node_data = JSON.parse(ssh.exec!("metal view node.#{node} 2> /dev/null"))
      node_data = metal_view("nodes.#{node_name}.to_h")

      node_asset_data = metal_view("nodes.#{node_name}.asset")
      node_server = asset_name(node_asset_data)

      node_group_name = metal_view("nodes.#{node_name}.group.name")

      node = Node.create!(
        name: node_name,
        data: node_data,
        server: Server.find_by_name!(node_server),
        group: Group.find_by_name!(node_group_name),
      )

      node_genders = node_data['genders']
      STDERR.puts "Creating/associating genders for node #{node_name}: #{node_genders.join(', ')}"
      node_genders.each do |gender_name|
        gender = Gender.find_or_create_by!(name: gender_name)
        gender.nodes << node
      end
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
