
require 'rake'

class Import
  include Rake::DSL

  class << self
    def run
      Net::SSH.start(
        controller_ip, 'root', password: controller_password
      ) do |ssh|
        self.new(ssh).run
      end
    end

    private

    def controller_ip
      ENV.fetch('IP')
    end

    def controller_password
      ENV.fetch('ALCES_INSECURE_PASSWORD')
    end
  end

  def run
    # XXX Reset everything on each run for now; `pkill` the server process
    # first so (hopefully) no open database connections which would cause
    # `rails db:reset` to fail (use backticks rather than `sh` for this as if
    # this command fails presumably the server is not already running, which is
    # fine).
    `pkill --full "puma .*flight-inventory"`
    sh 'rails db:reset'

    # Physical assets.
    import_networks
    import_network_switches
    import_pdus
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
    # XXX Import networks without using `import_assets_of_type` for now as we
    # want to ensure we always extract the required `cable_colour` field, which
    # this does not currently support.
    Log.info 'Importing networks'

    networks_data = metal_eval('assets.networks')
    Log.info "Found #{networks_data.length} networks"

    networks_data.map do |data|
      name = asset_name(data)
      Log.info "Importing network #{name}"
      cable_colour = data.fetch('cable_colour')
      Network.create!(name: name, data: data, cable_colour: cable_colour)
    end
  end

  def import_network_switches
    import_assets_of_type(NetworkSwitch, has_oob: true)
  end

  def import_pdus
    import_assets_of_type(Pdu, has_oob: true)
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
      child_classes: [NetworkAdapter],
      has_oob: true
    )
  end

  def import_network_adapters(network_adapters_to_servers)
    import_assets_of_type(
      NetworkAdapter,
      parent_class: Server,
      parents_map: network_adapters_to_servers
    ) do |adapters|
      adapters.each do |adapter|
        adapter.data.fetch('ports').each_with_index do |port_data, index|
          port_number = index += 1
          Log.info "Importing network adapter port #{port_number} for adapter #{adapter.name}"
          port = NetworkAdapterPort.create!(
            number: port_number,
            network_adapter: adapter
          )

          connected_network_reference = port_data['network']
          if connected_network_reference.present?
            Log.info "Port connected to network; creating connection"

            network_name = asset_name_from_reference(connected_network_reference)
            switch_reference = port_data.fetch('switch')
            network_switch_name = asset_name_from_reference(switch_reference)

            NetworkConnection.create!(
              network: Network.find_by_name!(network_name),
              network_adapter_port: port,
              network_switch: NetworkSwitch.find_by_name!(network_switch_name)
            )
          end
        end
      end
    end
  end

  def import_assets_of_type(
    klass,
    parent_class: nil,
    parents_map: nil,
    child_classes: [],
    has_oob: false
  )
    asset_type = klass.to_s.underscore
    human_asset_type = asset_type.humanize(capitalize: false)

    parent_type = parent_class.to_s.underscore

    Log.info "Importing #{human_asset_type.pluralize}"

    all_data = metal_eval("assets.#{asset_type.pluralize}")
    Log.info "Found #{all_data.length} #{human_asset_type.pluralize}"

    assets = all_data.map do |data|
      name = asset_name(data)
      Log.info "Importing #{human_asset_type} #{name}"

      asset_attributes = {name: name, data: data}
      if parent_class
        parent_name = parents_map.fetch(name)
        parent = parent_class.find_by_name!(parent_name)
        asset_attributes.merge!(parent_type => parent)
      end

      if has_oob
        oob_data = data.fetch('oob')
        network_name = asset_name_from_reference(oob_data.fetch('network'))
        network = Network.find_by_name!(network_name)
        oob = Oob.create!(data: oob_data, network: network)
        asset_attributes.merge!(oob: oob)
      end

      klass.create!(asset_attributes)
    rescue KeyError => ex
      Log.warning "#{human_asset_type} #{name} has no #{parent_class}, skipping: #{ex.message}"
    end.compact

    # Allow performing additional asset-specific processing before returning
    # the asset child relationships hash (below).
    yield assets if block_given?

    child_classes.map do |child_class|
      child_type = child_class.to_s.underscore

      # Create Child name -> Asset name hash
      relationships = assets.flat_map do |asset|
        children_names = asset.data[child_type.pluralize].flat_map do |reference|
          asset_name_from_reference(reference)
        end

        children_names.zip([asset.name] * children_names.length)
      end.to_h

      Log.info "Found these #{child_type.humanize(capitalize: false)}-#{human_asset_type} relationships:"
      Log.raw_info JSON.pretty_generate(relationships).gsub(/^/, '    ')

      # Return value of this function should be
      # `Hash[child_class, Hash[child_name, asset_name]]`.
      [child_class, relationships]
    end.to_h
  end

  def import_groups
    all_groups = metal_eval('groups.map(&:name)')

    Log.info "Found #{all_groups.length} groups: #{all_groups.join(', ')}"

    all_groups.map do |group|
      Log.info "Importing group #{group}..."

      group_data = metal_eval("groups.#{group}.to_h")

      Group.create!(
        name: group,
        data: group_data,
      )
    end
  end

  def import_nodes
    all_nodes = metal_eval('nodes.map(&:name)')
    # XXX This gets all nodes on old Metalware; above only works on latest
    # Metalware with https://github.com/alces-software/metalware/pull/430
    # merged.
    # all_nodes = ssh.exec!("nodeattr --expand | awk '{print $1}'").lines.map(&:chomp)

    Log.info "Found #{all_nodes.length} nodes: #{all_nodes.join(', ')}"

    all_nodes.each do |node_name|
      import_node(node_name)
    end
  end

  def import_node(node_name)
    Log.info "Importing node #{node_name}..."

    node_data = metal_eval("nodes.#{node_name}.to_h")

    node_asset_data = metal_eval("nodes.#{node_name}.asset")
    node_server = asset_name(node_asset_data)

    node_group_name = metal_eval("nodes.#{node_name}.group.name")

    node = Node.create!(
      name: node_name,
      data: node_data,
      server: Server.find_by_name!(node_server),
      group: Group.find_by_name!(node_group_name),
    )

    node_genders = node_data['genders']
    Log.info "Creating/associating genders for node #{node_name}: #{node_genders.join(', ')}"
    node_genders.each do |gender_name|
      gender = Gender.find_or_create_by!(name: gender_name)
      gender.nodes << node
    end

    available_network_adapter_ports =
      node.server.network_adapters.flat_map(&:network_adapter_ports)

    Log.info "Associating network connections for node #{node_name} "
    rendered_networks = metal_eval(
      "nodes.#{node_name}.config.networks.map { |name,data| [name, data.map {|k,v| [k,v]}.to_h ]}.to_h"
    )
    rendered_networks.each do |network_name, network_data|
      # Find port Node is connected to Network via by matching up network
      # names.
      port = available_network_adapter_ports.find do |p|
        p.network_connection&.network&.name == network_name
      end

      unless port
        Log.info <<~INFO
          Could not find Server NetworkAdapterPort for Network #{network_name}
          for Node #{node_name}; skipping network.
        INFO
        next
      end

      interface = network_data.fetch('interface')
      port.network_connection.update!(node: node, interface: interface)
    end
  end

  def metal_eval(eval_args)
    metal_command = "metal eval '#{eval_args}' 2> /dev/null"
    Log.info ">>> #{metal_command}"
    output = ssh_connection.exec!(metal_command)
    JSON.parse(output)
  end

  def asset_name(asset_data)
    asset_data.dig('metadata', 'name')
  end

  def asset_name_from_reference(reference)
    # Reference is an @WilliamMcCumstie-style Metalware asset reference, e.g.
    # `^rack1-r630-chassis-780-server1`; we just want the name of the
    # referenced asset.
    reference.gsub(/^\^/, '')
  end

  module Log
    class << self
      def fatal(text)
        raise "ERROR: #{text.squish}"
      end

      def warning(text)
        info "WARNING: #{text}"
      end

      def info(text)
        raw_info text.squish
      end

      def raw_info(text)
        STDERR.puts text
      end
    end
  end
end
