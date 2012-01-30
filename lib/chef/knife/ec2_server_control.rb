require 'chef/knife/ec2_base'

class Chef
  class Knife
    class Ec2ServerControl < Knife

      include Knife::Ec2Base

      banner "knife ec2 server control --cmd {start,stop,reboot,terminate} -i instance-id (options)"
      
      option :cmd,
        :short => "--cmd {start,stop,reboot,terminate}",
        :description => "Server control command",
        :proc => Proc.new { |f| Chef::Config[:knife][:instance_cmd] = f }
      
      option :instance,
        :instance => "-i INSTANCE_ID",
        :long => "--instance INSTANCE_ID",
        :required => true,
        :description => "Your instance id",
        :proc => Proc.new { |f| Chef::Config[:knife][:instance] = f }
      
      def run
        $stdout.sync = true

        validate!
        
        pp ["cmd", Chef::Config[:knife][:instance_cmd]]
        
        if Chef::Config[:knife][:instance_cmd].nil?
          ui.error("Instance control command is missing: --cmd {start,stop,terminate}")
          exit 1
        end
        
        
        instance_ids = connection.servers.map{ |server| server.id }
        
        unless instance_ids.include?(Chef::Config[:knife][:instance])
          ui.error("Invalid instance id: #{Chef::Config[:knife][:instance]}")
          puts "Existing instances: #{instance_ids.join(", ")}"
          exit 1
        end
        
        result = run_cmd(Chef::Config[:knife][:instance_cmd], [Chef::Config[:knife][:instance]])
        pp ["result", result.body]
        
        res = result.body["instancesSet"].first
        
        
        msg = []
        msg << "Instance #{Chef::Config[:knife][:instance]} previous state "
        msg << color_state(res["previousState"]["name"])
        msg << "Instance #{Chef::Config[:knife][:instance]} current state "
        msg << color_state(res["currentState"]["name"])
        
        puts ui.list(msg, :columns_across, 2)
      end
      
      def run_cmd(cmd, instance)
        case cmd 
        when "start"
          result = connection.start_instances(instance)
        when "stop"
          result = connection.stop_instances(instance)
        when "reboot"
          result = connection.reboot_instances(instance)
        when "terminate"
          result = connection.terminate_instances(instance)
        else
          ui.error("Unknown control command: #{cmd}")
          exit 1
        end
        
        return result
      end
      
    end
  end
end