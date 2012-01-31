#
# Author:: Artem Veremey (<artem@veremey.net>)
# Copyright:: Copyright (c) Artem Veremey
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
        
        if Chef::Config[:knife][:instance_cmd] == "reboot"
          puts "Rebooting instance #{Chef::Config[:knife][:instance]}"
          exit 0
        end
        
        res = result.body["instancesSet"].first
        
        msg = []
        msg << "Instance #{Chef::Config[:knife][:instance]} previous state "
        msg << color_state(:server, res["previousState"]["name"])
        msg << "Instance #{Chef::Config[:knife][:instance]} current state "
        msg << color_state(:server, res["currentState"]["name"])
        
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