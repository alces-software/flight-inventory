
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

    import_nodes
  end

  private

  attr_reader :ssh_connection

  def initialize(ssh_connection)
    @ssh_connection = ssh_connection
  end

  def import_nodes
    all_nodes = metal_view('nodes.map(&:name)')
    # XXX This gets all nodes on old Metalware; above only works on latest
    # Metalware with https://github.com/alces-software/metalware/pull/430
    # merged.
    # all_nodes = ssh.exec!("nodeattr --expand | awk '{print $1}'").lines.map(&:chomp)

    STDERR.puts "Found nodes: #{all_nodes.join(', ')}"

    all_nodes.each do |node|
      if node == 'local'
        STDERR.puts 'Skipping local node'
        next
      end

      STDERR.puts "Importing #{node}..."
      # XXX Use below with old Metalware, as above.
      # node_data = JSON.parse(ssh.exec!("metal view node.#{node} 2> /dev/null"))
      node_data = metal_view("nodes.#{node}.to_h")
      Node.create!(name: node, data: node_data)
    end
  end

  def metal_view(view_args)
    output = ssh_connection.exec!("metal view '#{view_args}' 2> /dev/null")
    JSON.parse(output)
  end
end
