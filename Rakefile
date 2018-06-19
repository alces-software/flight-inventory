
CONTROLLER_IP = '10.101.0.46'

# Always show error stack traces.
# XXX Doesn't work?
Rake.application.options.trace = true

task :run do
  password = ENV.fetch('ALCES_INSECURE_PASSWORD')

  sh "sshpass -p '#{password}' scp ./prototype root@#{CONTROLLER_IP}:/tmp"
  sh "sshpass -p '#{password}' ssh root@#{CONTROLLER_IP} -- bash --login -c \"'chmod +x /tmp/prototype && /tmp/prototype'\""
end
